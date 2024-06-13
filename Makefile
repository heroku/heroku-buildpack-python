# These targets are not files
.PHONY: lint lint-scripts lint-ruby compile publish

STACK ?= heroku-24
FIXTURE ?= spec/fixtures/python_version_unspecified

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts lint-ruby

lint-scripts:
	@git ls-files -z --cached --others --exclude-standard 'bin/*' '*/bin/*' '*.sh' | xargs -0 shellcheck --check-sourced --color=always

lint-ruby:
	@bundle exec rubocop

compile:
	@echo "Running compile using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@echo
	@docker run --rm -it --user root -v $(PWD):/src:ro -e "STACK=$(STACK)" -w /buildpack "$(STACK_IMAGE_TAG)" \
		bash -c 'cp -r /src/{bin,requirements,vendor} /buildpack && cp -r /src/$(FIXTURE) /build && mkdir /cache /env && bin/compile /build /cache /env'
	@echo

publish:
	@etc/publish.sh
