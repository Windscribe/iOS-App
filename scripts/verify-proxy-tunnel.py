#!/usr/bin/env python3
"""Live view of which Windscribe node the device is dialling, and whether the local proxy is in the path.

  sudo ./verify-proxy-tunnel.py                 watch live
  sudo ./verify-proxy-tunnel.py -p stealth      watch and assert Stealth is proxied
  ./verify-proxy-tunnel.py -r capture.pcap      replay a capture (no sudo)

Each node exposes three addresses and protocols share them, so the transport and
the payload signature decide what you are looking at, not the address alone:

    ip1   WStunnel (TLS)      IKEv2 (UDP 500/4500)
    ip2   OpenVPN TCP         OpenVPN UDP
    ip3   Stealth (TLS)       WireGuard (UDP)

Stealth and WStunnel must be TLS. Raw OpenVPN on their addresses -- or anywhere,
when -p names a proxied protocol -- means the local proxy was skipped.
"""

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import threading
import time
import urllib.request

SERVERLIST = "https://assets.windscribe.com//serverlist/mob-v2/1/"
PHYS = re.compile(r"^(en\d+|pdp_ip\d+)$")
LINE = re.compile(r"^(\d\d:\d\d:\d\d\.\d+) \((\S+?)\) IP ([\d.]+)\.(\d+) > ([\d.]+)\.(\d+):")

OFF = "((tcp[12:1] & 0xf0) >> 2)"
BPF_TLS = f"tcp[{OFF}] = 0x16 and tcp[{OFF} + 1] = 0x03 and tcp[{OFF} + 5] = 0x01"
BPF_OVPN = f"tcp[{OFF}] = 0x00 and tcp[{OFF} + 2] = 0x38"
BPF_SYN = "tcp[tcpflags] & (tcp-syn|tcp-ack) == tcp-syn"
BPF_OVPN_UDP = "udp[8] = 0x38"
# WireGuard MessageInitiation: type 1 then three reserved zero bytes.
BPF_WG = "udp[8] = 0x01 and udp[9] = 0x00 and udp[10] = 0x00 and udp[11] = 0x00"
BPF_IKE = "udp port 500 or udp port 4500"
BPF_UDP_ANY = "udp"

# (signature, node role) -> (protocol, must it be proxied)
CLASSIFY = {
    ("tls", "ip3"): ("Stealth", True),
    ("tls", "ip1"): ("WStunnel", True),
    ("ovpn", "ip2"): ("OpenVPN TCP", False),
    ("ovpn_udp", "ip2"): ("OpenVPN UDP", False),
    ("wg", "ip3"): ("WireGuard", False),
    ("ike", "ip1"): ("IKEv2", False),
}
PROXIED = {"stealth", "wstunnel"}
# The app latency-probes every server on this port (LatencyRepository.swift:386),
# which is hundreds of connections to ip1 that have nothing to do with a tunnel.
PROBE_PORTS = {"6464"}
ROLE_HINT = {"ip1": "WStunnel/IKEv2", "ip2": "OpenVPN", "ip3": "Stealth/WireGuard"}

C = {"g": "\033[32m", "r": "\033[31m", "y": "\033[33m", "d": "\033[2m", "b": "\033[1m", "x": "\033[0m"}
if not sys.stdout.isatty():
    C = dict.fromkeys(C, "")


def load_nodes(url):
    token = os.urandom(20).hex()
    with urllib.request.urlopen(url + token, timeout=45) as r:
        data = json.load(r)
    nodes = {}
    for region in data.get("data", []):
        for grp in region.get("groups", []):
            where = f"{region.get('name')} / {grp.get('city', '')}".strip(" /")
            for n in grp.get("nodes", []):
                for role in ("ip", "ip2", "ip3"):
                    ip = n.get(role)
                    if ip:
                        nodes[ip] = ("ip1" if role == "ip" else role, n.get("hostname", "?"), where)
    return nodes


