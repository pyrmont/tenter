# Tenter

[![Latest Release][release-badge]][release-latest]
[![Test Status][test-badge]][test-status]

[release-badge]: https://img.shields.io/github/v/release/pyrmont/tenter
[release-latest]: https://github.com/pyrmont/tenter/releases/latest
[test-badge]: https://github.com/pyrmont/tenter/actions/workflows/test.yml/badge.svg
[test-status]: https://github.com/pyrmont/tenter/actions/workflows/test.yml

Tenter is a web server that runs a command when GitHub sends it a signed
webhook. This repository provides `tenter`, a command-line utility written in
the [Wattle][] programming language.

[Wattle]: https://github.com/pyrmont/wattle

Tenter exposes URLs in the form `/run/<command>/in/<directory>`. A POST
request to such a URL that is signed with the directory's secret causes
Tenter to run `<doc-root>/<directory>/commands/<command>`.

Tenter is its own HTTP server and does not use TLS. It listens on
`127.0.0.1` by default, for use behind a reverse proxy such as nginx that
provides HTTPS.

## Building

#### Pre-Built

Pre-built binaries of `tenter` are available as tarballs via the
[Releases][github-releases] section on GitHub for:

- Linux (x86-64 and aarch64, statically linked)
- macOS (aarch64)

[github-releases]: https://github.com/pyrmont/tenter/releases

```console
$ curl -LO https://github.com/pyrmont/tenter/releases/latest/download/tenter-<version>-<platform>-<arch>.tar.gz
$ tar -xzf tenter-<version>-<platform>-<arch>.tar.gz
$ cd tenter-<version>
```

Each tarball holds the binary, the man page and the examples in
`res/deploy/`.

#### From Source

To build the `tenter` binary from source, you need [Zig][] 0.17.1 and
Wattle, installed with the `<prefix>/share/wattle` support files. `-p` gives
the Wattle install prefix, or set `WATTLE_PREFIX` instead:

[Zig]: https://ziglang.org

```console
$ git clone https://github.com/pyrmont/tenter
$ cd tenter
$ wattle -p ~/.local build exe --release fast
```

The executable is at `zig-out/bin/tenter`. It includes the Wattle runtime, so
the target system does not need Wattle to be installed. To build a static
executable for a Linux server:

```console
$ wattle -p ~/.local build exe --release fast -t x86_64-linux-musl
```

## Installing

Move the `tenter` binary somewhere on your path and the man page to the
appropriate location. For example:

```console
# use sudo or doas depending on the permissions of the target directories
$ sudo cp zig-out/bin/tenter /usr/local/bin/
$ sudo cp man/man1/tenter.1 /usr/local/share/man/man1/
```

If you have Wattle installed, you can instead build and install `tenter` and
its man page under your `WATTLE_PREFIX` in one step:

```console
$ wattle apps install https://github.com/pyrmont/tenter
```

## Using

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

See [`tenter(1)`][tenter-man] for the full reference (`man tenter`).

[tenter-man]: man/man1/tenter.1.predoc

### Exposing a Directory

Each directory under the document root can be exposed. With the defaults, a
directory looks like this:

```
/var/www/example.org/
├── hooks.edn
├── commands/
│   └── rebuild
└── log/
```

`hooks.edn` holds the directory's secret, as an EDN map:

```clojure
{:secret "a long random string"}
```

Tenter reads the file as data and evaluates nothing in it. Make it readable
only by the user that runs Tenter.

Each file in `commands/` is a command. It must be executable (and a script
must begin with a `#!` line), and it cannot be a symlink. A POST to
`/run/rebuild/in/example.org/` runs `commands/rebuild` in the `commands/`
directory, with its output appended to `log/commands.log`. `log/` must exist.

A command gets `PATH`, `HOME`, `LANG`, `LC_ALL` and `TZ` from Tenter's
environment, plus `TENTER_DIRECTORY` and `TENTER_COMMAND`, and nothing else.
Only one run of a command is in progress at a time: requests that arrive
during a run cause one more run when it ends.

### Setting Up a Webhook

In the settings of a GitHub repository, add a webhook with:

- **Payload URL**: `https://<host>/run/<command>/in/<directory>/`
- **Content type**: either; the signature covers the body as it is sent
- **Secret**: the `:secret` in the directory's `hooks.edn`

GitHub shows each delivery and Tenter's response. A wrong secret gets 403
`X-Hub-Signature-256 header did not match`, as does an unknown directory.

### Deploying

`res/deploy/` has examples for a Linux server:

- `nginx/tenter.conf`, a location block that forwards `/run/` from an HTTPS
  server block to Tenter on `127.0.0.1:4567`;
- `runit/tenter/`, a runit service that runs Tenter as an unprivileged user
  and logs its output with `svlogd`.

Run Tenter as a user that owns the exposed directories, not as root. Its
commands run as the same user.

### Moving from Tenter 0.2

Tenter 0.2 was a Ruby gem. To move a server to this version:

1. Replace each directory's `hooks.yaml` (`secret: <value>`) with
   `hooks.edn` (`{:secret "<value>"}`). Tenter does not read `hooks.yaml`.
2. Move any settings from `config.ru` to command-line options:
   `doc_root` to `--doc-root`, `config_filename` to `--config-filename`,
   `command_dir` to `--command-dir`, `log_file` to `--log-file` (or
   `--no-log` for `nil`) and `timestamp: false` to `--no-timestamp`.
3. Check that each command is an executable file, not a symlink, with a
   `#!` line, and does not rely on environment variables other than those
   above.
4. Point the reverse proxy at Tenter's address and stop the Ruby server.

The webhooks on GitHub do not need to change: GitHub sends the
`X-Hub-Signature-256` header that Tenter checks on every delivery.

## Licence

Tenter is licensed under the MIT Licence. See [LICENSE][] for more details.

[LICENSE]: LICENSE
