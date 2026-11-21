# Tenter Project Guide

## Project Overview

Tenter is a web server that runs a command when GitHub sends it a signed
webhook. It is written in Wattle, a Lisp with Clojure-like syntax that runs
on a Zig rewrite of the Janet virtual machine. The executable is `tenter`.
It replaces the Ruby gem (last released as 0.2.0), whose source is on the
`ruby` branch.

## Directory Structure

```
tenter/
├── lib/
│   ├── cli.wattle       # Command line (Gum's Argy-Bargy port), settings, `serve` and `main`
│   ├── server.wattle    # HTTP: reading requests, limits, routing, responses
│   ├── paths.wattle     # Valid names; resolving an exposed directory
│   ├── auth.wattle      # hooks.edn, HMAC-SHA256 signatures, `auth/check`
│   ├── runner.wattle    # Command paths, spawning, the per-command queue
│   ├── log.wattle       # Timestamped log lines, splitting output into lines
│   └── version.wattle   # Version label, fixed at compile time
├── test/
│   ├── auth.wattle        # Names, directories, secrets and signatures
│   ├── cli.wattle         # Settings from options
│   ├── runner.wattle      # Commands, logs, environment and the queue
│   ├── server.wattle      # Parsing, routing and requests over a socket
│   └── executable.wattle  # Runs zig-out/bin/tenter, including a sandboxed run
├── res/
│   ├── fixtures/          # Trees the tests copy, one directory per test file
│   │   ├── auth/          # www/ (a document root) and outside/
│   │   └── runner/        # www/ with commands for each case, outside/
│   ├── helpers/
│   │   └── util.wattle    # Copies a fixture to tmp/test/ (imported as `h`)
│   ├── deploy/            # Examples: nginx/tenter.conf, runit/tenter/
│   └── tools/
│       └── version.wattle # Sets the version (release tooling)
├── man/man1/
│   ├── tenter.1.predoc  # Man page source (Predoc)
│   └── tenter.1         # Generated man page (committed)
├── deps/gum/            # Vendored with `wattle gum args test`
├── .github/workflows/
│   ├── test.yml         # Builds Wattle, builds Tenter, runs the tests
│   └── release.yml      # Builds release archives and drafts a GitHub release
├── info.edn             # Project and build declaration
├── CHANGELOG.md         # Changes by release, with an Unreleased section
└── RELEASING.md         # Steps for making a release
```

## Requests

`server/handler` answers each connection in its own fiber. A request is
refused on its head (`server/check-head`: path, method and length) before
its body is read, and its body is read in full before `auth/check`, since
the signature covers the body. `server/answer` then calls `runner/start`.
Each step returns a reply map (`:status`, `:body`, and `:reason` for the
server's stderr), and only the handler writes to the socket.

Connection fibers do not see the dynamic bindings of the code that started
the server, so `server/handler` captures `*out*` and `*err*` when it is
made; the tests rely on this to read the server's output. Test-only
settings, `:read-timeout` and `:max-connections`, override the limits in
`lib/server.wattle`. Pass changes to settings as a function that `assoc`s
(a map of changes cannot hold `nil`, so cannot turn a setting off).

The sandbox call is in `cli/serve`, after the listener is open and the
environment for commands has been read. Code that runs after it cannot
compile, read the environment, connect out or unmarshal. Check a change
that touches the request path with the built executable
(`test/executable.wattle`), not only in-process, since only the executable
calls `sandbox`.

## Runs

`runner/start` runs a command on the event loop and returns at once. The
state of the runs is `runs`, a `var` holding a persistent map from a
command's resolved path to `:running` or `:pending`. Only `runner/start` and
the run loop change it. A run's output is read from one pipe (stderr is sent
to stdout) and written to the log a line at a time, so the log shows output
as it arrives. Tests wait for a run with `runner/status`.

## Security

Tenter runs programs on behalf of whoever can sign a request, so changes to
request handling, authentication and spawning need tests for the refusals as
well as for the successful path. In particular:

- A command is run only after the request's `X-Hub-Signature-256` matches
  the HMAC-SHA256 of the body under the directory's secret, compared with
  `crypto/equal?`.
- An unknown directory, an unusable `hooks.edn` and a wrong signature all
  give the same 403 response, so a caller cannot tell them apart.
- Commands are run with `os/spawn` and an argument vector, never through a
  shell, and only if the resolved path is inside the directory's command
  directory.
- Configuration files are read with `edn/decode`, which evaluates nothing.
  Do not use `parse`, `eval` or `dofile` on files under the document root.

## Writing Wattle

Wattle is not Janet. Code copied from Janet or written from memory of it often
fails to parse or means something else:

- **Prefer persistent collections.** `[...]` is a persistent vector, `{...}`
  a persistent map and `#{...}` a set. `assoc`, `conj`, `dissoc` and `disj`
  return a new collection that shares structure with the old one, so build
  values with them rather than filling a table and converting it. A map
  cannot hold `nil` and `assoc` with a `nil` value removes the key. Do not
  `freeze` results. State that changes over the life of the server is a
  `var` holding a persistent map, replaced with `assoc`, not a mutable
  table.
