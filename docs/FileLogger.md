# FileLogger: legacy state and segmented replacement

## Purpose

This document records:

1. what the current FileLogger is responsible for;
2. the problems observed in its implementation;
3. the changes made so far and their tradeoffs;
4. a clean-slate structure that avoids continuing to patch the current class.

MR !1559 remains stabilization work against the legacy implementation. MR !1562 implements the process-owned segmented replacement described later in this document while preserving the existing `FileLogger` compatibility API. The baseline sections below remain as the rationale and migration record.

## Legacy implementation before MR !1562

Primary files:

- `Windscribe/Managers/Logger/FileLogger.swift`
- `Windscribe/Managers/Logger/FileLoggerImpl.swift`
- `WindscribeTests/Managers/FileLoggerTests.swift`

`FileLoggerImpl` currently owns all of these responsibilities:

- receiving app, extension, and WSNet log messages;
- formatting timestamps and JSON records;
- buffering and sorting records;
- scheduling timed flushes;
- appending to the shared file;
- parsing existing records;
- applying age and size retention;
- compacting the file;
- exporting a user-shareable log;
- adding device/build metadata;
- creating the log directory.

The host app, PacketTunnel, WireGuardTunnel, and other consumers can instantiate the same implementation. The network extensions and host app use the same app-group log path, but each process has its own `FileLoggerImpl`, serial queue, timer, and compaction state.

The serial queue protects one logger instance. It does not serialize access between processes.

The current JSON-lines file is an implementation choice, not a storage requirement. JSON is required when logs are displayed or exported in the existing `tm`, `lvl`, `mod`, and `msg` shape. A replacement may use a different internal format and create the ordered JSON representation only at the presentation/export boundary.

## What is known about the PacketTunnel crashes

The supplied `3.14.1 (4636)` reports share these facts:

- `PacketTunnel` terminates with `EXC_CRASH / SIGABRT` shortly after launch;
- the triggered thread is the PlugInKit/XPC run loop, not a FileLogger worker thread;
- FileLogger work is present on another thread in every supplied report;
- observed FileLogger operations include timestamp formatting, file URL access, appending, and full-file compaction;
- the normalized incident rate is higher than public-testing build 4217;
- the logger implementation changed between those builds.

The reports do not prove that FileLogger requested the abort. They do make FileLogger the strongest build-specific candidate because it performs immediate startup work and the changed compaction failure semantics can increase file size and resource use.

## Evolution so far

### Original JSON logger

The original implementation performed this work for every flush:

1. read and parse the complete existing file;
2. combine existing and new records;
3. apply the 24-hour and size policies;
4. atomically rewrite the result.

Benefits:

- the file was trimmed before a successful write;
- a failed write did not append additional data.

Problems:

- every flush paid the full parse, allocation, sort, encode, and rewrite cost;
- the cost occurred inside network extensions as well as the host app;
- concurrent processes could still read and replace the same shared path.

### MR !1521: append before periodic compaction

MR !1521 changed the normal path to append records first and compact only when the file exceeded the size cap or the compaction interval elapsed. It also reused one queue-confined `DateFormatter`.

Benefits:

- ordinary flushes no longer rewrite the entire file;
- timestamp formatting no longer creates a formatter per operation;
- normal write amplification was substantially reduced.

New risks:

- the append can succeed before size lookup or compaction fails;
- failures are intentionally silent, so an oversized file can remain;
- later flushes can append again and retry against a larger file;
- compaction still reads and decodes the complete file;
- independent host/extension compactors can race on the same path.

### MR !1557: PacketTunnel startup completion

MR !1557 removed a `fatalError`, completed the missing-OpenVPN-data path, and serialized PacketTunnel startup completion ownership.

This removes ambiguous extension startup exits but does not change FileLogger storage or compaction.

### MR !1559: bounded legacy compaction

MR !1559 currently proposes stabilization of the existing logger:

- reduce the retained file cap from 2 MiB to 512 KiB;
- keep the 24-hour age policy and 120,000-character export cap;
- read at most the newest 512 KiB when parsing;
- discard the first partial line before UTF-8 decoding;
- compact before an append that would exceed the cap;
- reserve room for the incoming batch during compaction;
- stop the append if size lookup, parsing, or compaction fails;
- cover oversized input, age retention, timestamp preservation, and concurrent calls with tests.

Benefits:

- parsing memory is bounded even if the file has grown unexpectedly;
- a failed compaction does not deliberately grow the file further;
- successful compaction leaves room for the pending batch;
- one behavior applies to the host app and extensions.

Costs:

- `FileLoggerImpl` now has more control flow and more coupled responsibilities;
- retention, parsing, compaction, append policy, and export remain in one class;
- cross-process races are reduced in impact but not removed;
- the fix is defensive stabilization rather than an organic simplification of the design.

### Alternative explored in MR !1560

MR !1560 explores the useful idea of checking size before append and reading only a recent tail. Its current implementation also demonstrates pitfalls the final design should avoid:

