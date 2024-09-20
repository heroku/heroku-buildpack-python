# This file is here to confirm we don't try and create the fallback requirements
# file containing '-e .' when using Pipenv.

from setuptools import setup

setup(
  name='test',
  install_requires=['six'],
)
