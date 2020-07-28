# These targets are not files
.PHONY: check test buildenv-heroku-16 buildenv-heroku-18 tools

STACK ?= heroku-18
TEST_CMD ?= test/run-versions && test/run-features && test/run-deps

ifeq ($(STACK),cedar-14)
	# Cedar-14 doesn't have a build image varient.
	IMAGE_TAG := heroku/cedar:14
else
	# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
	IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build
endif

check:
	@shellcheck -x bin/compile bin/detect bin/release bin/test-compile bin/utils bin/warnings bin/default_pythons
	@shellcheck -x bin/steps/collectstatic bin/steps/eggpath-fix  bin/steps/eggpath-fix2 bin/steps/gdal bin/steps/geo-libs bin/steps/mercurial bin/steps/nltk bin/steps/pip-install bin/steps/pip-uninstall bin/steps/pipenv bin/steps/pipenv-python-version bin/steps/pylibmc bin/steps/python
	@shellcheck -x bin/steps/hooks/*

test:
	@echo "Running tests using: STACK=$(STACK) TEST_CMD='$(TEST_CMD)'"
	@echo ""
	@docker run --rm -it -v $(PWD):/buildpack:ro -e "STACK=$(STACK)" "$(IMAGE_TAG)" bash -c 'cp -r /buildpack /buildpack_test && cd /buildpack_test && $(TEST_CMD)'
	@echo ""

buildenv-heroku-16:
	@echo "Creating build environment (heroku-16)..."
	@echo
	@docker build --pull -f $(shell pwd)/builds/heroku-16.Dockerfile -t python-buildenv-heroku-16 .
	@echo
	@echo "Usage..."
	@echo
	@echo "  $$ export AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar  # Optional unless deploying"
	@echo "  $$ bob build runtimes/python-2.7.13"
	@echo "  $$ bob deploy runtimes/python-2.7.13"
	@echo
	@docker run -it --rm python-buildenv-heroku-16

buildenv-heroku-18:
	@echo "Creating build environment (heroku-18)..."
	@echo
	@docker build --pull -f $(shell pwd)/builds/heroku-18.Dockerfile -t python-buildenv-heroku-18 .
	@echo
	@echo "Usage..."
	@echo
	@echo "  $$ export AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar  # Optional unless deploying"
	@echo "  $$ bob build runtimes/python-2.7.13"
	@echo "  $$ bob deploy runtimes/python-2.7.13"
	@echo
	@docker run -it --rm python-buildenv-heroku-18

tools:
	git clone https://github.com/kennethreitz/pip-pop.git
	mv pip-pop/bin/* vendor/pip-pop/
	rm -fr pip-pop
