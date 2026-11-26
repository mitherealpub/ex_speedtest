# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com),
and this project adheres to [Semantic Versioning](https://semver.org).

## - 2026-11-25

### Added
- **HTTP latency probing (`:http` method):** `Speedtest.Ping.ping/2` now supports Ookla's `/speedtest/latency.txt` HTTP probe as the default method, enabling latency checks in containerized and cloud environments (such as Docker and Render) without raw ICMP socket permissions.
- **Configurable ping options:** `Speedtest.Ping.ping/2`, `Speedtest.choose_best_server/2`, and `Speedtest.run/1` accept `:method` (`:http` or `:icmp`), `:count`, and `:timeout` options.
- **Pluggable HTTP client (`Speedtest.HTTP`):** Added a `Speedtest.HTTP` behaviour with a default `Speedtest.HTTP.HTTPoison` adapter, allowing offline mocking in tests via `Mox`.
- **Automatic `ignoreids` filtering:** `Speedtest.run/1` now merges server IDs from `<server-config ignoreids="...">` into the excluded servers list automatically.
- **Fallback server endpoints:** `Speedtest.fetch_servers/1` now iterates through all fallback Speedtest server list URLs if the primary URL fails.
- **ExUnit test suite:** Added unit and mocked integration tests covering `Speedtest`, `Speedtest.Decoder`, `Speedtest.Ping`, and `Speedtest.Result`.

### Changed
- **Concurrent probing and transfers:** Replaced sequential server pings and chunked task batches with `Task.async_stream/3` for bounded concurrency in `choose_best_server/2`, `download/1`, and `upload/1`.
- **Consistent `{:ok, result} | {:error, reason}` tuples:** `Speedtest.Result.share/1` and `Speedtest.choose_best_server/2` now return tagged `{:ok, ...}` / `{:error, ...}` tuples instead of raising on HTTP or network failures.
- **SweetXml direct type casting:** Refactored `Speedtest.Decoder` to use SweetXml sigil modifiers (`s`, `i`, `f`) and accept either response maps (`%{body: ...}`) or raw XML strings.
- **Consolidated result math:** Extracted `Speedtest.Result`'s upload and download throughput calculations into a single-pass `Enum.reduce/3` helper with division-by-zero guards.

### Fixed
- **Upload payload transmission:** `Speedtest.upload/1` now sends an actual byte payload matching the configured upload size instead of an empty body with a mismatched `Content-Length` header.
- **Server `include` / `exclude` filtering:** Fixed server list filtering so `:include` and `:exclude` match against server `:id` strings using a `MapSet` rather than comparing IDs against full server maps.
- **Best server selection sorting:** Filtered out failed ping tuples before finding the minimum RTT so `:error` tuples are never sorted ahead of `:ok` results.
- **Download URL scheme & case-insensitive headers:** Added the `http://` scheme prefix to generated download URLs and switched `Content-Length` lookup to case-insensitive matching with a `byte_size/1` fallback.
- **ICMP `ping` parsing & cross-platform flags:** Removed `-s 1` (which omitted RTT summaries on Linux `iputils-ping`), added support for both Linux/BusyBox (`-w`) and macOS (`-t`) timeout flags, and parsed floating-point average RTTs across all probes.
- **XML decoding bugs in `Speedtest.Decoder`:** Fixed `socket_download/1` and `socket_upload/1` referencing `data` instead of `result`, and ensured `<server-config>` attributes return Elixir binaries instead of charlists.
- **Multi-digit `resultid` parsing:** Updated the share response regex in `Speedtest.Result.share/1` from `resultid=(.)` to `resultid=(\d+)` so full result IDs are captured.

## - Previous Release
- Initial Hex release of `speedtest`.
