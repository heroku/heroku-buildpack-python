Cloud Foundry Python Buildpack
==============================

This is a fork of https://github.com/heroku/heroku-buildpack-python designed to support Cloud Foundry
on premises installations.

This buildpack allows the Python Buildpack to work with Cloud Foundry. The upstream is dependent on
Logplex, which is not available on other PaaS.

Notes to developers
===================

* In offline mode, this buildpack will fail with non-Git vcs dependencies in requirements.txt
