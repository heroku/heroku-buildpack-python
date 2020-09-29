# These targets are not files
.PHONY: check test builder-image buildenv deploy-runtimes tools

STACK ?= heroku-18
STACKS ?= cedar-14 heroku-16 heroku-18
TEST_CMD ?= test/run-versions && test/run-features && test/run-deps
ENV_FILE ?= builds/dockerenv.default
BUILDER_IMAGE_PREFIX := heroku-python-build

ifeq ($(STACK),cedar-14)
	# Cedar-14 doesn't have a build image varient.
	STACK_IMAGE_TAG := heroku/cedar:14
else
	# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
	STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build
endif

check:
	@shellcheck -x bin/compile bin/detect bin/release bin/test-compile bin/utils bin/warnings bin/default_pythons
	@shellcheck -x bin/steps/collectstatic bin/steps/eggpath-fix  bin/steps/eggpath-fix2 bin/steps/gdal bin/steps/geo-libs bin/steps/mercurial bin/steps/nltk bin/steps/pip-install bin/steps/pip-uninstall bin/steps/pipenv bin/steps/pipenv-python-version bin/steps/pylibmc bin/steps/python
	@shellcheck -x bin/steps/hooks/*

test:
	@echo "Running tests using: STACK=$(STACK) TEST_CMD='$(TEST_CMD)'"
	@echo
	@docker run --rm -it -v $(PWD):/buildpack:ro -e "STACK=$(STACK)" "$(STACK_IMAGE_TAG)" bash -c 'cp -r /buildpack /buildpack_test && cd /buildpack_test && $(TEST_CMD)'
	@echo

builder-image:
	@echo "Generating binary builder image for $(STACK)..."
	@echo
	@docker build --pull -f builds/$(STACK).Dockerfile -t "$(BUILDER_IMAGE_PREFIX)-$(STACK)" .
	@echo

buildenv: builder-image
	@echo "Starting build environment for $(STACK)..."
	@echo
	@echo "Usage..."
	@echo
	@echo "  $$ bob build runtimes/python-X.Y.Z"
	@echo
	@docker run --rm -it --env-file="$(ENV_FILE)" -v $(PWD)/builds:/app/builds "$(BUILDER_IMAGE_PREFIX)-$(STACK)" bash

deploy-runtimes:
ifndef RUNTIMES
	$(error No runtimes specified! Use: "make deploy-runtimes RUNTIMES='python-X.Y.Z ...' [STACKS='heroku-18 ...'] [ENV_FILE=...]")
endif
	@echo "Using: RUNTIMES='$(RUNTIMES)' STACKS='$(STACKS)' ENV_FILE='$(ENV_FILE)'"
	@echo
	@set -eu; for stack in $(STACKS); do \
		$(MAKE) builder-image STACK=$${stack}; \
		for runtime in $(RUNTIMES); do \
			echo "Generating/deploying $${runtime} for $${stack}..."; \
			echo; \
			docker run --rm -it --env-file="$(ENV_FILE)" "$(BUILDER_IMAGE_PREFIX)-$${stack}" bob deploy "runtimes/$${runtime}"; \
			echo; \
		done; \
	done

tools:
	git clone https://github.com/kennethreitz/pip-pop.git
	mv pip-pop/bin/* vendor/pip-pop/
	rm -rf pip-pop