- separate normal and oversized parsing paths;
- compaction without reserving room for the incoming batch;
- appending after an unreported compaction failure;
- deleting the entire log on temporary open, decode, or write failures;
- decoding a byte tail before removing a potentially partial UTF-8 line;
- eager DateFormatter initialization that moves, rather than removes, startup work;
- no focused tests for the new behavior.

The desired replacement should retain the simple idea—bounded append-only segments—but should not duplicate parsing modes or add destructive recovery paths.

## Current architectural concerns

### Shared mutable file across processes

The host app and network extensions independently append to and atomically replace the same path. A process-local serial queue cannot prevent:

- one process replacing the file while another has the previous inode open;
- one process compacting a snapshot while another appends newer records;
- lost records after an atomic replacement;
- inconsistent size checks;
- multiple processes performing the same retention work.

### Compaction on the write path

A logging call can eventually trigger:

- file metadata lookup;
- file reads;
- UTF-8 conversion;
- line splitting;
- JSON decoding;
- DateFormatter parsing;
- sorting;
- JSON encoding;
- atomic replacement.

Logging should not require all of this work to accept a record.

### Responsibilities are not separable

`FileLoggerImpl` cannot change storage policy without also affecting buffering, export, formatting, tests, and extension behavior. This is why targeted fixes tend to add branches rather than simplify the component.

### Silent failure has unclear semantics

Suppressing recursive logger errors is reasonable, but the current implementation does not distinguish between:

- dropping one record;
- dropping one batch;
- failing retention;
- failing export;
- losing the entire file after replacement.

The caller receives no result, and the logger has no small internal health state for tests or diagnostics.

### Retention and export limits are conflated

The logger currently combines:

- an age requirement: retain records no older than 24 hours;
- a resource requirement: never retain more than the size budget;
- an implementation limit: return no more than 120,000 characters.

There is no product requirement to cap the number of exported records or characters, but physical storage must remain bounded during a runaway producer. The replacement keeps at most 10 MiB of segment data per process and rotates an active segment at 1 MiB. Within that budget, View Debug Logs shows up to the complete 24-hour window while Send Debug Logs submits only the most recent 2 hours. The current 120,000-character behavior remains a legacy export detail rather than the storage safety boundary.

### Export is coupled to the active writer

`getLogData()` flushes the active buffer and then parses the same storage used by live writers. Export should be a separate read operation over stable segments.

### Shutdown flushing is unreliable

`deinit` schedules an asynchronous flush using a weak reference while the object is being destroyed. It cannot be treated as a durable final write guarantee.

## Clean-slate goals

A replacement should:

- keep the logging hot path append-only and bounded;
- apply the same writer behavior in every process;
- avoid sharing an actively mutated file between processes;
- avoid parsing or sorting during normal writes;
- keep memory use independent of historical file growth;
- treat JSON as an output format rather than requiring JSON on disk;
- preserve recent records needed by QA and customer support;
- retain up to 24 hours within a fixed per-process storage budget, show the complete retained window available inside that budget, and submit only the most recent 2 hours without a separate output-size limit;
- tolerate partial, malformed, or interrupted writes;
- bound work per write and export operation;
- remain local-only and contain no new telemetry.

## Clean-slate non-goals

The replacement does not need:

- remote log upload;
- runtime memory monitoring;
- console phase diagnostics;
- a general analytics pipeline;
- arbitrary query support;
- a database;
- compression on the write path.

## Storage and presentation formats

The external presentation contract is the current ordered JSON record:

```json
{"tm": "2026-08-25 12:34:56.789", "lvl": "info", "mod": "Module", "msg": "Message"}
```

That contract belongs to `LogExporter`. The active writer does not need to produce JSON, preserve a human-readable timestamp string, escape JSON characters, or use newline boundaries.

A simple starting point for storage is a private, versioned, length-prefixed binary segment. One possible layout is:

```text
segment header
  magic                 4 bytes
  format version        1 byte

record
  record length         UInt32
  UTC timestamp seconds TimeInterval / Float64
  level                 UInt8
  module length         UInt16
  module                UTF-8 bytes
  message               remaining record bytes
```

The exact codec should be decided during implementation, but it should provide these properties:

- a segment and record can be validated without JSON parsing;
- a maximum record length is checked before allocation;
- complete records can be streamed sequentially;
- an incomplete final record can be ignored after an interrupted append;
- timestamps remain numeric until export;
- no third-party serialization dependency is required merely for local logs.

The exporter decodes storage records and produces the existing ordered JSON, including date formatting, JSON escaping, and metadata. It streams the available retained records up to 24 hours old for viewing and filters them to the most recent 2 hours for submission instead of imposing the current 120,000-character limit. Storage schema compatibility and JSON presentation compatibility are therefore separate concerns.

## Implemented file structure

