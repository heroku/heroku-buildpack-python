# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'uv support' do
  context 'with a uv.lock' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_basic', buildpacks:) }

    it 'installs successfully using uv and on rebuilds uses the cache' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved .+ packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.15.0
          remote: -----> Running bin/post_compile hook
          remote:        BUILD_DIR=/tmp/build_.+
          remote:        CACHE_DIR=/tmp/codon/tmp/cache
          remote:        C_INCLUDE_PATH=/app/.heroku/python/include
          remote:        CPLUS_INCLUDE_PATH=/app/.heroku/python/include
          remote:        ENV_DIR=/tmp/.+
          remote:        LANG=en_US.UTF-8
          remote:        LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote:        LIBRARY_PATH=/app/.heroku/python/lib
          remote:        PATH=/tmp/codon/tmp/cache/.heroku/python-uv:/app/.heroku/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote:        PKG_CONFIG_PATH=/app/.heroku/python/lib/pkg-config
          remote:        PYTHONUNBUFFERED=1
          remote:        UV_CACHE_DIR=/tmp/uv-cache
          remote:        UV_LINK_MODE=hardlink
          remote:        UV_NO_MANAGED_PYTHON=1
          remote:        UV_PROJECT_ENVIRONMENT=/app/.heroku/python
          remote:        UV_PYTHON_DOWNLOADS=never
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: LANG=en_US.UTF-8
          remote: LD_LIBRARY_PATH=/app/.heroku/python/lib
          remote: LIBRARY_PATH=/app/.heroku/python/lib
          remote: PATH=/app/.heroku/python/bin:/tmp/codon/tmp/cache/.heroku/python-uv:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          remote: PYTHONHOME=/app/.heroku/python
          remote: PYTHONPATH=/app
          remote: PYTHONUNBUFFERED=true
          remote: UV_CACHE_DIR=/tmp/uv-cache
          remote: UV_LINK_MODE=hardlink
          remote: UV_NO_MANAGED_PYTHON=1
          remote: UV_PROJECT_ENVIRONMENT=/app/.heroku/python
          remote: UV_PYTHON_DOWNLOADS=never
          remote: 
          remote: \\['',
          remote:  '/app',
          remote:  '/app/.heroku/python/lib/python314.zip',
          remote:  '/app/.heroku/python/lib/python3.14',
          remote:  '/app/.heroku/python/lib/python3.14/lib-dynload',
          remote:  '/app/.heroku/python/lib/python3.14/site-packages'\\]
          remote: 
          remote: uv #{UV_VERSION} \\(x86_64-unknown-linux-gnu\\)
          remote: Using Python #{DEFAULT_PYTHON_FULL_VERSION} environment at: /app/.heroku/python
          remote: Package           Version
          remote: ----------------- -------
          remote: typing-extensions 4.15.0
          remote: 
          remote: <module 'typing_extensions' from '/app/.heroku/python/lib/python3.14/site-packages/typing_extensions.py'>
          remote: 
          remote: \\{
          remote:   "cache_restore_duration": [0-9.]+,
          remote:   "cache_save_duration": [0-9.]+,
          remote:   "cache_status": "empty",
          remote:   "dependencies_install_duration": [0-9.]+,
          remote:   "django_collectstatic_duration": [0-9.]+,
          remote:   "nltk_downloader_duration": [0-9.]+,
          remote:   "package_manager": "uv",
          remote:   "package_manager_install_duration": [0-9.]+,
          remote:   "post_compile_hook": true,
          remote:   "post_compile_hook_duration": [0-9.]+,
          remote:   "pre_compile_hook": false,
          remote:   "python_install_duration": [0-9.]+,
          remote:   "python_version": "#{DEFAULT_PYTHON_FULL_VERSION}",
          remote:   "python_version_major": "3.14",
          remote:   "python_version_origin": ".python-version",
          remote:   "python_version_outdated": false,
          remote:   "python_version_pinned": false,
          remote:   "python_version_requested": "3.14",
          remote:   "total_duration": [0-9.]+,
          remote:   "uv_version": "#{UV_VERSION}"
          remote: \\}
        REGEX

        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> Using Python #{DEFAULT_PYTHON_MAJOR_VERSION} specified in .python-version
          remote: -----> Restoring cache
          remote: -----> Using cached install of Python #{DEFAULT_PYTHON_FULL_VERSION}
          remote: -----> Using cached uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved .+ packages in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote: -----> Running bin/post_compile hook
          remote:        .+
          remote: -----> Saving cache
          remote: -----> Inline app detected
        REGEX

        command = 'bin/print-env-vars.sh && if command -v uv; then echo "uv unexpectedly found!" && exit 1; fi'
        expect(normalize_trailing_newlines(app.run(command))).to eq(<<~OUTPUT)
          DYNO_RAM=512
          FORWARDED_ALLOW_IPS=*
          GUNICORN_CMD_ARGS=--access-logfile -
          LANG=en_US.UTF-8
          LD_LIBRARY_PATH=/app/.heroku/python/lib
          LIBRARY_PATH=/app/.heroku/python/lib
          PATH=/app/.heroku/python/bin:/usr/local/bin:/usr/bin:/bin
          PYTHONHOME=/app/.heroku/python
          PYTHONPATH=/app
          PYTHONUNBUFFERED=true
          WEB_CONCURRENCY=2
          WEB_CONCURRENCY_SET_BY=heroku/python
        OUTPUT
        expect($CHILD_STATUS.exitstatus).to eq(0)
      end
    end
  end

  # TODO: Enable on Heroku-26 after the uv and default Python versions next change,
  # since for now there isn't a historic buildpack version we can use in this test
  # whose stack check permits Heroku-26 and that also uses older uv/Python versions.
  context 'when the uv and Python versions have changed since the last build', stacks: %w[heroku-22 heroku-24] do
    let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v313'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_basic', buildpacks:) }

    it 'clears the cache before installing' do
      app.deploy do |app|
        update_buildpacks(app, [:default])
        FileUtils.rm('bin/post_compile')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.14 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The Python version has changed from 3.14.0 to #{LATEST_PYTHON_3_14}
          remote:        - The uv version has changed from 0.8.23 to #{UV_VERSION}
          remote: -----> Installing Python #{LATEST_PYTHON_3_14}
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

  # This tests that:
  #  - The current project's editable install paths are rewritten correctly for hooks, later buildpacks,
  #    runtime and cached builds.
  #  - Git from the stack image can be found (ie: the system PATH has been correctly propagated to uv).
  #  - Building/compiling a source distribution package (as opposed to a pre-built wheel) works.
  #  - The Python headers can be found when compiling.
  #
  # We can't install the VCS dependency in editable mode (like the Git tests for other package managers),
  # since uv doesn't support editable mode with VCS dependencies:
  # https://github.com/astral-sh/uv/issues/5442
  context 'with an editable current project and a compiled (non-editable) VCS package' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_editable_git_compiled', buildpacks:) }

    it 'installs and rewrites editable paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+s
          remote:           .+
          remote:        Prepared 2 packages in .+s
          remote:        Installed 2 packages in .+s
          remote:        Bytecode compiled .+ files in .+s
          remote:         \\+ extension-dist==0.1 \\(from git\\+https://github.com/pypa/wheel.git@7855525de4093257e7bfb434877265e227356566#subdirectory=tests/testdata/extension.dist\\)
          remote:         \\+ uv-editable-git-compiled==0.0.0 \\(from file:///tmp/build_.+\\)
          remote: -----> Running bin/post_compile hook
          remote:        uv_editable_git_compiled.pth:/tmp/build_.+/src
          remote:        
          remote:        Running project entrypoint: OK
          remote:        Running import of VCS package: OK
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: uv_editable_git_compiled.pth:/tmp/build_.+/src
          remote: 
          remote: Running project entrypoint: OK
          remote: Running import of VCS package: OK
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-editable-installs.sh')).to include(<<~OUTPUT)
          uv_editable_git_compiled.pth:/app/src

          Running project entrypoint: OK
          Running import of VCS package: OK
        OUTPUT

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+
          remote:           .+
          remote:        Prepared 1 package in .+s
          remote:        Uninstalled 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled .+ files in .+s
          remote:         - uv-editable-git-compiled==0.0.0 \\(from file:///tmp/build_.+\\)
          remote:         \\+ uv-editable-git-compiled==0.0.0 \\(from file:///tmp/build_.+\\)
          remote: -----> Running bin/post_compile hook
          remote:        uv_editable_git_compiled.pth:/tmp/build_.+/src
          remote:        
          remote:        Running project entrypoint: OK
          remote:        Running import of VCS package: OK
          remote: -----> Saving cache
          remote: -----> Inline app detected
          remote: uv_editable_git_compiled.pth:/tmp/build_.+/src
          remote: 
          remote: Running project entrypoint: OK
          remote: Running import of VCS package: OK
        REGEX
      end
    end
  end

  context 'when using our oldest supported Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_oldest_python') }

    it 'installs successfully' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.10.0 specified in .python-version
          remote: 
          remote:  !     Warning: Support for Python 3.10 is deprecated!
          remote:  !     
          remote:  !     Python 3.10 will reach its upstream end-of-life in October 2026,
          remote:  !     at which point it will no longer receive security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, support for Python 3.10 will be removed from this
          remote:  !     buildpack on 6th January 2027.
          remote:  !     
          remote:  !     Upgrade to a newer Python version as soon as possible, by
          remote:  !     changing the version in your .python-version file.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote: 
          remote: 
          remote:  !     Warning: A Python patch update is available!
          remote:  !     
          remote:  !     Your app is using Python 3.10.0, however, there is a newer
          remote:  !     patch release of Python 3.10 available: #{LATEST_PYTHON_3_10}
          remote:  !     
          remote:  !     It is important to always use the latest patch version of
          remote:  !     Python to keep your app secure.
          remote:  !     
          remote:  !     Update your .python-version file to use the new version.
          remote:  !     
          remote:  !     We strongly recommend that you don't pin your app to an
          remote:  !     exact Python version such as 3.10.0, and instead only specify
          remote:  !     the major Python version of 3.10 in your .python-version file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically and prevent this warning.
          remote: 
          remote: -----> Installing Python 3.10.0
          remote: -----> Installing uv #{UV_VERSION}
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+s
          remote:        Prepared 1 package in .+s
          remote:        Installed 1 package in .+s
          remote:        Bytecode compiled 1 file in .+s
          remote:         \\+ typing-extensions==4.15.0
          remote: -----> Saving cache
        REGEX
      end
    end
  end

  # This tests the error message when there is no .python-version file, and in particular the case where
  # the buildpack's default Python version is not compatible with `requires-python` in pyproject.toml.
  # (Since we must prevent uv from downloading its own Python or using system Python, and also
  # want a clearer error message than using `--python` or `UV_PYTHON` would give us).
  context 'when there is no .python-version file' do
    context 'when there is no cached Python version' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/uv_no_python_version_file', allow_failure: true) }

      it 'fails the build with .python-version instructions' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote: 
            remote:  !     Error: No Python version was specified.
            remote:  !     
            remote:  !     When using the package manager uv on Heroku, you must specify
            remote:  !     your app's Python version with a .python-version file.
            remote:  !     
            remote:  !     To add a .python-version file:
            remote:  !     
            remote:  !     1. Make sure you are in the root directory of your app
            remote:  !        and not a subdirectory.
            remote:  !     2. Run 'uv python pin #{DEFAULT_PYTHON_MAJOR_VERSION}'
            remote:  !        (adjust to match your app's major Python version).
            remote:  !     3. Commit the changes to your Git repository using
            remote:  !        'git add --all' and then 'git commit'.
            remote:  !     
            remote:  !     Note: We strongly recommend that you don't specify the Python
            remote:  !     patch version number in your .python-version file, since it will
            remote:  !     pin your app to an exact Python version and so stop your app from
            remote:  !     receiving security updates each time it builds.
            remote: 
            remote:  !     Push rejected, failed to compile Python app.
          OUTPUT
        end
      end
    end

    context 'when there is a cached Python version' do
      let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', allow_failure: true) }

      it 'fails the build with .python-version instructions' do
        app.deploy do |app|
          FileUtils.rm('requirements.txt')
          FileUtils.cp(FIXTURE_DIR.join('uv_no_python_version_file/pyproject.toml'), '.')
          FileUtils.cp(FIXTURE_DIR.join('uv_no_python_version_file/uv.lock'), '.')
          app.commit!
          app.push!
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> No Python version was specified. Using the same major version as the last build: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote: 
            remote:  !     Error: No Python version was specified.
            remote:  !     
            remote:  !     When using the package manager uv on Heroku, you must specify
            remote:  !     your app's Python version with a .python-version file.
            remote:  !     
            remote:  !     To add a .python-version file:
            remote:  !     
            remote:  !     1. Make sure you are in the root directory of your app
            remote:  !        and not a subdirectory.
            remote:  !     2. Run 'uv python pin #{DEFAULT_PYTHON_MAJOR_VERSION}'
            remote:  !        (adjust to match your app's major Python version).
            remote:  !     3. Commit the changes to your Git repository using
            remote:  !        'git add --all' and then 'git commit'.
            remote:  !     
            remote:  !     Note: We strongly recommend that you don't specify the Python
            remote:  !     patch version number in your .python-version file, since it will
            remote:  !     pin your app to an exact Python version and so stop your app from
            remote:  !     receiving security updates each time it builds.
            remote: 
            remote:  !     Push rejected, failed to compile Python app.
          OUTPUT
        end
      end
    end
  end

  # This tests the error message when a runtime.txt is present, and in particular the case where
  # the runtime.txt version is not compatible with `requires-python` in pyproject.toml.
  # (Since we must prevent uv from downloading its own Python or using system Python, and also
  # want a clearer error message than using `--python` or `UV_PYTHON` would give us).
  context 'when there is a runtime.txt file' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_runtime_txt', allow_failure: true) }

    it 'fails the build with runtime.txt migration instructions' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Using Python 3.11 specified in runtime.txt
          remote: 
          remote:  !     Error: The runtime.txt file isn't supported when using uv.
          remote:  !     
          remote:  !     When using the package manager uv on Heroku, you must specify
          remote:  !     your app's Python version with a .python-version file and not
          remote:  !     a runtime.txt file.
          remote:  !     
          remote:  !     To switch to a .python-version file:
          remote:  !     
          remote:  !     1. Make sure you are in the root directory of your app
          remote:  !        and not a subdirectory.
          remote:  !     2. Delete your runtime.txt file.
          remote:  !     3. Run 'uv python pin 3.11'
          remote:  !        (adjust to match your app's major Python version).
          remote:  !     4. Commit the changes to your Git repository using
          remote:  !        'git add --all' and then 'git commit'.
          remote:  !     
          remote:  !     Note: We strongly recommend that you don't specify the Python
          remote:  !     patch version number in your .python-version file, since it will
          remote:  !     pin your app to an exact Python version and so stop your app from
          remote:  !     receiving security updates each time it builds.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # This tests the error message when `requires-python` in pyproject.toml isn't compatible with
  # the version in .python-version. This might seem unnecessary since it's testing something uv
  # validates itself, however, the quality of the error message here depends on what uv options
  # we use (for example, using `--python` or `UV_PYTHON` results in a worse error message).
  context 'when requires-python in pyproject.toml is incompatible with .python-version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_mismatched_python_version', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Using CPython #{LATEST_PYTHON_3_13} interpreter at: /app/.heroku/python/bin/python3.13
          remote:        error: The Python request from `.python-version` resolved to Python #{LATEST_PYTHON_3_13}, which is incompatible with the project's Python requirement: `==3.12.*` (from `project.requires-python`)
          remote:        Use `uv python pin` to update the `.python-version` file to a compatible version
          remote: 
          remote:  !     Error: Unable to install dependencies using uv.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # This tests not only our handling of failing dependency installation, but also that we're running
  # uv in such a way that it errors if the lockfile is out of sync, rather than simply updating it.
  context 'when uv.lock is out of sync with pyproject.toml' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/uv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Installing dependencies using 'uv sync --locked --no-default-groups'
          remote:        Resolved 2 packages in .+s
          remote:        error: The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
          remote:        
          remote:        hint: To update the lockfile, run `uv lock`.
          remote: 
          remote:  !     Error: Unable to install dependencies using uv.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end
end
