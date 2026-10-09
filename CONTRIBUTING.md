# Contributing

This document describes how to set up, test and make changes to the classic Heroku Python buildpack.

Please open an issue to discuss any non-trivial change before opening a pull request. Participation
is subject to the [Code of Conduct](CODE_OF_CONDUCT.md), and security issues should be reported as
described in [SECURITY.md](SECURITY.md).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (for `make run`)
- [Ruby](https://www.ruby-lang.org/) and [Bundler](https://bundler.io/) (see `Gemfile` for the supported Ruby versions)
- [ShellCheck](https://www.shellcheck.net/) and [shfmt](https://github.com/mvdan/sh#shfmt) (for linting)
- The [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli), logged in to a Heroku account
  (for the integration tests)

Then install the Ruby dependencies:

```
bundle install
```

## Linting and formatting

| Command             | Description                                   |
| ------------------- | --------------------------------------------- |
| `make lint`         | Runs all of the checks below                  |
| `make lint-scripts` | Lints the Bash scripts using ShellCheck       |
| `make check-format` | Checks the Bash script formatting using shfmt |
| `make lint-ruby`    | Lints the Ruby tests using RuboCop            |
| `make format`       | Auto-formats the Bash scripts using shfmt     |

## Running the buildpack locally

`make run` runs the buildpack's `detect`, `compile` and `report` steps against a test fixture inside a
Docker container, which is the quickest way to try out a change:

```
make run FIXTURE=spec/fixtures/<fixture-name>
```

`FIXTURE` defaults to `spec/fixtures/python_version_unspecified`. To run against a different stack than
the default (`heroku-26`), also pass `STACK`, for example `STACK=heroku-24`.

## Integration tests

The integration tests in `spec/hatchet/` use [Hatchet](https://github.com/heroku/hatchet) to deploy
the fixtures in `spec/fixtures/` to real Heroku apps using this buildpack, and then assert on the
build output and the behaviour of the deployed app. They are slow, and create temporary apps on the
Heroku account you are logged in to (Hatchet deletes the oldest ones once `HATCHET_APP_LIMIT` is
reached, which defaults to `50` locally).

Hatchet deploys the buildpack from GitHub, so push your branch to the repository (or your fork,
by setting `HATCHET_BUILDPACK_BASE`) before running the tests.

Run all of the integration tests, in parallel:

```
bundle exec parallel_split_test spec/hatchet/
```

Run all of the tests in one file:

```
bundle exec rspec spec/hatchet/pip_spec.rb
```

Run a single test, by its line number or by a substring of its description:

```
bundle exec rspec spec/hatchet/pip_spec.rb:134
bundle exec rspec spec/hatchet/pip_spec.rb -e "requirements.txt has changed"
```

Alternatively, temporarily change `it`, `context` or `describe` to `fit`, `fcontext` or `fdescribe`
(or add `:focus` metadata) to run only the focused tests whenever a file or directory is run. Revert
these changes before committing.

By default the tests deploy using the `heroku-26` stack. To use another stack:

```
HATCHET_DEFAULT_STACK=heroku-24 bundle exec rspec spec/hatchet/pip_spec.rb
```

Tests that only apply to certain stacks declare this using `stacks:` metadata, and are skipped
on the others.

If the tests are interrupted, apps may be left behind. Delete them using:

```
bundle exec hatchet destroy --older-than 10
```

### Running the integration tests in CI

CI runs the linting checks, the container (`make run`) tests, and the integration tests for every
supported stack on each pull request and on pushes to `main`.

To run the full CI workflow against a branch without opening a pull request:

```
gh workflow run ci.yml --ref <branch>
```

## Changelog

Add an entry under `[Unreleased]` in `CHANGELOG.md` for any user-facing change, using a single
sentence in the style of the existing entries. For changes that don't affect users (such as tests
or CI), add the `skip changelog` label to the pull request instead.
