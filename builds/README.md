# Python Buildpack Binaries

The binaries for this buildpack are built on GitHub Actions, inside Docker containers based on the Heroku stack image.

Users with suitable repository access can trigger builds by:

1. Navigating to the [Build and upload Python runtime](https://github.com/heroku/heroku-buildpack-python/actions/workflows/build_python_runtime.yml) workflow.
2. Opening the "Run workflow" prompt.
3. Entering the desired Python version.
4. Optionally checking the "Skip deploying" checkbox (if testing)
5. Clicking "Run workflow".
