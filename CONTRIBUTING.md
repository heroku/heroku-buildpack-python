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

Please include integration tests (in `cf_spec/integration`) and corresponding fixtures (in `cf_spec/fixtures`) where necessary to cover any functionality that is introduced.

**NOTE:** When submitting a pull request, *please make sure to target the `develop` branch*, so that your changes are up-to-date and easy to integrate with the most recent work on the buildpack. Thanks!