```text
Windscribe/Services/Logging/
  LogModels.swift              LogLevel, LogProcess, LogRecord, LogSegment
  LogProtocols.swift           write, export, codec, and segment boundaries
  LogMessagePolicy.swift       two-line and bounded-message normalization
  BinaryLogRecordCodec.swift   versioned length-prefixed binary records
  FileLogSegmentStore.swift    process-scoped writer/reader and legacy archive naming
  SegmentedLogWriter.swift     serial batching, time/size rotation, bounded cleanup
  JSONLogExporter.swift        streaming segment and archived-legacy JSON export

Windscribe/Managers/Logger/
  FileLogger.swift             existing compatibility protocol
  FileLoggerImpl.swift         compatibility facade and process composition

WindscribeTests/Managers/
  FileLoggerTests.swift        codec, policy, storage, export, and recovery tests
```

The shared logging files are compiled into the iOS app, tvOS app, PacketTunnel, WireGuardTunnel, SiriIntents, and HomeWidget targets. `FileLoggerImpl` preserves the existing logging/export methods and exposes the app-group root through a get-only `logDirectory`, which is fixed during initialization and remains available for `proxy.log`. On `main`, `CoreModule` now accepts an explicit `LogProcess`, and every executable composition boundary passes its identity; there is no bundle-identifier inference. On `neo-4.0`, the manual `CoreGraph` and target-local composition roots can construct the facade with the same explicit identity without Swinject.

The compatibility protocol still exposes `getLogData()` to every target, so the exporter currently compiles everywhere even though normal export is host-owned. Once legacy consumers move from `FileLogger`/`LogStoring` to the narrow `LogWriting` and `LogExporting` capabilities, extension composition roots should receive only `LogWriting` and the exporter can become host-only target membership.

## Implemented contracts

The snippets below describe the implementation boundaries used by this MR.

### Data objects

```swift
enum LogLevel: UInt8, Sendable {
    case debug
    case info
    case error

    var stringValue: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .error: return "error"
        }
    }
}

enum LogProcess: String, Sendable, CaseIterable {
    case app
    case packetTunnel
    case wireGuardTunnel
    case appIntents
    case siriIntents
    case homeWidget
}

struct LogRecord: Sendable, Equatable {
    let timestamp: TimeInterval
    let level: LogLevel
    let module: String
    let message: String
}

struct LogSegment: Sendable, Equatable {
    let process: LogProcess
    let bucketStart: TimeInterval
    let sequence: UInt32
    let url: URL
}

struct LogExportArtifact: Sendable {
    let url: URL
    let contentType: String // application/x-ndjson
}
```

`LogRecord` is storage-agnostic. It does not contain JSON strings, a `DateFormatter`, file URLs, or app metadata. `LogSegment` is a storage descriptor, not an owner of an open handle. `BinaryLogRecordCodec` stores `LogLevel.rawValue`; `JSONLogFormatter` uses `LogLevel.stringValue` for the exported `lvl` field.

#### `LogRecord` versus `LogSegment`

- A `LogRecord` is one logged event: timestamp, level, module, and message.
- A `LogSegment` identifies one physical segment file that contains many encoded records from one process and time bucket.
- `LogSegment` does not contain `[LogRecord]` and does not keep the file open. It carries only the process, bucket start, sequence, and URL needed by storage and export code.

In database terms, a record is one row; a segment is the file/container holding many rows. Keeping the segment descriptor avoids passing a bare URL while separately reconstructing its process and ordering metadata.

#### How physical segment files are created

The logger does **not** create one file for every record timestamp. It keeps one active segment per writer until the hour changes or the file reaches 1 MiB:

1. A record timestamp is rounded down to the start of its hour: `floor(timestamp / 3600) * 3600`.
2. The first flushed record lazily creates one file in the current process directory.
3. Later records append framed binary records until another record would exceed the 1 MiB segment limit.
4. Reaching the size limit or entering the next hour closes the current file and creates another. Closed files are never rewritten or compacted.
5. A process restart creates a new segment even within the same hour, so it never appends behind a possibly incomplete record left by the previous process lifetime.

The filename is:

```text
segment-<hour-bucket-start>-<first-record-offset>-<uuid>.wslg
```

- `hour-bucket-start` is the Unix timestamp for the beginning of the hour.
- `first-record-offset` is the first record's microsecond offset inside that hour and helps deterministic file ordering; it does not cause a file per timestamp.
- `uuid` guarantees a distinct filename across process restarts or simultaneous process lifetimes.

Each file starts with the versioned `WSLG` header and then contains many length-prefixed records. `LogSegmentFileName` only creates and parses this filename. `LogSegment` is the in-memory descriptor for that file. Rotation removes expired files and evicts the oldest closed files until the active segment's 1 MiB is reserved inside the 10 MiB per-process budget, then creates the replacement segment.

Timestamps use Foundation's existing `TimeInterval` (`Double`, in seconds). The writer and exporter receive the current time as an injected closure:

