# These targets are not files
.PHONY: lint lint-scripts lint-ruby run publish

STACK ?= heroku-24
FIXTURE ?= spec/fixtures/python_version_unspecified

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts lint-ruby

lint-scripts:
	@git ls-files -z --cached --others --exclude-standard 'bin/*' '*/bin/*' '*.sh' | xargs -0 shellcheck --check-sourced --color=always

lint-ruby:
	@bundle exec rubocop

run:
	@echo "Running buildpack using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@docker run --rm -it -v $(PWD):/src:ro --tmpfs /app -e "HOME=/app" -e "STACK=$(STACK)" "$(STACK_IMAGE_TAG)" \
		bash -eo pipefail -c '\
			mkdir /tmp/buildpack /tmp/build /tmp/cache /tmp/env \
			&& cp -r /src/{bin,lib,requirements,vendor} /tmp/buildpack \
			&& cp -rT /src/$(FIXTURE) /tmp/build \
			&& cd /tmp/buildpack \
			&& echo -e "\n~ Detect:" && bash ./bin/detect /tmp/build /tmp/cache /tmp/env \
			&& echo -e "\n~ Compile:" && { ./bin/compile /tmp/build /tmp/cache /tmp/env || true; } \
			&& echo -e "\n~ Report:" && ./bin/report /tmp/build /tmp/cache /tmp/env \
		'
	@echo

publish:
	@etc/publish.sh
