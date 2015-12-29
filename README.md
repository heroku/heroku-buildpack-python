# Cloud Foundry Python Buildpack
[![CF Slack](https://s3.amazonaws.com/buildpacks-assets/buildpacks-slack.svg)](http://slack.cloudfoundry.org)

A Cloud Foundry [buildpack](http://docs.cloudfoundry.org/buildpacks/) for Python based apps.

This is based on the [Heroku buildpack] (https://github.com/heroku/heroku-buildpack-python).

This buildpack supports running Django and Flask apps.


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

For the Python buildpack, use ```pip```:

```shell 
cd <your app dir>
mkdir -p vendor

# vendors all the pip *.tar.gz into vendor/
pip install --download vendor -r requirements.txt
```

```cf push``` uploads your vendored dependencies. The buildpack will install them directly from the `vendor/`.

## Building

1. Make sure you have fetched submodules

  ```bash
  git submodule update --init
  ```

1. Get latest buildpack dependencies

  ```shell
  BUNDLE_GEMFILE=cf.Gemfile bundle
  ```

1. Build the buildpack

  ```shell
  BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager [ --uncached | --cached ]
  ```

1. Use in Cloud Foundry

    Upload the buildpack to your Cloud Foundry and optionally specify it by name
        
    ```bash
    cf create-buildpack custom_python_buildpack python_buildpack-cached-custom.zip 1
    cf push my_app -b custom_python_buildpack
    ```  

# Supported binary dependencies

The buildpack only supports the stable patches for each dependency listed in the [manifest.yml](manifest.yml) and [releases page](https://github.com/cloudfoundry/python-buildpack/releases).

If you try to use a binary that is not currently supported, staging your app will fail and you will see the following error message:

```
       Could not get translated url, exited with: DEPENDENCY_MISSING_IN_MANIFEST: ...
 !
 !     exit
 !
Staging failed: Buildpack compilation step failed
```

## Testing
Buildpacks use the [Machete](https://github.com/cloudfoundry/machete) framework for running integration tests.

To test a buildpack, run the following command from the buildpack's directory:

```
BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-build
```

More options can be found on Machete's [Github page.](https://github.com/cloudfoundry/machete)



## Contributing

Find our guidelines [here](./CONTRIBUTING.md).

## Help and Support

Join the #buildpacks channel in our [Slack community] (http://slack.cloudfoundry.org/) 

## Reporting Issues

Open a GitHub issue on this project [here](https://github.com/cloudfoundry/python-buildpack/issues/new)

## Active Development

The project backlog is on [Pivotal Tracker](https://www.pivotaltracker.com/projects/1042066)