```swift
let productionNow: @Sendable () -> TimeInterval = {
    Date().timeIntervalSince1970
}

let fixedTestNow: @Sendable () -> TimeInterval = {
    1_700_000_000
}
```

No separate clock protocol or wrapper type is needed.

### Consumer capabilities

```swift
protocol LogWriting: Sendable {
    func log(
        _ level: LogLevel,
        module: String,
        message: String
    )
}

extension LogWriting {
    func logD(_ module: String, _ message: String) {
        log(.debug, module: module, message: message)
    }

    func logI(_ module: String, _ message: String) {
        log(.info, module: module, message: message)
    }

    func logE(_ module: String, _ message: String) {
        log(.error, module: module, message: message)
    }
}

protocol LogExporting: Sendable {
    func exportRetainedLogs() async throws -> LogExportArtifact
}
```

Writing and exporting are separate capabilities. Most features, managers, and every extension receive only `LogWriting`. Host screens that view, attach, or share logs receive `LogExporting` in addition to `LogWriting` when they also emit their own logs.

The current Neo `LogStoring` protocol combines `logI`/`logE`/`logD` with `getLogData()`. During migration it can be adapted to these two capabilities, then retired. The clean-slate protocols should not retain `getLogData() -> String`, because building the entire 24-hour export in one `String` defeats streaming.

### Storage boundaries

```swift
enum LogRecordDecodeResult: Sendable {
    case record(LogRecord, consumedBytes: Int)
    case incomplete
    case invalid(consumedBytes: Int)
    case invalidHeader
}

protocol LogRecordCoding: Sendable {
    var segmentHeader: Data { get }
    var maximumRecordPayloadBytes: Int { get }

    func maximumMessageBytes(module: String) -> Int
    func encode(_ record: LogRecord) throws -> Data
    func decodeNext(from buffer: Data) -> LogRecordDecodeResult
}

protocol LogSegmentWriting: Sendable {
    func createSegment(
        bucketStart: TimeInterval,
        sequence: UInt32,
        header: Data
    ) throws -> LogSegment
    func append(_ data: Data, to segment: LogSegment) throws
    func removeClosedSegments(
        olderThan cutoff: TimeInterval,
        retainingAtMost maximumBytes: Int
    ) throws
}

protocol LogSegmentReading: Sendable {
    func segments(
        for processes: [LogProcess],
        newerThan cutoff: TimeInterval
    ) throws -> [LogSegment]

    func open(_ segment: LogSegment) throws -> FileHandle
    func removeClosedSegments(olderThan cutoff: TimeInterval) throws
}

protocol LogMetadataProviding: Sendable {
    func metadataRecord(at timestamp: TimeInterval) -> LogRecord
}
```

The process-scoped `LogSegmentWriting` implementation receives one `LogProcess` during construction and cannot write into another process directory. The host `LogSegmentReading` implementation can enumerate all process directories but exposes no append operation.

### Message policy

```swift
struct LogMessagePolicy: Sendable {
    func normalize(_ message: String, fitting payloadBytes: Int) -> String {
        // Keep at most two lines.
        // If the encoded record still does not fit, truncate only message bytes.
        // Append a visible truncation marker.
    }
}
```

The per-record boundary protects one allocation and one append operation; it is not a file-retention or export limit. Timestamp, level, and module/tag are never discarded to make a message fit.

## Implemented structure

### 1. LogRecord

A small immutable value containing:

- numeric UTC timestamp;
- level;
- module/tag;
- message.

Use a numeric timestamp on disk. Human-readable formatting belongs in export/UI code, not the write path. A normal log message should contain at most two lines of text. If an encoded record exceeds the writer's per-record safety boundary, preserve its timestamp, level, and module/tag and truncate only the message with an explicit truncation marker. Do not drop the entire record because its message was too long. Storage versioning belongs to the segment codec rather than the domain record.

### 2. LogWriter

One writer instance per process, implemented as an actor or a dedicated serial queue.

Responsibilities:

- accept `LogRecord` values;
- normalize each message to at most two lines;
- truncate only the message if the encoded record exceeds the per-record safety boundary;
- reserve one of 200 pending slots before enqueueing and drop the new record immediately if the queue is saturated;
- maintain a byte-bounded in-memory batch so one flush has predictable memory use;
- encode each record into the private storage format;
- create a new segment on the first flush, at the fixed time boundary, and before the active segment exceeds 1 MiB;
- append only to one process-owned active segment;
- drop a bounded batch if segment creation or append fails.

The pending-slot and batch boundaries control transient memory; they are not retention or export limits. Messages are normalized before their asynchronous closure is queued, so pending work cannot retain arbitrarily large raw messages. The writer never parses historical records. It removes expired or over-budget closed segments from filename and file-size metadata when it initializes or rotates; it does not decode old record payloads to do so.

### 3. SegmentedLogStore

