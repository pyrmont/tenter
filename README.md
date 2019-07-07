# Tenter

Tenter is a Sinatra-based web application that provides webhooks for use by
GitHub.

## Rationale

Webhooks offer the promise of being able to execute arbitrary actions in
response to events occurring in a GitHub Repository. Sounds amazing. Except
who's going to set up a server to receive each request, confirm its authenticity
and then process it appropriately?

Tenter makes that all easy. Tenter runs on any Rack-compatible server and
exposes a simple URL in the form of `/run/<command>/in/<directory>`. An
authenticated POST request to this URL will cause Tenter to execute the command
at `/<doc_root>/<directory>/commands/<command>`. The defaults are all sane but
you can customise them as you please.

Enough jibber jabber. Let's get to the action.

## Installation

Tenter is available as a gem:

```shell
$ gem install tenter
```

Now create a `config.ru` file in the directory where you'll run Tenter:

```ruby
require "tenter"

run Tenter::Hooks
```

The final step:

```shell
$ rackup
```

And you're off to the races.

## Usage

The easiest way to understand how Tenter works is to first imagine a directory
structure like this:

```
doc/
├─root/
│ ├─my_dir/
│ │ ├─commands/
│ │ │ ├─my_action
│ │ ├─log/
│ │ ├─hooks.yaml
```

By setting up Tenter to listen on a particular domain (eg. `example.org`) and to
treat `/doc/root` as the document root, we expose a webhook that will allow
`my_action` to be run by sending a POST request to
<http://example.org/run/my_action/in/my_dir/>.

## Configuration

Tenter adopts convention over configuration as much as possible.

The only thing you need to set is the `secret` in each exposed directory's
`hooks.yaml` file. When you set up the webhook in your GitHub repository's
settings, GitHub will ask you for this secret. GitHub will use the secret to
sign its POST requests and it's this signature that Tenter validates before
running commands.

Of course, if you want, you can tweak the following settings as you please:

- `:doc_root` (default: `"/var/www"`): The root directory in which each exposed
  directory will be located. It's recommended to specify this as an absolute
  path.

- `:config_filename` (default: `"hooks.yaml"`): The filename of the
  configuration file in each exposed directory.

- `:command_dir` (default: `"commands"`): The name of the subdirectory holding
  the commands for each exposed directory.

- `:log_file` (default `"log/commands.log"`): The path to the log file in each
  exposed directory where output from your commands will be logged. You can set
  this to `nil` to disable logging.

To change these settings, simply assign a hash with the defaults you want to
change in your `config.ru` file:

```ruby
require "tenter"

Tenter.settings = { log_file: nil } # disable logging

run Tenter::Hooks
```

### Limitations

Tenter does not currently provide the ability to use different settings for
different exposed directories. If you want that kind of fine-grained control,
you can run multiple instances of Tenter.

## Bugs

Found a bug? I'd love to know about it. The best way is to report them in the
[Issues section][ghi] on GitHub.

[ghi]: https://github.com/pyrmont/tenter/issues

## Versioning

Tenter uses [Semantic Versioning 2.0.0][sv2].

[sv2]: http://semver.org/

## Licence

Tenter is released into the public domain. See [LICENSE.md][lc] for more details.

[lc]: https://github.com/pyrmont/tenter/blob/master/LICENSE.md
