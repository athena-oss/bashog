# basHog [![Build Status](https://travis-ci.org/athena-oss/bashog.svg?branch=master)](https://travis-ci.org/athena-oss/bashog)

basHog is a dependency manager for bash and it allows you to use other projects in your own project.

## Quick start

Prerequisites
 * You have a `bash` shell.
 * You have either `git`, `curl` or `wget`

There are three quick start options available:

* On MAC OSX using [Homebrew](http://brew.sh/) :
```bash
$ brew tap athena-oss/tap
$ brew install bashog
```
* [Download the latest release](https://github.com/athena-oss/bashog/releases/latest)
* Clone the repo: `git clone https://github.com/athena-oss/bashog.git`


## How does it work

basHog fetches dependencies specified in a file called `feed.hog` that must be located at the root of your project. This file uses the [INI file](https://en.wikipedia.org/wiki/INI_file) format with sections.

A dependency is identified by a **section header** and it is configured by the properties that are specified in that section. There are 3 available properties for a dependency :

* **url** - it identifies the url where the dependency can be fetched, e.g.:

```bash
# retrieves the dependency from master
url=git@github.com:athena-oss/bashunit.git

or

# using this format you are required to specify the version property
url=athena-oss/bashunit
```

* **lib_dir** - the relative location inside the project where the libraries are located, e.g.:

```bash
lib_dir=lib
```

* **version** - the version of the dependency

```bash
version=0.3.0
```
## 1. Declaring dependencies in `feed.hog`

### 1.1 using version in master (`git` only)
```bash
[bashunit]
url=git@github.com:athena-oss/bashunit.git
lib_dir=lib
```

### 1.2 using a specific version (`curl` or `wget` only)
```bash
[bashunit]
url=athena-oss/bashunit
version=0.3.0
lib_dir=lib
```

## 2. Fetching the dependencies

At the root of your project (where the `feed.hog` file is located), run the following command :

```bash
$ bashog
```

## 3. Using the dependencies in your project

```bash
...
source "./vendor/autoloader.sh"

bashunit.utils.print_info "Hello world!"
...
```

## Contributing

Checkout our guidelines on how to contribute in [CONTRIBUTING.md](CONTRIBUTING.md).

## Versioning

Releases are managed using github's release feature. We use [Semantic Versioning](http://semver.org) for all
the releases. Every change made to the code base will be referred to in the release notes (except for
cleanups and refactorings).

## License

Licensed under the [Apache License Version 2.0 (APLv2)](LICENSE).