Use a separate process-owned directory in the app group for every process that writes logs. This does mean separate segment files for the host app, PacketTunnel, WireGuardTunnel, and any other extension process using the logger. For example:

```text
AppExtensionLogs/
  app/segment-<time>-<sequence>.wslg
  packet-tunnel/segment-<time>-<sequence>.wslg
  wireguard-tunnel/segment-<time>-<sequence>.wslg
```

Every process uses the same writer and rotation rules; only the directory identity differs. A writer lazily creates a new uniquely named segment for its first flushed batch and never reopens a segment from a previous process lifetime. This removes active cross-process file sharing and ensures that an interrupted final record can only be the last record in an older segment.

Rotation is both time- and size-based. A segment closes when its one-hour bucket ends or before another record would take it past 1 MiB.

`LogRetention.duration` is the maximum physical age and currently equals 24 hours. `FileLoggerImpl` injects it into both `SegmentedLogWriter` and `JSONLogExporter`, while `LogStorageBudget` limits each process directory to 10 MiB through 1 MiB segments. View Debug Logs shows the records still available inside both bounds. `LogRetention.submissionDuration` is 2 hours and applies only to Send Debug Logs; a submission export never shortens physical retention.

Rotation flow:

1. lazily create a unique active segment when the first accepted batch is flushed;
2. append bounded records and batches while the segment remains below 1 MiB;
3. when the size limit or time bucket changes, flush and close the active segment;
4. remove expired closed segments and evict the oldest closed segments until 1 MiB is reserved inside the 10 MiB process budget;
5. create the replacement segment and continue appending;
6. if segment creation or append fails, drop the current batch without retrying recursively.

Each process writer loads its existing segment filenames once in oldest-first FIFO order. Initialization removes expired entries and any history already beyond 10 MiB. Rotation flushes the old active file, removes expired entries, then removes additional oldest files until the closed history leaves room for one full segment before creating the replacement. Using the bucket end rather than only its start prevents age-based deletion of a one-hour file that may still contain a record inside the user-visible retention window; the byte budget can still evict it when necessary.

Each process retains at most 10 MiB of segment data. The time rule remains an upper age bound: keep up to `LogRetention.duration`, currently 24 hours, while evicting older records sooner when the byte budget requires it. Viewing exports the available retained window, and submission filters it to `LogRetention.submissionDuration`, currently 2 hours.

No process reads or compacts its active file to make room.

In `DEBUG` iOS app builds only, the writer counts accepted records in one-second windows. More than 1,000 records emits one app-boundary warning, with a 60-second cooldown. The app presents that warning through `AlertManager`; Network Extensions and non-`DEBUG` builds contain no warning path.

### 4. LogExporter

An export service separate from the writer. The iOS and tvOS host apps are its normal consumers while the legacy compatibility protocol remains shared.

Responsibilities:

- enumerate the process-owned segment directories;
- enumerate read-only legacy archives created during the one-time migration;
- process directories in a deterministic order, such as host app, PacketTunnel, then WireGuardTunnel;
- read each process's segments oldest to newest while preserving their stored record order;
- snapshot each segment's byte length before reading so concurrent appends are deferred to the next export;
- stream length-prefixed records with bounded buffers;
- skip an incomplete final record and stop safely at malformed record metadata;
- discard records outside the selected purpose window: 24 hours for viewing or 2 hours for submission;
- convert every retained record to the existing ordered JSON shape;
- reuse one lock-protected POSIX `DateFormatter` for export timestamp formatting;
- add device/build metadata to the exported output.

The exporter does not perform a global numeric-timestamp merge across processes. There is no requirement for a total order between independent app and extension clocks/writers, and sorting adds work without improving the normal support workflow. Timestamps remain useful for the JSON output and the configured retention filter.

The exporter runs synchronous file I/O on a utility queue and streams to a temporary export file rather than building one unbounded `String`. Viewing exports available records inside `LogRetention.duration`; submission exports only available records inside `LogRetention.submissionDuration`. Neither path applies another character or record-count limit. After the completed artifact is returned, a separate utility-queue task removes process segments and legacy archives older than the physical 24-hour retention cutoff; the 2-hour submission cutoff is never used for deletion. The current `FileLogger` adapter reads that artifact into a `String` only for legacy callers; direct URL consumers and their cleanup contract remain a follow-up migration.

The View Debug Log screen presents that potentially large string through a scrolling `UITextView` with non-contiguous TextKit layout. It must not apply SwiftUI `drawingGroup` to the complete log: that forces the unbounded text into an offscreen rendered layer before it appears and made multi-megabyte logs take around a minute to become visible.

### 5. LogStore maintenance

Maintenance is limited to time-based segment creation and deletion. There is no historical decode/re-encode compaction cycle.

Each writer schedules an expired FIFO sweep when it initializes and repeats it whenever it creates or rotates a segment. After export returns its artifact, background cleanup also removes expired segments across every process directory, so cleanup does not depend on an extension launching. All paths use `LogRetention.duration`; correctness does not depend on parsing record contents to decide whether a closed time-bucketed segment has expired.