class Watch:
    def __init__(self, nodes, expect, show_all=False):
        self.nodes = nodes
        self.expect = expect
        self.show_all = show_all
        self.probes = 0
        self.seen = {}
        self.bypassed = []
        self.confirmed = []
        self.found = []
        self.classified = set()
        self.unclassified = {}
        self.pending = {}
        self.lock = threading.Lock()

    def event(self, kind, line):
        m = LINE.match(line)
        if not m or not PHYS.match(m.group(2)):
            return
        ts, _, _, _, dst, dport = m.groups()
        node = self.nodes.get(dst)
        if not node:
            return
        role, host, where = node

        with self.lock:
            if dport in PROBE_PORTS and not self.show_all:
                self.probes += 1
                return
            if (dst, kind) in self.seen:
                return
            self.seen[(dst, kind)] = ts
            t = ts[:8]

            if kind == "udp_any":
                self.unclassified.setdefault(dst, (t, role, host))
                return

            if kind == "syn":
                self.pending[dst] = (t, dport, role, host, where)
                return

            self.classified.add(dst)
            hit = CLASSIFY.get((kind, role))

            if kind in ("ovpn", "ovpn_udp"):
                proxied_expected = role in ("ip1", "ip3") or (self.expect in PROXIED)
                if proxied_expected:
                    name = CLASSIFY.get((kind, role), (None,))[0] or (self.expect or "proxied").capitalize()
                    if role in ("ip1", "ip3"):
                        name = "Stealth" if role == "ip3" else "WStunnel"
                    self.bypassed.append((name, host, role, dst))
                    print(f"{C['d']}{t}{C['x']}  {C['r']}{name:<12}{C['x']} {host}  "
                          f"{role} {dst}:{dport}  {C['d']}{where}{C['x']}  "
                          f"{C['r']}raw OpenVPN — PROXY BYPASSED ✘{C['x']}")
                    return

            if not hit:
                print(f"{C['d']}{t}{C['x']}  {C['y']}odd{C['x']}         "
                      f"{kind:<18} {host}  {role} {dst}  {C['y']}unexpected on this address{C['x']}")
                return

            proto, must_proxy = hit
            self.found.append((proto, host, role, dst))
            self.pending.pop(dst, None)
            if must_proxy:
                self.confirmed.append((proto, host, role, dst))
                tail = f"{C['g']}TLS — proxy in path ✓{C['x']}"
            else:
                tail = f"{C['d']}direct{C['x']}"
            print(f"{C['d']}{t}{C['x']}  {C['b']}{proto:<12}{C['x']} {host}  "
                  f"{role} {dst}:{dport}  {C['d']}{where}{C['x']}  {tail}")

    def verdict(self):
        print()
        for dst, (t, dport, role, host, where) in self.pending.items():
            if dst not in self.classified:
                print(f"{C['d']}{t}{C['x']}  {C['y']}unclassified{C['x']} {host}  "
                      f"{role} {dst}:{dport}  {C['d']}{where}{C['x']}  "
                      f"{C['y']}connected but no handshake seen{C['x']}")
        if self.probes:
            print(f"{C['d']}({self.probes} latency probes on port "
                  f"{'/'.join(sorted(PROBE_PORTS))} hidden — pass -a to show){C['x']}")
        for dst, (t, role, host) in self.unclassified.items():
            if dst not in self.classified:
                print(f"{C['y']}⚠{C['x']} unclassified UDP to {host} {role} {dst} at {t}")

        if self.bypassed:
            for proto, host, role, dst in self.bypassed:
                print(f"{C['r']}✘ FAIL{C['x']}  {proto} sent raw OpenVPN to {host} {role} {dst} — the proxy was skipped.")
            return 1
        if not self.seen:
            print(f"{C['y']}⚠ nothing seen{C['x']}  No traffic to any known node. Connect *after* starting the watch.")
            return 2
        if self.expect:
            hit = [f for f in self.found if f[0].lower().replace(" ", "") == self.expect.lower().replace(" ", "")]
            if hit:
                proto, host, role, dst = hit[0]
                how = "through the proxy" if self.expect in PROXIED else "directly"
                print(f"{C['g']}✔ PASS{C['x']}  {proto} connected {how} to {host} {role} {dst}.")
                return 0
            print(f"{C['y']}⚠ INCONCLUSIVE{C['x']}  No {self.expect} connection observed.")
            return 2
        if self.found:
            for proto, host, role, dst in self.found:
                mark = f"{C['g']}✔{C['x']}" if (proto, host, role, dst) in self.confirmed else f"{C['d']}·{C['x']}"
                print(f"{mark} {proto} via {host} {role} {dst}")
            return 0
        print(f"{C['y']}⚠ INCONCLUSIVE{C['x']}  Saw node traffic but nothing classifiable.")
        return 2


# iOS hardware UDIDs: 8-16 hex (modern) or 40 hex (older). A Mac's UUID is 8-4-4-4-12,
# which is how the host machine gets excluded regardless of how anything is named.
IOS_UDID = re.compile(r"^([0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{40})$")
DEVICE_LINE = re.compile(r"^(.*?) \(([^()]*)\) \(([^()]+)\)$")


def list_devices():
    """Connected iOS devices as (udid, name). Device names are arbitrary, so match on UDID shape."""
    cmd = ["xcrun", "xctrace", "list", "devices"]
    # Device pairing belongs to the logged-in user; root often cannot see it, so ask as them.
    if os.geteuid() == 0 and os.environ.get("SUDO_USER"):
        cmd = ["sudo", "-u", os.environ["SUDO_USER"], "-H"] + cmd
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    devices, live = [], False
    for line in out.splitlines():
        stripped = line.strip()
        if stripped.startswith("=="):
            live = stripped == "== Devices =="
            continue
        if not live:
            continue
        m = DEVICE_LINE.match(stripped)
        if m and IOS_UDID.match(m.group(3)):
            devices.append((m.group(3), f"{m.group(1)} ({m.group(2)})"))
    if not devices:
        # Fall back to libimobiledevice if it is around.
        ids = subprocess.run(["idevice_id", "-l"], capture_output=True, text=True).stdout.split()
        devices = [(i, "via idevice_id") for i in ids if IOS_UDID.match(i)]
    return devices


