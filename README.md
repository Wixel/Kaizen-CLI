# Kaizen-CLI
A Ruby Gem for the [Kaizen Front-end Framework](http://wixel.github.io/Kaizen/)

## Installation

```sh
gem install kaizen-cli
```

#### Requirements

- **[Ruby](https://www.ruby-lang.org/)**

#### Getting started

- Run: `kzn [directory] -n` - Create a new Kaizen project in the specified directory
- Run: `kzn [directory] -f` - Overwrite files that already exist in the target directory
- Run: `kzn [directory] -w` - Watch the specified directory for Sass changes and compile them automatically
- Run: `kzn [directory] -s` - Start serving the specified directory from the built-in web server
- Run: `kzn --help` for further instructions

If something does happen to go wrong, you can add the `-v` argument to enable more verbosity.
