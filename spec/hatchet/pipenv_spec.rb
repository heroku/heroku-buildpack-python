# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds using Pipenv with the requested Python version' do |python_version|
  it "builds with Python #{python_version}" do
    app.deploy do |app|
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> Python app detected
        remote: -----> Using Python version specified in Pipfile.lock
        remote: -----> Installing python-#{python_version}
        remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
        remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
        remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
        remote: -----> Installing SQLite3
      REGEX
    end
  end
end

RSpec.shared_examples 'aborts the build with a runtime not available message (Pipenv)' do |requested_version|
  it 'aborts the build with a runtime not available message' do
    app.deploy do |app|
      expect(clean_output(app.output)).to include(<<~OUTPUT)
        remote: -----> Python app detected
        remote: -----> Using Python version specified in Pipfile.lock
        remote:  !     Requested runtime 'python-#{requested_version}' is not available for this stack (#{app.stack}).
        remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
      OUTPUT
    end
  end
end

RSpec.describe 'Pipenv support' do
  context 'without a Pipfile.lock' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_no_lockfile') }

    it 'builds with the default Python version using just the Pipfile' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote:  !     No 'Pipfile.lock' found! We recommend you commit this into your repository.
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        The flag --skip-lock has been reintroduced (but is not recommended).  Without 
          remote:        the lock resolver it is difficult to manage multiple package indexes, and hash 
          remote:        checking is not provided.  However it can help manage installs with current 
          remote:        deficiencies in locking across platforms.
          remote:        Installing dependencies from Pipfile...
          remote: -----> Installing SQLite3
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock but no Python version specified' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 'builds with the default Python version' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing python_version 3.6' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.6', allow_failure: true) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'aborts the build with an EOL message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~OUTPUT))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 3.6 reached upstream end-of-life on December 23rd, 2021, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     As such, it is no longer supported by the latest version of this buildpack.
            remote:  !     
            remote:  !     Please upgrade to a newer Python version. See:
            remote:  !     https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      # Python 3.6 is EOL, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', '3.6.15'
    end
  end

  context 'with a Pipfile.lock containing python_version 3.7' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.7', allow_failure: true) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'aborts the build with an EOL message' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~OUTPUT))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 3.7 reached upstream end-of-life on June 27th, 2023, and is
            remote:  !     therefore no longer receiving security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     As such, it is no longer supported by the latest version of this buildpack.
            remote:  !     
            remote:  !     Please upgrade to a newer Python version. See:
            remote:  !     https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
          OUTPUT
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      include_examples 'aborts the build with a runtime not available message (Pipenv)', '3.7.17'
    end
  end

  context 'with a Pipfile.lock containing python_version 3.8' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.8', allow_failure:) }

    context 'when using Heroku-20', stacks: %w[heroku-20] do
      it 'builds with the latest Python 3.8 but shows a deprecation warning' do
        app.deploy do |app|
          expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
            remote: -----> Python app detected
            remote: -----> Using Python version specified in Pipfile.lock
            remote:  !     
            remote:  !     Python 3.8 will reach its upstream end-of-life in October 2024, at which
            remote:  !     point it will no longer receive security updates:
            remote:  !     https://devguide.python.org/versions/#supported-versions
            remote:  !     
            remote:  !     Support for Python 3.8 will be removed from this buildpack on December 4th, 2024.
            remote:  !     
            remote:  !     Upgrade to a newer Python version as soon as possible to keep your app secure.
            remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
            remote:  !     
            remote: -----> Installing python-#{LATEST_PYTHON_3_8}
            remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
            remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
            remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
            remote: -----> Installing SQLite3
          REGEX
        end
      end
    end

    context 'when using Heroku-22', stacks: %w[heroku-22] do
      let(:allow_failure) { true }

      # Python 3.8 is in the security fix only stage of its lifecycle, so has not been built for newer stacks.
      include_examples 'aborts the build with a runtime not available message (Pipenv)', LATEST_PYTHON_3_8
    end
  end

  context 'with a Pipfile.lock containing python_version 3.9' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.9') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_9
  end

  context 'with a Pipfile.lock containing python_version 3.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.10') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_10
  end

  context 'with a Pipfile.lock containing python_version 3.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.11') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_11
  end

  context 'with a Pipfile.lock containing python_version 3.12' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_3.12') }

    include_examples 'builds using Pipenv with the requested Python version', LATEST_PYTHON_3_12
  end

  context 'with a Pipfile.lock containing python_full_version 3.10.7' do
    let(:allow_failure) { false }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version', allow_failure:) }

    it 'builds with the outdated Python version specified' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     
          remote:  !     A Python security update is available! Upgrade as soon as possible to: python-#{LATEST_PYTHON_3_10}
          remote:  !     See: https://devcenter.heroku.com/articles/python-runtimes
          remote:  !     
          remote: -----> Installing python-3.10.7
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'with a Pipfile.lock containing an invalid python_version',
          skip: 'unknown python_version values are currently ignored (W-8104668)' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     Requested runtime '^3.9' is not available for this stack (#{app.stack}).
          remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
        OUTPUT
      end
    end
  end

  context 'with a Pipfile.lock containing an invalid python_full_version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_full_version_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote:  !     Requested runtime 'python-X.Y.Z' is not available for this stack (#{app.stack}).
          remote:  !     For supported versions, see: https://devcenter.heroku.com/articles/python-support
        OUTPUT
      end
    end
  end

  context 'when there is a both a Pipfile.lock python_version and a runtime.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_runtime_txt') }

    it 'builds with the Python version from runtime.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python version specified in runtime.txt
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'when Pipfile.lock is unchanged since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_python_version_unspecified') }

    it 're-uses packages from the cache' do
      app.deploy do |app|
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the same version as the last build: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Using cached install of python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Installing SQLite3
          remote: -----> Discovering process types
        REGEX
      end
    end
  end

  context 'when there is both a Pipfile.lock and a requirements.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_and_requirements_txt') }

    it 'builds with Pipenv rather than pip' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python version specified in Pipfile.lock
          remote: -----> Installing python-#{LATEST_PYTHON_3_10}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Installing dependencies from Pipfile.lock \\(.+\\)...
          remote: -----> Installing SQLite3
        REGEX
      end
    end
  end

  context 'when the Pipfile.lock is out of sync with Pipfile' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_lockfile_out_of_sync', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Python app detected
          remote: -----> No Python version was specified. Using the buildpack default: python-#{DEFAULT_PYTHON_VERSION}
          remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
          remote: -----> Installing python-#{DEFAULT_PYTHON_VERSION}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing dependencies with Pipenv #{PIPENV_VERSION}
          remote:        Your Pipfile.lock \\(.+\\) is out of date.  Expected: \\(.+\\).
          remote:        .+
          remote:        ERROR:: Aborting deploy
        REGEX
      end
    end
  end

  context 'when Pipfile contains editable requirements' do
    let(:buildpacks) { [:default, 'heroku-community/inline'] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/pipenv_editable', buildpacks:) }

    it 'rewrites .pth, .egg-link and finder paths correctly for hooks, later buildpacks, runtime and cached builds' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Running post-compile hook
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: /app/.heroku/src/gunicorn
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable___local_package_pyproject_toml_0_0_1_finder.py <==
          remote: .*
          remote: MAPPING = \\{'local_package_pyproject_toml': '/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'\\}
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable__.local_package_pyproject_toml-0.0.1.pth <==
          remote: import __editable___.*
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local_package_setup_py.egg-link <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: .
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: /app/.heroku/src/gunicorn
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable___local_package_pyproject_toml_0_0_1_finder.py <==
          remote: .*
          remote: MAPPING = \\{'local_package_pyproject_toml': '/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'\\}
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable__.local_package_pyproject_toml-0.0.1.pth <==
          remote: import __editable___.*
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local_package_setup_py.egg-link <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: .
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test rewritten paths work at runtime.
        expect(app.run('bin/test-entrypoints')).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          .*

          ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          /app/packages/local_package_setup_py
          /app/.heroku/src/gunicorn

          ==> .heroku/python/lib/python.*/site-packages/__editable___local_package_pyproject_toml_0_0_1_finder.py <==
          .*
          MAPPING = \\{'local_package_pyproject_toml': '/app/packages/local_package_pyproject_toml/local_package_pyproject_toml'\\}
          .*

          ==> .heroku/python/lib/python.*/site-packages/__editable__.local_package_pyproject_toml-0.0.1.pth <==
          import __editable___.*
          ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          /app/.heroku/src/gunicorn
          .
          ==> .heroku/python/lib/python.*/site-packages/local_package_setup_py.egg-link <==
          /app/packages/local_package_setup_py
          .
          Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          Running entrypoint for the setup.py-based local package: Hello setup.py!
          Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX

        # Test that the cached .pth files work correctly.
        app.commit!
        app.push!
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Running post-compile hook
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /app/.heroku/src/gunicorn
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable___local_package_pyproject_toml_0_0_1_finder.py <==
          remote: .*
          remote: MAPPING = \\{'local_package_pyproject_toml': '/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'\\}
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable__.local_package_pyproject_toml-0.0.1.pth <==
          remote: import __editable___.*
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local_package_setup_py.egg-link <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: .
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
          remote: -----> Inline app detected
          remote: ==> .heroku/python/lib/python.*/site-packages/distutils-precedence.pth <==
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/easy-install.pth <==
          remote: /app/.heroku/src/gunicorn
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable___local_package_pyproject_toml_0_0_1_finder.py <==
          remote: .*
          remote: MAPPING = \\{'local_package_pyproject_toml': '/tmp/build_.*/packages/local_package_pyproject_toml/local_package_pyproject_toml'\\}
          remote: .*
          remote: 
          remote: ==> .heroku/python/lib/python.*/site-packages/__editable__.local_package_pyproject_toml-0.0.1.pth <==
          remote: import __editable___.*
          remote: ==> .heroku/python/lib/python.*/site-packages/gunicorn.egg-link <==
          remote: /app/.heroku/src/gunicorn
          remote: .
          remote: ==> .heroku/python/lib/python.*/site-packages/local_package_setup_py.egg-link <==
          remote: /tmp/build_.*/packages/local_package_setup_py
          remote: .
          remote: Running entrypoint for the pyproject.toml-based local package: Hello pyproject.toml!
          remote: Running entrypoint for the setup.py-based local package: Hello setup.py!
          remote: Running entrypoint for the VCS package: gunicorn \\(version 20.1.0\\)
        REGEX
      end
    end
  end
end
