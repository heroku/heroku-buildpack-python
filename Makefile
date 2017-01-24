# These targets are not files
.PHONY: tests

test: test-cedar-14

test-cedar-14:
	@echo "Running tests in docker (cedar-14)..."
	@docker run -v $(shell pwd):/buildpack:ro --rm -it -e "STACK=cedar-14" heroku/cedar:14 bash -c 'cp -r /buildpack /buildpack_test; cd /buildpack_test/; test/run;'
	@echo ""

tools:
	git clone https://github.com/kennethreitz/pip-pop.git
	mv pip-pop/bin/* vendor/pip-pop/
	rm -fr pip-pop