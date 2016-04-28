# These targets are not files
.PHONY: tests

tests:
	./bin/test

tools:
	git clone https://github.com/kennethreitz/pip-pop.git
	mv pip-pop/bin/* vendor/pip-pop/
	rm -fr pip-pop