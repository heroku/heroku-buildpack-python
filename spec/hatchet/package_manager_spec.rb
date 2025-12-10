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
          remote:  !     'Pipfile.lock', 'poetry.lock' or 'uv.lock' package manager file
          remote:  !     in the root directory of its source code.
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

  context 'when there is only a setup.py' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/setup_py_only', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Implicit setup.py file support has been sunset.
          remote:  !     
          remote:  !     Your app currently only has a setup.py file and no Python
          remote:  !     package manager files. This means that the buildpack can't
          remote:  !     tell which package manager you want to use, and whether to
          remote:  !     install your project in editable mode or not.
          remote:  !     
          remote:  !     Previously the buildpack guessed and used pip to install your
          remote:  !     dependencies in editable mode. However, this fallback was
          remote:  !     deprecated in September 2025 and has now been sunset.
          remote:  !     
          remote:  !     You must now add an explicit package manager file to your app,
          remote:  !     such as a requirements.txt, poetry.lock or uv.lock file.
          remote:  !     
          remote:  !     To continue using your setup.py file with pip in editable
          remote:  !     mode, create a new file in the root directory of your app
          remote:  !     named 'requirements.txt' containing the requirement
          remote:  !     '--editable .' (without quotes).
          remote:  !     
          remote:  !     Alternatively, if you wish to switch to another package
          remote:  !     manager, we recommend uv, since it supports lockfiles, is
          remote:  !     faster, and is actively maintained by a full-time team:
          remote:  !     https://docs.astral.sh/uv/
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when there are multiple package manager files' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/multiple_package_managers', allow_failure: true) }

    it 'fails the build with an informative error message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Multiple Python package manager files were found.
          remote:  !     
          remote:  !     Exactly one package manager file should be present in your app's
          remote:  !     source code, however, several were found:
          remote:  !     
          remote:  !     Pipfile.lock (Pipenv)
          remote:  !     requirements.txt (pip)
          remote:  !     poetry.lock (Poetry)
          remote:  !     uv.lock (uv)
          remote:  !     
          remote:  !     Previously, the buildpack guessed which package manager to use
          remote:  !     and installed your dependencies with the first package manager
          remote:  !     listed above. However, this implicit behaviour was deprecated
          remote:  !     in November 2024 and is now no longer supported.
          remote:  !     
          remote:  !     You must decide which package manager you want to use with your
          remote:  !     app, and then delete the file(s) and any config from the others.
          remote:  !     
          remote:  !     If you aren't sure which package manager to use, we recommend
          remote:  !     trying uv, since it supports lockfiles, is extremely fast, and
          remote:  !     is actively maintained by a full-time team:
          remote:  !     https://docs.astral.sh/uv/
          remote:  !     
          remote:  !     Note: If you use a third-party uv or Poetry buildpack, you must
          remote:  !     remove it from your app, since it's no longer required and the
          remote:  !     requirements.txt file it generates will trigger this error. See:
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#remove-classic-buildpacks
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when the package manager has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pip_basic') }

    it 'clears the cache before installing with the new package manager' do
      app.deploy do |app|
        FileUtils.rm('bin/post_compile')
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
          remote:        Resolved .+ packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.15.0
          remote: -----> Saving cache
          remote: -----> Discovering process types
        REGEX
      end
    end
  end
end
