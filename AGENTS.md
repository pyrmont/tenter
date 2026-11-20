# Tenter Project Guide

## Project Overview

Tenter is a web server that runs a command when GitHub sends it a signed
webhook. It is written in Wattle, a Lisp with Clojure-like syntax that runs
on a Zig rewrite of the Janet virtual machine. The executable is `tenter`.
It replaces the Ruby version of Tenter (0.2.0, Sinatra on Thin) on
a Linux server, where nginx terminates HTTPS and
forwards requests to Tenter on `127.0.0.1`. Its main job there is running
each site's `commands/rebuild`, which calls Ecstatic.

`PLAN.md` holds the design decisions and the milestones. Read it before
starting a milestone, and update it when a decision changes or a milestone
is done.

**Author**: Michael Camilleri
**License**: MIT
**Language**: Wattle
**Repository**: https://github.com/pyrmont/tenter

## Directory Structure

```
tenter/
├── lib/
│   ├── cli.wattle       # Command line (Gum's Argy-Bargy port), settings and `main`
│   ├── paths.wattle     # Valid names; resolving an exposed directory
│   ├── auth.wattle      # hooks.edn, HMAC-SHA256 signatures, `auth/check`
│   └── version.wattle   # Version label, fixed at compile time
├── test/
│   ├── auth.wattle        # Names, directories, secrets and signatures
│   ├── cli.wattle         # Settings from options
│   └── executable.wattle  # Runs zig-out/bin/tenter
├── res/
│   ├── fixtures/          # Trees the tests copy, one directory per test file
│   │   └── auth/          # www/ (a document root) and outside/
│   └── helpers/
│       └── util.wattle    # Copies a fixture to tmp/test/ (imported as `h`)
├── deps/gum/            # Vendored with `wattle gum args test`
├── info.edn             # Project and build declaration
├── CHANGELOG.md         # Changes by release, with an Unreleased section
└── PLAN.md              # Design and milestones
```

`PLAN.md` lists the modules still to be written (`server`, `runner` and
`log`).

## Security

Tenter runs programs on behalf of whoever can sign a request, so changes to
request handling, authentication and spawning need tests for the refusals as
well as for the successful path. In particular:

- A command is run only after the request's `X-Hub-Signature-256` matches
  the HMAC-SHA256 of the body under the directory's secret, compared with
  `crypto/equal?`.
- Every refusal before the signature is checked gives the same 403 response,
  so a caller cannot tell an unknown directory from a wrong signature.
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
  values with them rather than filling a table and converting it. Assoc-ing
  `nil` removes a key. Do not `freeze` results. State that changes over the
  life of the server is a `var` holding a persistent map, replaced with
  `assoc`, not a mutable table.
- **Mutable literals use `!`**: `![]` is an array, `!{}` a table and `!""` a
  buffer. `@[]` and `@{}` are parse errors. Keep them for accumulating inside
  one function, such as building a response in a buffer.
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
  the second and `$&` the rest. A short function whose body is a collection
  literal needs `do`, as in `#(do {:path $})`.
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
  handler.

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

The version stays `DEVEL` in `info.edn` between releases.

## Testing

Tests are plain Wattle scripts in `test/`, using `deps/gum/test.wattle`
(`deftest`, `is`, `run-tests!`). Run them from the project root.

The directory layout follows the one in "Recommended Directory Structure for
Janet Bundles" (articles.inqk.net, 2025-09-18): resources used by the
project, including test fixtures and helper scripts, go in `res/`, not in
`test/`. `wattle test` runs every file in `test/`, so `test/` holds only
test files.

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

A hook rejects shell commands that contain the word `sleep`, including
Wattle source with `ev/sleep` passed with `-e`. Put such code in a script
file and run the file.

## Common Tasks

### Adding a CLI option
1. Add it to the rules in `lib/cli.wattle`, to `defaults` and to `settings`.
2. Update the help text in `README.md` and `test/executable.wattle`.
3. Add an entry to the Unreleased section of `CHANGELOG.md`.
