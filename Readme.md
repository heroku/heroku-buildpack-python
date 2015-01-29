# Cloud Foundry buildpack: Python

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for Python based apps.

This is based on the [Heroku buildpack] (https://github.com/heroku/heroku-buildpack-python).

Additional information can be found at [CloudFoundry.org](http://docs.cloudfoundry.org/buildpacks/).

## Usage

This buildpack will be used if there is a `requirements.txt` or `setup.py` file in the root directory of your project.

```bash
cf push my_app -b https://github.com/cloudfoundry/buildpack-python.git
```

## Disconnected environments
To use this buildpack on Cloud Foundry, where the Cloud Foundry instance limits some or all internet activity, please read the [Disconnected Environments documentation](https://github.com/cf-buildpacks/buildpack-packager/blob/master/doc/disconnected_environments.md).

### Vendoring app dependencies
As stated in the [Disconnected Environments documentation](https://github.com/cf-buildpacks/buildpack-packager/blob/master/doc/disconnected_environments.md), your application must 'vendor' it's dependencies.

For the Ruby buildpack, use ```pip```:

```shell 
cd <your app dir>
pip install # vendors into /vendor
```

```cf push``` uploads your vendored dependencies.

## Contributing

### Run the tests

See the [Machete](https://github.com/cf-buildpacks/machete) CF buildpack test framework for more information.


### Pull Requests

1. Fork the project
1. Submit a pull request

## Reporting Issues

Open an issue on this project

## Active Development

The project backlog is on [Pivotal Tracker](https://www.pivotaltracker.com/projects/1042066)
