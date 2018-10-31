# Courier

A library to represent emails in transit and to transfer them.

NOTE: This library is a work in progress and is not ready for use.

## Features

- An Address class to represent senders and recipients (pending)
- A Message class to represent emails (pending)
- A configurable persistence layer to store messages (pending)
- A configurable authentication process (pending)
- An SMTP server capable of:
  - being configured from code (pending)
  - message ingest (pending)
  - message relay (pending)
  - SMTP authentication (pending)
- A POP3 server capable of:
  - being configured from code (pending)
  - message retrieval (pending)
  - authentication (pending)
- An IMAP4 server capable of:
  - being configured from code (pending)
  - message retrieval (pending)
  - authentication (pending)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  courier:
    github: requnix/courier
```

## Usage

```crystal
require "courier"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1.  Fork it ( https://github.com/requnix/courier/fork )
2.  Create your feature branch (git checkout -b my-new-feature)
3.  Commit your changes (git commit -am 'Add some feature')
4.  Push to the branch (git push origin my-new-feature)
5.  Create a new Pull Request

## Contributors

- [requnix](https://github.com/requnix) Michael Prins - creator, maintainer
