# Tenter

Tenter is a web server that runs a command when GitHub sends it a signed
webhook. This repository provides `tenter`, a command-line utility written in
the [Wattle][] programming language.

[Wattle]: https://github.com/pyrmont/wattle

Tenter exposes URLs in the form `/run/<command>/in/<directory>`. A POST
request to such a URL that is signed with the directory's secret causes
Tenter to run `<doc-root>/<directory>/commands/<command>`.

Tenter is being rewritten. `PLAN.md` describes the design; the server itself
is not written yet.

## Building

To build the `tenter` binary from source, you need [Zig][] 0.17.1 and
Wattle, installed with the `<prefix>/share/wattle` support files. `-p` gives
the Wattle install prefix, or set `WATTLE_PREFIX` instead:

[Zig]: https://ziglang.org

```console
$ git clone https://github.com/pyrmont/tenter
$ cd tenter
$ wattle -p ~/.local build exe --release fast
```

The executable is at `zig-out/bin/tenter`. To build a static executable for a
Linux server:

```console
$ wattle -p ~/.local build exe --release fast -t x86_64-linux-musl
```

## Usage

```
Usage: tenter [--host <address>] [--port <port>] [--doc-root <dir>] [--config-filename <name>] [--command-dir <name>]
              [--log-file <path>] [--no-log] [--no-timestamp]

Run commands in response to signed GitHub webhooks.

Options:

 -H, --host <address>            The address to listen on. (Default: 127.0.0.1)
 -p, --port <port>               The port to listen on. (Default: 4567)

 -r, --doc-root <dir>            The directory that holds each exposed directory. (Default: /var/www)
     --config-filename <name>    The name of the configuration file in each exposed directory. (Default: hooks.edn)
     --command-dir <name>        The name of the directory of commands in each exposed directory. (Default: commands)
     --log-file <path>           The path of the log in each exposed directory. (Default: log/commands.log)
     --no-log                    Discard the output of commands.
     --no-timestamp              Do not prefix log lines with the time.

 -v, --version                   Show version information.

 -h, --help                      Show this help message.
```

## Licence

Tenter is licensed under the MIT Licence. See [LICENSE][] for more details.

[LICENSE]: LICENSE
