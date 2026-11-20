# Changelog

Each release lists what changed since the release before it. The changes made
since the most recent release are under Unreleased.

## Unreleased

- Rewritten in Wattle as a single executable, `tenter`, with no Ruby
  dependencies. Settings that were given in `config.ru` are now command-line
  options, and `--no-log` replaces setting `log_file` to `nil`.
