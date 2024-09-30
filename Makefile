# These targets are not files
.PHONY: lint lint-scripts lint-ruby check-format format run publish

STACK ?= heroku-24
FIXTURE ?= spec/fixtures/python_version_unspecified

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts check-format lint-ruby

lint-scripts:
	@git ls-files -z --cached --others --exclude-standard 'bin/*' '*/bin/*' '*.sh' | xargs -0 shellcheck --check-sourced --color=always

lint-ruby:
	@bundle exec rubocop

check-format:
	@shfmt --diff .

format:
	@shfmt --write --list .

run:
	@echo "Running buildpack using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@docker run --rm -v $(PWD):/src:ro --tmpfs /app -e "HOME=/app" -e "STACK=$(STACK)" "$(STACK_IMAGE_TAG)" \
		bash -euo pipefail -c '\
			mkdir /tmp/buildpack /tmp/build /tmp/cache /tmp/env; \
			cp -r /src/{bin,lib,requirements,vendor} /tmp/buildpack; \
			cp -rT /src/$(FIXTURE) /tmp/build; \
			cd /tmp/buildpack; \
			unset $$(printenv | cut -d '=' -f 1 | grep -vE "^(HOME|LANG|PATH|STACK)$$"); \
			echo -e "\n~ Detect:" && ./bin/detect /tmp/build; \
			echo -e "\n~ Compile:" && { ./bin/compile /tmp/build /tmp/cache /tmp/env || COMPILE_FAILED=1; }; \
			echo -e "\n~ Report:" && ./bin/report /tmp/build /tmp/cache /tmp/env; \
			[[ "$${COMPILE_FAILED:-}" == "1" ]] && exit 0; \
			[[ -f /tmp/build/bin/compile ]] && { echo -e "\n~ Compile (Inline Buildpack):" && (source ./export && /tmp/build/bin/compile /tmp/build /tmp/cache /tmp/env); }; \
			echo -e "\n~ Release:" && ./bin/release /tmp/build; \
			echo -e "\nBuild successful!"; \
		'
	@echo

publish:
	@etc/publish.sh