WSNet verbose generation is enabled only by `Env.isDebug`, which is derived from `#if DEBUG`. `FileLoggerImpl.logWSNet` also rejects decoded `.debug` records in non-`DEBUG` builds, so an unexpected library callback cannot bypass the application logger's release-level protection.

## Component dependencies

| Component | Dependencies | Must not depend on |
|---|---|---|
| `LogRecord`, `LogLevel`, `LogProcess` | Standard-library value types | UIKit, files, JSON, WSNet, app metadata |
| `LogMessagePolicy` | Record payload allowance | File size, export size, process identity |
| `BinaryLogRecordCodec` | `LogMessagePolicy` or an already-normalized `LogRecord` | FileManager, app-group paths, JSON formatting |
| `FileLogSegmentWriter` | Injected base URL, one `LogProcess`, FileManager/file handles | Other process directories, exporter, UI |
| `FileLogSegmentReader` | Injected base URL, FileManager/file handles | Append operations, feature code |
| `SegmentedLogWriter` | Injected `now: @Sendable () -> TimeInterval`, `LogRecordCoding`, process-scoped `LogSegmentWriting`, `LogMessagePolicy` | `LogExporting`, UIKit, WSNet, user scope |
| `JSONLogFormatter` | `LogRecord`, POSIX date formatting | Segment rotation, file writes |
| `JSONLogExporter` | Injected `now: @Sendable () -> TimeInterval`, `LogSegmentReading`, `LogRecordCoding`, `JSONLogFormatter`, `LogMetadataProviding` | Active writer internals, Swinject, feature state |
| `AppLogMetadataProvider` | Bundle/device information needed by the existing export format | Segment storage and writer state |


Storage receives URLs and process identity through initializers. It does not discover a composition root, read a global container, or call `Assembler.resolve`.

## Neo-4.0 composition alignment

The `neo-4.0` branch has retired Swinject and the generic `Assembler` graph. Its current ownership model is:

- `IOSCompositionRoot` owns one process-lifetime `CoreGraph` and one replaceable `UserScope`;
- `CoreGraph` owns dependencies that survive logout, including the current logger;
- `NeoEnvironmentCapabilities` is the typed SwiftUI capability installation surface;
- PacketTunnel, WireGuardTunnel, AppIntents/SiriIntents, HomeWidget, and tvOS each have independent target-local composition boundaries;
- target-local roots construct their own logger and do not resolve through the host app process.

The replacement logger follows those same boundaries. Logging is process-lifetime state, never user-scope state. Logout must not replace the writer or exporter.

This MR keeps `FileLoggerImpl` as the composition-facing compatibility facade. `main` changes `CoreModule` only enough to require an explicit process identity; `neo-4.0`'s manual roots can pass the same value directly. The direct narrow-capability examples below show the follow-up shape after legacy `FileLogger`/`LogStoring` consumers migrate; they are not additional container work in this MR.

### Host app composition

```swift
final class CoreGraph {
    let logger: any LogWriting
    let logExporter: any LogExporting

    init(
        logBaseURL: URL,
        process: LogProcess,
        now: @escaping @Sendable () -> TimeInterval = {
            Date().timeIntervalSince1970
        }
    ) {
        let codec = BinaryLogRecordCodec()
        let messagePolicy = LogMessagePolicy()

        let appSegments = FileLogSegmentWriter(
            baseURL: logBaseURL,
            process: process
        )
        logger = SegmentedLogWriter(
            now: now,
            codec: codec,
            segments: appSegments,
            messagePolicy: messagePolicy
        )

        let allSegments = FileLogSegmentReader(baseURL: logBaseURL)
        logExporter = JSONLogExporter(
            now: now,
            segments: allSegments,
            codec: codec,
            formatter: JSONLogFormatter(),
            metadata: AppLogMetadataProvider()
        )
    }
}
```

`IOSCompositionRoot` obtains the app-group container URL once and constructs `CoreGraph(logBaseURL:process:)` with `.app`. `TVCompositionRoot`, which also owns a `CoreGraph` on `neo-4.0`, also uses `.app`: iOS and tvOS run on different devices, so a separate directory identity adds no isolation. Tests inject a temporary directory instead. `CoreGraph` exposes the writer and exporter directly; it does not register them in a container.

The typed SwiftUI seam becomes conceptually:

```swift
struct NeoEnvironmentCapabilities: Sendable {
    let logger: any LogWriting
    let logExporter: any LogExporting
    // Other capabilities...
}

extension IOSCompositionRoot {
    func makeEnvironmentCapabilities() -> NeoEnvironmentCapabilities {
        NeoEnvironmentCapabilities(
            logger: core.logger,
            logExporter: core.logExporter
        )
    }
}
```

A screen reads the narrow capability it needs and constructor-injects it into its view model:

