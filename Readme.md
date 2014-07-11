# Heroku buildpack: Python

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for Ruby based apps.

This is based on the [Heroku buildpack] (https://github.com/heroku/heroku-buildpack-python).

## Usage

This buildpack will be used if there is a `requirements.txt` or `setup.py` file in the root directory of your project.

```bash
cf push my_app -b https://github.com/cloudfoundry/buildpack-python.git
```

## Cloud Foundry Extensions - Offline Mode

The primary purpose of extending the heroku buildpack is to cache system dependencies for firewalled or other non-internet accessible environments. This is called 'offline' mode.

'offline' buildpacks can be used in any environment where you would prefer the dependencies to be cached instead of fetched from the internet.

The list of what is cached is maintained in [bin/package](bin/package).

Using cached system dependencies is accomplished by overriding curl during staging. See [bin/compile](bin/compile#L71-75)

### App Dependencies in Offline Mode
Offline mode expects each app to use pip to manage dependencies. Use `pip install` to vendor your dependencies into `/vendor`.

## Building

1. Make sure you have fetched submodules

  ```bash
  git submodule update --init
  ```

1. Build the buildpack

  ```bash
  bin/package [ online | offline ]
  ```

1. Use in Cloud Foundry

    Upload the buildpack to your Cloud Foundry and optionally specify it by name

    ```bash
    cf create-buildpack custom_python_buildpack python_buildpack-offline-custom.zip 1
    cf push my_app -b custom_python_buildpack
    ```

## Contributing

### Run the tests

There are [Machete](https://github.com/pivotal-cf-experimental/machete) based integration tests available in [cf_spec](cf_spec).

The test script is included in machete and can be run as follows:

```bash
BUNDLE_GEMFILE=cf.Gemfile bundle install
git submodule update --init
`BUNDLE_GEMFILE=cf.Gemfile bundle show machete`/scripts/buildpack-build [mode]
```

`buildpack-build` will create a buildpack in one of two modes and upload it to your local bosh-lite based Cloud Foundry installations.

Valid modes:

online : Dependencies can be fetched from the internet.

offline : System dependencies, such as python, are installed from a cache included in the buildpack.

The tests expect two Cloud Foundry installations to be present, an online one at 10.244.0.34 and an offline one at 10.245.0.34.

We use [bosh-lite](https://github.com/cloudfoundry/bosh-lite) for the online instance and [bosh-lite-2nd-instance](https://github.com/cf-buildpacks/bosh-lite-2nd-instance) for the offline instance.

### Pull Requests

1. Fork the project
1. Submit a pull request

## Reporting Issues

Open an issue on this project

## Active Development

The project backlog is on [Pivotal Tracker](https://www.pivotaltracker.com/projects/1042066)
