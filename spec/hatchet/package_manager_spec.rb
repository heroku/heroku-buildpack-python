# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Package manager support' do
  context 'when there are no supported package manager files' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pyproject_toml_only', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Couldn't find any supported Python package manager files.
          remote:  !     
          remote:  !     A Python app on Heroku must have either a 'requirements.txt',
          remote:  !     'Pipfile', 'poetry.lock' or 'uv.lock' package manager file in
          remote:  !     the root directory of its source code.
          remote:  !     
          remote:  !     Currently the root directory of your app contains:
          remote:  !     
          remote:  !     .example-dotfile
          remote:  !     pyproject.toml
          remote:  !     subdir/
          remote:  !     
          remote:  !     If your app already has a package manager file, check that it:
          remote:  !     
          remote:  !     1. Is in the top level directory (not a subdirectory).
          remote:  !     2. Has the correct spelling (the filenames are case-sensitive).
          remote:  !     3. Isn't listed in '.gitignore' or '.slugignore'.
          remote:  !     4. Has been added to the Git repository using 'git add --all'
          remote:  !        and then committed using 'git commit'.
          remote:  !     
          remote:  !     Otherwise, add a package manager file to your app. If your app has
          remote:  !     no dependencies, then create an empty 'requirements.txt' file.
          remote:  !     
          remote:  !     If you aren't sure which package manager to use, we recommend
          remote:  !     trying uv, since it supports lockfiles, is extremely fast, and
          remote:  !     is actively maintained by a full-time team:
          remote:  !     https://docs.astral.sh/uv/
          remote:  !     
          remote:  !     For help with using Python on Heroku, see:
          remote:  !     https://devcenter.heroku.com/articles/getting-started-with-python
          remote:  !     https://devcenter.heroku.com/articles/python-support
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # TODO: Deprecate/sunset the setup.py file fallback.
  context 'when there is only a setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/setup_py_only') }

    it 'installs packages from setup.py using pip' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install --editable .'
          remote:        Obtaining file:///tmp/build_.*
          remote:        .+
          remote:        Installing collected packages: six, test
          remote:        Successfully installed six-.+ test-0.0.0
        REGEX
      end
    end
  end

  # This case will be turned into an error in the future.
  context 'when there are multiple package manager files' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/multiple_package_managers') }

    it 'outputs a warning and builds with the first listed' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: 
          remote:  !     Warning: Multiple Python package manager files were found.
          remote:  !     
          remote:  !     Exactly one package manager file should be present in your app's
          remote:  !     source code, however, several were found:
          remote:  !     
          remote:  !     Pipfile.lock \\(Pipenv\\)
          remote:  !     requirements.txt \\(pip\\)
          remote:  !     poetry.lock \\(Poetry\\)
          remote:  !     uv.lock \\(uv\\)
          remote:  !     
          remote:  !     For now, we will build your app using the first package manager
          remote:  !     listed above, however, in the future this warning will become
          remote:  !     an error.
          remote:  !     
          remote:  !     Decide which package manager you want to use with your app, and
          remote:  !     then delete the file\\(s\\) and any config from the others.
          remote:  !     
          remote:  !     If you aren't sure which package manager to use, we recommend
          remote:  !     trying uv, since it supports lockfiles, is extremely fast, and
          remote:  !     is actively maintained by a full-time team:
          remote:  !     https://docs.astral.sh/uv/
          remote: 
          remote: 
          remote:  !     Note: We recently added support for the package manager Poetry.
          remote:  !     If you are using a third-party Poetry buildpack you must remove
          remote:  !     it, otherwise the requirements.txt file it generates will cause
          remote:  !     the warning above.
          remote: 
          remote: 
          remote:  !     Note: We recently added support for the package manager uv.
          remote:  !     If you are using a third-party uv buildpack you must remove
          remote:  !     it, otherwise the requirements.txt file it generates will cause
          remote:  !     the warning above.
          remote: 
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing Pipenv #{PIPENV_VERSION}
          remote: -----> Installing dependencies using 'pipenv install --deploy'
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        REGEX
      end
    end
  end

  context 'when the package manager has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_basic') }

    it 'clears the cache before installing with the new package manager' do
      app.deploy do |app|
        FileUtils.rm('requirements.txt')
        FileUtils.cp(FIXTURE_DIR.join('uv_basic/pyproject.toml'), '.')
        FileUtils.cp(FIXTURE_DIR.join('uv_basic/uv.lock'), '.')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The package manager has changed from pip to uv
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 7 packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.13.2
          remote: -----> Discovering process types
        REGEX
      end
    end
  end
end