- **Mutable literals use `!`**: `![]` is an array, `!{}` a table and `!""` a
  buffer. `@[]` and `@{}` are parse errors. Keep them for accumulating inside
  one function, such as building a response in a buffer.
- **Functions that mutate end in `!`**: `buffer/clear!`, `buffer/push!`,
  `array/push!`, `put!`. Janet's names without `!` (`buffer/clear`) do not
  exist.
- **`merge` returns a mutable table.** Extend a map with
  `(assoc m :k v :k2 v2)`.
- **There is no persistent `update`**; write `(assoc m k (f (get m k)))`.
  `update!` and `update-in!` are for tables. `mapv`, `filterv`, `into`,
  `select-keys`, `assoc-in`, `eachp`, `doseq` and `some` do not exist. Use
  `find` with a predicate, or `any?` on values, in place of `some`.
- **Iterating a map**: `(each [k v] (pairs m) ...)`, or `eachk` and `eachv`.
- **`map`, `filter` and similar return arrays**, which compare by identity.
  Compare results with `==` in tests, or convert them.
- **`(...)` is a tuple** and is only for calls; use vectors for data. There
  are no structs.
- **Splice is `|`**: `(f |args)`, `["cmd" |args]`. A `;` starts a comment;
  `#` does not.
- **Short functions are `#(...)`**: `$` (or `$0`) is the first argument, `$1`
  the second and `$&` the rest. `|(...)` is a splice, not a function. If
  the body of a short function is a collection literal, it needs `do`, as
  in `#(do {:path $})`.
- **Quasiquote is a backtick and unquote is `~`**, as in a PEG grammar that
  calls a function: `` `(/ (<- :d) ~f) ``. A backtick is not a string
  delimiter. Use `"..."` or a raw string, `"""..."""`, which drops the line
  break before its closing quotes. Docstrings use `"""`.
- **Parameter lists are vectors**, `& rest` binds a vector, and named options
  are `& {:keys [a b] :or {a 1}}`. Map patterns put the binding first:
  `{name :name}`.
- **Argument order differs from Janet in places**: `(string/join sep parts)`
  takes the separator first, like `string/split` and `string/find`.
- **`os/date` is UTC by default**, and `:month` and `:month-day` count from
  0.
- **`doc` is a macro**, so do not bind it as a name. `chr` is a compile-time
  macro that takes a literal.
- **Error helpers**: `error`, `errorf`, `assertf`, and `try` with a `([e] ...)`
  handler. `net/read` raises the string `"timeout"` when its timeout passes.

`man 7 wattle` describes the language and `../wattle/notes/LANGUAGE.md`
records how it differs from Janet. When unsure of a binding, check it with
`(doc sym)`. Run `wattle check <file>` on each changed file (one file per
call).

## Build

The build is declared in `info.edn` and driven by `wattle build exe`. There is
no `build.zig`.

```bash
wattle build exe                                        # zig-out/bin/tenter
wattle build exe --release fast -t x86_64-linux-musl    # static Linux binary
```

A musl build replaces `zig-out/bin/tenter`, so run `wattle build exe` again
before `wattle test`.

The man page source is `man/man1/tenter.1.predoc`. Regenerate
`man/man1/tenter.1` with `predoc man/man1/tenter.1.predoc -o
man/man1/tenter.1` and commit both. Code blocks in Predoc use four
backticks.

The version stays `DEVEL` in `info.edn` and the man page between releases;
`RELEASING.md` describes a release.

The files in `res/deploy/` are examples for any server, so they name no
particular host. Keep them in step with the defaults and the man page.

## Testing

Tests are plain Wattle scripts in `test/`, using `deps/gum/test.wattle`
(`deftest`, `is`, `run-tests!`). Run them from the project root.

`wattle test` runs every file in `test/`, so `test/` holds only test files.
Fixtures and helper scripts go in `res/`.

Fixtures are committed trees in `res/fixtures/`, including symlinks and
executable files. An empty directory holds a `.gitkeep`, which
`h/copy` leaves out. A test copies its fixture to `tmp/test/` with
`h/copy` (from `res/helpers/util.wattle`), works on the copy, and
removes it when it finishes, so the tests never change `res/`. `tmp/` is
ignored by Git.

```bash
wattle build exe      # test/executable.wattle runs zig-out/bin/tenter
wattle test
```

## Common Tasks

### Adding a CLI option
1. Add it to the rules in `lib/cli.wattle`, to `defaults` and to `settings`.
2. Update `man/man1/tenter.1.predoc`, regenerate `tenter.1`, and update the
   help text in `README.md` and `test/executable.wattle`.
3. Add an entry to the Unreleased section of `CHANGELOG.md`.

### Changing a response or a limit
1. Update `lib/server.wattle` and its tests.
2. Update RESPONSES in `man/man1/tenter.1.predoc` (and regenerate
   `tenter.1`), and `res/deploy/nginx/tenter.conf` if the body limit
   changes.
3. Add an entry to the Unreleased section of `CHANGELOG.md`.
