# These targets are not files
.PHONY: lint lint-scripts lint-ruby compile builder-image buildenv deploy-runtimes publish

STACK ?= heroku-20
STACKS ?= heroku-18 heroku-20
FIXTURE ?= spec/fixtures/python_version_unspecified
ENV_FILE ?= builds/dockerenv.default
BUILDER_IMAGE_PREFIX := heroku-python-build

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts lint-ruby

lint-scripts:
	@shellcheck -x bin/compile bin/detect bin/release bin/test-compile bin/utils bin/warnings bin/default_pythons
	@shellcheck -x bin/steps/collectstatic bin/steps/nltk bin/steps/pip-install bin/steps/pipenv bin/steps/pipenv-python-version bin/steps/python
	@shellcheck -x bin/steps/hooks/*

lint-ruby:
	@bundle exec rubocop

compile:
	@echo "Running compile using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@echo
	@docker run --rm -it -v $(PWD):/src:ro -e "STACK=$(STACK)" -w /buildpack "$(STACK_IMAGE_TAG)" \
		bash -c 'cp -r /src/{bin,vendor} /buildpack && cp -r /src/$(FIXTURE) /build && mkdir /cache /env && bin/compile /build /cache /env'
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

publish:
	@etc/publish.sh