```swift
struct ViewLogScreen: View {
    @Environment(\.logExporter) private var logExporter

    var body: some View {
        ViewLogView(
            viewModel: ViewLogViewModel(logExporter: logExporter)
        )
    }
}

@MainActor
@Observable
final class ViewLogViewModel {
    private let logExporter: any LogExporting

    init(logExporter: any LogExporting) {
        self.logExporter = logExporter
    }
}
```

Features that only write logs receive `any LogWriting`. Features that export logs receive `any LogExporting`. This replaces the current broad `LogStoring` protocol without reintroducing Swinject or a service locator.

### PacketTunnel composition

```swift
final class PacketTunnelCompositionRoot {
    let logger: any LogWriting

    init(
        logBaseURL: URL,
        now: @escaping @Sendable () -> TimeInterval = {
            Date().timeIntervalSince1970
        }
    ) {
        let codec = BinaryLogRecordCodec()
        logger = SegmentedLogWriter(
            now: now,
            codec: codec,
            segments: FileLogSegmentWriter(
                baseURL: logBaseURL,
                process: .packetTunnel
            ),
            messagePolicy: LogMessagePolicy()
        )
    }
}
```

`PacketTunnelProvider` constructs this root in the PacketTunnel process, as it does on `neo-4.0`, and passes `logger` to tunnel dependencies through their constructors. The WSNet logging closure also calls this writer. PacketTunnel receives no `LogExporting` or cross-process `LogSegmentReading` capability.

### WireGuardTunnel composition

`WireGuardTunnelCompositionRoot` performs the same explicit construction with `LogProcess.wireGuardTunnel`. It passes `any LogWriting` to `WgCredentials`, `TunnelApiManager`, localization, WSNet, and the provider through constructors. It receives no exporter.

### AppIntents, SiriIntents, HomeWidget, and tvOS

- `AppIntentsCompositionRoot` constructs a writer with `.appIntents`.
- the current `SiriIntents` `ContainerResolver` constructs a writer with `.siriIntents`.
- `HomeWidgetCompositionRoot` constructs a writer with `.homeWidget`.
- `TVCompositionRoot` constructs a writer with `.app` and an exporter only if the tvOS product exposes log viewing/sharing.

These are independent process roots, not children of `IOSCompositionRoot`. Repeated construction code may be moved into a narrowly typed `LogWriterFactory` only if needed; it must not become a generic resolver or service locator.

### How processes share logs

The app and extensions share only the entitled app-group directory, not service instances or active files:

```text
iOS/tvOS host process -------> app/segment-*.wslg
PacketTunnel process --------> packet-tunnel/segment-*.wslg
WireGuardTunnel process -----> wireguard-tunnel/segment-*.wslg
AppIntents process ----------> app-intents/segment-*.wslg
SiriIntents process ---------> siri-intents/segment-*.wslg
HomeWidget process ----------> home-widget/segment-*.wslg
                                      |
                                      v
host-only FileLogSegmentReader -> JSONLogExporter
```

Each extension root injects the same app-group base URL and its own `LogProcess`; iOS and tvOS both use `.app` on their separate devices. A process-scoped writer can append only inside its own directory. The host exporter has read access to all directories and streams them when the user views, attaches, or shares logs. No extension calls into the host process, and no IPC is needed for normal writes.

## Implemented write flow

```text
log(level, module, message)
  -> normalize message to at most two lines
  -> create LogRecord, truncating only message if required
  -> enqueue on process-local writer
  -> encode one length-prefixed storage record
  -> add to bounded batch
  -> create a new segment if the time bucket changed
  -> append batch
```

The hot path has no historical read, JSON encode/decode, human-readable date formatting, sort, retention scan, or atomic full-file replacement.

## Implemented export flow

```text
user requests logs
  -> flush host writer
  -> snapshot process-owned segment paths
  -> visit process directories in deterministic order
  -> stream each process's valid records in stored order
  -> discard records outside the viewing or submission window
  -> format records as the current ordered JSON
  -> append metadata
  -> finish the streamed export file/output
```

An extension does not need to be running for its existing segments to be exported.

## Failure policy

- Message longer than two lines: keep the first two lines and append an explicit truncation marker.
- Encoded record larger than the per-record safety boundary: keep timestamp, level, and module/tag; truncate only the message until the record fits.
- Module/tag alone exceeds the record frame: drop the record because message-only truncation cannot make it valid.
- Segment creation or time/size rotation failure: drop the current batch; keep existing segments untouched.
- Append failure: drop the pending batch without retrying it. The failing append may have left a partial frame, so abandon that active segment and create a new one for later records. Preserve the earlier files and any complete frames already written.
- Pending queue saturation: drop the new record without blocking the caller or allocating another queued closure.
- `flushImmediately`: synchronously serialize and append the accepted record before returning.
- Partial final record: ignore it during export.
- Invalid record length or segment version: stop reading that segment without allocating the declared size.
- Invalid UTF-8 module/message: skip that record during export.
- Missing segment: continue with the remaining segments.
- Input seek/read failure: stop reading that input and continue with other segments; preserve records already decoded.
- Export output write/close failure: throw to the caller and remove the incomplete temporary artifact instead of returning it as a successful export.
- Export failure in one process directory: export the other directories.

