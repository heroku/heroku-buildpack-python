# Contributing

## Contributing Guidelines

All pull request authors must have a Contributor License Agreement (CLA) on-file with us. Please sign the appropriate CLA ([individual](http://cloudfoundry.org/pdfs/CFF_Individual_CLA.pdf) or [corporate](http://cloudfoundry.org/pdfs/CFF_Corporate_CLA.pdf)).

When sending signed CLA please provide your github username in case of individual CLA or the list of github usernames that can make pull requests on behalf of your organization.

If you are confident that you're covered under a Corporate CLA, please make sure you've publicized your membership in the appropriate Github Org, per these instructions.

## Run the tests

See the [Machete](https://github.com/cf-buildpacks/machete) CF buildpack test framework for more information.

## Pull Requests

1. Fork the project
1. Submit a pull request

Please include tests with the pull request. Include a fixture app with integration test and/or unit tests based on which best covers the new functionality. Fixtures, integration tests and unit tests can all be found in the `cf-spec/` directory

**NOTE:** When submitting a pull request, *please make sure to target the `develop` branch*, so that your changes are up-to-date and easy to integrate with the most recent work on the buildpack. Thanks!
