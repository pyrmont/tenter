# Kyuji

Kyuji provides a simple API for requesting the execution of commands on a server.

## Overview

Kyuji is a minimal web app that processes requests for the execution of commands on the server running Kyuji. It is built on the Sinatra framework. Its intended use is as a means of providing webhooks that can be called by online services such as GitHub.

## Installation

```sh
$ git clone git@github.com:pyrmont/kyuji.git
    $ cd kyuji
    $ bundle install
    $ mkdir log
    $ mkdir -p tmp/puma
```

## Usage

Kyuji responds to POST requests sent to a URI of the form `/api/<version>/client/<client_id>/<command_name>`. All other forms of request are redirected to the root index.

If the request is authenticated and the command valid, the command will be executed and a successful status code returned. If not, an error status code will be returned.

### API Version

The API is currently at version 1.0.

### Clients

Authorized clients are defined in separate YAML files stored in `/clients`. An example file is included in the repo.

The YAML file should define a single-item hash with the key being the ID of the client. An ID must be an integer. The item is itself a hash setting out the following key/value pairs:

- `secret`: A secret token that is shared with the client.
- `method`: A method for authenticating requests. At present, the only authentication method is the [one used by GitHub][ghm] for its event webhooks.
- `command_dir`: The directory on the server in which the commands are located. This directory will also be used as the current directory for the environment in which the command is executed.

[ghm]: https://developer.github.com/webhooks/securing/

### Commands

Commands are executed by spawning a new process using Ruby's [`Process::spawn`][rds] method. As a result, they are run as the user that owns the process running Kyuji. Once spawned, the process is detached. The current working directory is set to be the same directory in which the process is running.

[rds]: http://ruby-doc.org/core-2.5.0/Process.html#method-c-spawn

## Requirements

Kyuji has been tested with Ruby version 2.3.2.

## Bugs

Found a bug? I'd love to know about it. The best way is to report them in the [Issues section][ghi] on GitHub.

[ghi]: https://github.com/pyrmont/kyuji/issues

## Versioning

Kyuji itself uses [Semantic Versioning 2.0.0][sv2]. The API uses only major and minor numbers.

[sv2]: http://semver.org/

## Licence

Kyuji is released into the public domain. See [LICENSE.md][lc] for more details.

[lc]: https://github.com/pyrmont/kyuji/blob/master/LICENSE.md
