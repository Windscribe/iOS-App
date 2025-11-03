//
//  SampleDataStaticIP.swift
//  WindscribeTests
//
//  Created by Claude Code on 2025-10-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class SampleDataStaticIP {
    static let staticIPListJSON = """
    {
        "data": {
            "static_ips": [
                {
                    "id": 1,
                    "ip_id": 101,
                    "static_ip": "192.168.1.100",
                    "type": "dedicated",
                    "name": "US East",
                    "country_code": "US",
                    "short_name": "US-E",
                    "city_name": "New York",
                    "server_id": 201,
                    "expiry": "2026-12-31",
                    "status": 1,
                    "connect_ip": "us-east.windscribe.com",
                    "wg_ip": "10.64.1.1",
                    "wg_pubkey": "test_wg_public_key_1",
                    "ovpn_x509": "test_ovpn_x509_1",
                    "ping_ip": "192.168.1.100",
                    "ping_host": "us-east.windscribe.com",
                    "device_name": "My Device",
                    "node": {
                        "ip1": "192.168.1.100",
                        "ip2": "192.168.1.101",
                        "ip3": "192.168.1.102",
                        "hostname": "us-east-node1",
                        "weight": 1000,
                        "group": "us-east",
                        "gps": "40.7128,-74.0060"
                    },
                    "ports": [
                        {
                            "ext_port": 443,
                            "int_port": 443
                        },
                        {
                            "ext_port": 1194,
                            "int_port": 1194
                        }
                    ],
                    "credentials": {
                        "username": "static_user_1",
                        "password": "static_pass_1"
                    }
                },
                {
                    "id": 2,
                    "ip_id": 102,
                    "static_ip": "10.10.2.200",
                    "type": "dedicated",
                    "name": "UK London",
                    "country_code": "GB",
                    "short_name": "UK-L",
                    "city_name": "London",
                    "server_id": 202,
                    "expiry": "2026-06-30",
                    "status": 1,
                    "connect_ip": "uk-london.windscribe.com",
                    "wg_ip": "10.64.2.1",
                    "wg_pubkey": "test_wg_public_key_2",
                    "ovpn_x509": "test_ovpn_x509_2",
                    "ping_ip": "10.10.2.200",
                    "ping_host": "uk-london.windscribe.com",
                    "device_name": "My Server",
                    "node": {
                        "ip1": "10.10.2.200",
                        "ip2": "10.10.2.201",
                        "ip3": "10.10.2.202",
                        "hostname": "uk-london-node1",
                        "weight": 1000,
                        "group": "uk-london",
                        "gps": "51.5074,-0.1278"
                    },
                    "ports": [
                        {
                            "ext_port": 443,
                            "int_port": 443
                        }
                    ],
                    "credentials": {
                        "username": "static_user_2",
                        "password": "static_pass_2"
                    }
                }
            ]
        }
    }
    """

    static let singleStaticIPListJSON = """
    {
        "data": {
            "static_ips": [
                {
                    "id": 1,
                    "ip_id": 101,
                    "static_ip": "192.168.1.100",
                    "type": "dedicated",
                    "name": "US East",
                    "country_code": "US",
                    "short_name": "US-E",
                    "city_name": "New York",
                    "server_id": 201,
                    "expiry": "2026-12-31",
                    "status": 1,
                    "connect_ip": "us-east.windscribe.com",
                    "wg_ip": "10.64.1.1",
                    "wg_pubkey": "test_wg_public_key_1",
                    "ovpn_x509": "test_ovpn_x509_1",
                    "ping_ip": "192.168.1.100",
                    "ping_host": "us-east.windscribe.com",
                    "device_name": "My Device",
                    "node": {
                        "ip1": "192.168.1.100",
                        "ip2": "192.168.1.101",
                        "ip3": "192.168.1.102",
                        "hostname": "us-east-node1",
                        "weight": 1000,
                        "group": "us-east",
                        "gps": "40.7128,-74.0060"
                    },
                    "ports": [
                        {
                            "ext_port": 443,
                            "int_port": 443
                        }
                    ],
                    "credentials": {
                        "username": "static_user_1",
                        "password": "static_pass_1"
                    }
                }
            ]
        }
    }
    """

    static let emptyStaticIPListJSON = """
    {
        "data": {
            "static_ips": []
        }
    }
    """
}
