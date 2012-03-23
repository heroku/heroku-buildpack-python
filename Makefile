docs:
	shocco -t 'Python Buildpack Compiler' ./bin/compile | browser

pip:
	git clone git@github.com:kennethreitz/pip.git --branch heroku --depth 1
	rm -fr vendor/virtualenv-1.7/virtualenv_support/pip-1.0.2.tar.gz
	rm -fr pip/.git
	tar -pczf vendor/virtualenv-1.7/virtualenv_support/pip-1.0.2.tar.gz pip
	rm -fr pip

