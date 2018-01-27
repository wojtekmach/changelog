# Changelog

:warning: Work in progress :warning:

Print changelog for a Hex package.

## Usage

Entire changelog:

```
$ mix changelog ecto
## 2.2.8 - 2018-01-13
(...)
```

Changelog for just one version:

```
$ mix changelog ecto 2.2.0
## 2.2.0 - 2017-08-22
(...)

$ mix changelog ecto latest
## 2.2.8 - 2018-01-13
(...)
```

Changelog between versions:

```
$ mix changelog ecto 2.2.6 2.2.7
## 2.2.7 - 2017-12-03
(...)
## 2.2.6 - 2017-09-30

$ mix changelog ecto 2.2.6 latest
## 2.2.8 - 2018-01-13
(...)
## 2.2.7 - 2017-12-03
(...)
## 2.2.6 - 2017-09-30
(...)
```

We can also fetch changelog directly from GitHub:

```
$ mix changelog github:elixir-lang/elixir
## 1.7.0-dev
(...)
```

## Roadmap

- :warning: stop using private Hex APIs!
- nicer printing
- better error handling

## Setup

```
$ mix archive.install github wojtekmach/changelog
```

## License

[Apache 2.0](./LICENSE.md)