All FileHandle reads, seeks, writes and closes in the logger use throwing APIs. Cleanup is best effort after an error and never writes another log message or starts a retry loop. Open-file factories allow tests to pass real read-only, closed and non-seekable handles through the production I/O paths.

Do not delete all logs because one read, decode, or write operation failed.

## Concurrency model

- One writer owns each process-specific active segment.
- No file is actively written by more than one process.
- Rotation is serialized by that process's writer.
- Export treats files as potentially changing and reads bounded snapshots defensively.
- Cross-process locking and file coordination are unnecessary because writers do not share an active file.

## Replacement test coverage

The unit tests in this MR cover:

- explicit `LogLevel` binary raw values and stable export strings;
- binary record round trips and stable little-endian golden bytes;
- non-finite timestamp rejection and recovery past invalid UTF-8 frames;
- explicit, distinct process identities including SiriIntents;
- two-line and UTF-8-safe message truncation;
- eager logger component construction without creating an empty startup segment;
- binary segment creation in a process-owned directory;
- concurrent write serialization;
- bounded pending work while a storage sink is blocked;
- separate app and tunnel paths;
- deterministic process-group export without a global timestamp sort;
- the ordered `tm`, `lvl`, `mod`, and `msg` JSON shape;
- WSNet payload and malformed-input compatibility;
- export beyond the legacy 120,000-character cap;
- 24-hour record filtering;
- expired closed-segment cleanup;
- oldest-first byte-budget cleanup and same-hour size rotation;
- a `DEBUG`-only burst warning after more than 1,000 records in one second;
- incomplete final-record recovery and a new segment after process restart;
- continued export when another segment has an invalid header;
- lossless archival and export of the legacy `windscribe.log` file;
- cleanup of legacy archives after their 24-hour migration window expires.

Failure-path tests also cover missing/read-only/closed/non-seekable append handles, cleanup after I/O failure, partial append isolation, recovery after segment creation failure, export output failure from segment/legacy/metadata sources, and continued export past unreadable input handles. CI additionally builds every target that contains the shared logging sources. Physical-device resource measurements and post-release crash-incidence comparison remain separate verification.

### Required invariants

- the writer does not append after segment creation or rotation failure;
- an append failure drops only the pending bounded batch and prevents later records from being appended behind an uncertain partial frame;
- app, PacketTunnel, and WireGuard writers cannot replace or truncate each other's files;
- one process's rotation cannot affect another process;
- each process directory remains within the configured byte budget after rotation;
- export skips malformed or unreadable segments while continuing with healthy segments;
- export never reads past the segment or legacy-archive byte length captured when that export starts;
- peak writer memory is bounded by the record and transient batch limits;
- PacketTunnel startup logging never parses historical records.

## Migration status

MR !1562 performs the replacement behind the existing `FileLogger` API:

1. `FileLoggerImpl` becomes a compatibility facade over the segmented writer and exporter.
2. New writes go only to process-owned binary segments.
3. The exporter reads process segments in deterministic process order and emits the existing JSON shape.
4. During logger initialization, `FileLoggerImpl` atomically moves the legacy `windscribe.log` JSON-lines file to a uniquely named, read-only `legacy-windscribe-<migration-time>-<uuid>.log` archive before starting the segmented writer. If the move fails, the source file remains in place.
5. The exporter reads recent records from that archive alongside segmented records, snapshots its input length, and removes the archive after `LogRetention.duration` from migration, when every record from the legacy retention window has expired.
6. The legacy shared-file writer, compactor, and append-before-compaction path are removed from `FileLoggerImpl`; 1 MiB append-only segments and oldest-first eviction enforce a 10 MiB budget per process.
7. The compatibility `getLogData() -> String` remains until existing consumers migrate to `LogExporting`; the new exporter itself streams through a temporary file.
8. `DEBUG` iOS app builds warn through the app boundary when more than 1,000 records arrive in one second. The detector and UI path are compile-time excluded from non-`DEBUG` builds.

## Decision guidance

MR !1559 remains a bounded-risk stabilization option for the legacy logger if a smaller patch must ship before the replacement. It should not be stacked onto MR !1562 without re-evaluating the overlapping `FileLoggerImpl` changes.

MR !1562 is the replacement path. Its review should focus on process isolation, record framing/recovery, compatibility of the exported JSON, the combined 24-hour/10 MiB retention bounds, extension startup cost, and lossless one-time legacy archival. The supplied crash reports still do not prove FileLogger caused the abort, so the replacement should be justified by the logger's independent architecture and resource problems as well as the crash hypothesis.