def ancestors():
    pids, pid = set(), os.getpid()
    for _ in range(12):
        pids.add(pid)
        out = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)], capture_output=True, text=True).stdout.strip()
        if not out.isdigit() or int(out) <= 1:
            break
        pid = int(out)
    return pids


def sweep():
    """Kill leftover watchers and tear down every stale rvi session before starting."""
    killed, mine = 0, ancestors()
    out = subprocess.run(["pgrep", "-f", os.path.basename(__file__)], capture_output=True, text=True).stdout
    for pid in (int(x) for x in out.split() if x.isdigit()):
        if pid not in mine:
            try:
                os.kill(pid, signal.SIGKILL)
                killed += 1
            except OSError:
                pass
    subprocess.run(["pkill", "-f", "tcpdump -i rvi"], capture_output=True)

    for _ in range(12):
        listing = subprocess.run(["rvictl", "-l"], capture_output=True, text=True).stdout
        udids = set(re.findall(r"\[\d+\]\s+(\S+)\s+with interface", listing))
        if not udids:
            break
        for u in udids:
            subprocess.run(["rvictl", "-x", u], capture_output=True)

    left = [i for i in subprocess.run(["ifconfig", "-l"], capture_output=True, text=True).stdout.split()
            if i.startswith("rvi")]
    print(f"{C['d']}swept: {killed} stale watcher(s), rvi interfaces left: {left or 'none'}{C['x']}")
    return left


def stream(cmd, kind, watch):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
    for line in p.stdout:
        watch.event(kind, line)
    return p


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-u", "--udid")
    ap.add_argument("-t", "--seconds", type=int, default=90)
    ap.add_argument("-r", "--read", metavar="PCAP")
    ap.add_argument("-p", "--protocol",
                    choices=["stealth", "wstunnel", "wireguard", "ikev2", "openvpntcp", "openvpnudp"])
    ap.add_argument("-a", "--all", action="store_true", help="include latency-probe traffic")
    ap.add_argument("--url", default=SERVERLIST)
    args = ap.parse_args()

    print(f"{C['d']}fetching server list…{C['x']}", end=" ", flush=True)
    try:
        nodes = load_nodes(args.url)
    except Exception as e:
        sys.exit(f"\ncould not fetch the server list: {e}")
    print(f"{len(nodes)} node addresses")

    watch = Watch(nodes, args.protocol, args.all)
    sources = [("syn", BPF_SYN), ("tls", BPF_TLS), ("ovpn", BPF_OVPN),
               ("ovpn_udp", BPF_OVPN_UDP), ("wg", BPF_WG), ("ike", BPF_IKE),
               ("udp_any", BPF_UDP_ANY)]

    if args.read:
        for kind, bpf in sources:
            out = subprocess.run(["tcpdump", "-r", args.read, "-n", "-k", "I", bpf],
                                 capture_output=True, text=True).stdout
            for line in out.splitlines():
                watch.event(kind, line)
        sys.exit(watch.verdict())

    if os.geteuid() != 0:
        sys.exit("live capture needs root — re-run with sudo, or use -r <pcap>")

    udid = args.udid
    if not udid:
        found = list_devices()
        if len(found) > 1:
            print("more than one device connected — pick one with -u:")
            for u, name in found:
                print(f"  {u}  {name}")
            sys.exit(1)
        udid = found[0][0] if found else None
    if not udid:
        sys.exit("no device found — connect an iPhone by USB, trust it, then retry "
                 "(or pass -u <udid>; 'xcrun xctrace list devices' shows what is paired)")

    sweep()
    rvi = subprocess.run(["rvictl", "-s", udid], capture_output=True, text=True).stdout
    m = re.search(r"with interface (rvi\d+)", rvi)
    if not m:
        sys.exit("rvictl failed — is the device connected by USB (not Wi-Fi) and trusted?")
    iface = m.group(1)
    print(f"{C['d']}device {udid} on {iface}{C['x']}")
    print(f"\n{C['b']}>>> Connect now — watching for {args.seconds}s{C['x']}\n")

    procs = []
    signal.signal(signal.SIGTSTP, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt))
    try:
        for kind, bpf in sources:
            t = threading.Thread(target=lambda k=kind, b=bpf: procs.append(
                stream(["tcpdump", "-i", iface, "-n", "-k", "I", "-l", b], k, watch)), daemon=True)
            t.start()
        time.sleep(args.seconds)
    except KeyboardInterrupt:
        pass
    finally:
        for p in procs:
            p.send_signal(signal.SIGTERM)
        subprocess.run(["rvictl", "-x", udid], capture_output=True)

    sys.exit(watch.verdict())


if __name__ == "__main__":
    main()
