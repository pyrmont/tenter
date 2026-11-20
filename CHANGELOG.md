# Changelog

Each release lists what changed since the release before it. The changes made
since the most recent release are under Unreleased.

## 0.1.0 (2026-11-21)

The first release of Tenter written in Wattle. It replaces the Ruby gem,
last released as 0.2.0, whose source is on the `ruby` branch. The
differences from the gem are:

- Tenter is a single executable, `tenter`, with no Ruby dependencies. It
  is its own HTTP server and listens on `127.0.0.1:4567` by default
  (`--host`, `--port`); use a reverse proxy such as nginx for HTTPS.
  Settings that were given in `config.ru` are now command-line options,
  and `--no-log` replaces setting `log_file` to `nil`.
- Requests are limited to 16 KiB of headers and 1 MiB of body, must give
  `Content-Length`, and must arrive within 10 seconds. At most 32
  connections are handled at once. Only `POST` to a command URL is
  answered.
- Once listening, Tenter gives up the capabilities it does not need, such
  as compiling code, reading the environment and making outbound
  connections.
- Added a man page, `tenter(1)`, and example nginx and runit configuration
  in `res/deploy/`. The README describes moving from Tenter 0.2.
- Requests are authenticated with `X-Hub-Signature-256` (HMAC-SHA256)
  instead of `X-Hub-Signature` (HMAC-SHA1), compared in constant time.
- Each exposed directory's configuration is `hooks.edn`, a map with a
  `:secret` string, instead of `hooks.yaml`. A file that is missing, is not
  EDN, has another key or has an empty secret refuses the request.
- Directory and command names in the URL are limited to letters, digits,
  `.`, `_` and `-`, beginning with a letter, digit or `_`. An exposed
  directory that resolves to a path outside the document root is refused.
- Commands are run directly rather than through a shell, with their output
  timestamped by Tenter. The log ends each run with a `Finished:` line that
  gives the exit status, or a `Failed:` line if the command could not be
  started.
- A command must be an executable file directly in the command directory;
  a symlink in its place is refused. If the log cannot be opened, the
  command is not run.
- A command that is already running is not started again. Requests that
  arrive during a run cause one more run when it ends.
- Commands get only `PATH`, `HOME`, `LANG`, `LC_ALL` and `TZ` from Tenter's
  environment, plus `TENTER_DIRECTORY` and `TENTER_COMMAND`, and read
  standard input from `/dev/null`.
