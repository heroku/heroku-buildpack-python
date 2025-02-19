# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.shared_examples 'builds with the requested Python version' do |requested_version, resolved_version|
  it "builds with Python #{requested_version}" do
    app.deploy do |app|
      if requested_version == '3.13'
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{requested_version} specified in .python-version
          remote: -----> Installing Python #{resolved_version}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      else
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python #{requested_version} specified in .python-version
          remote: -----> Installing Python #{resolved_version}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
      expect(app.run('python -V')).to include("Python #{resolved_version}")
    end
  end
end

RSpec.describe 'Python version support' do
  context 'when no Python version is specified' do
    let(:buildpacks) { [:default] }
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_unspecified', buildpacks:) }

    context 'with a new app' do
      it 'builds with the default Python version' do
        app.deploy do |app|
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> No Python version was specified. Using the buildpack default: Python #{DEFAULT_PYTHON_MAJOR_VERSION}
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote: -----> Installing Python #{DEFAULT_PYTHON_FULL_VERSION}
          OUTPUT
        end
      end
    end

    context 'with an app last built using an older default Python version' do
      # This test performs an initial build using an older buildpack version, followed
      # by a build using the current version. This ensures that:
      # - The current buildpack can successfully read the version metadata
      #   written to the build cache by older buildpack versions.
      # - If no Python version is specified, the same major version as the
      #   last build is used (sticky versioning).
      # - Changes in the pip version are handled correctly.
      let(:buildpacks) { ['https://github.com/heroku/heroku-buildpack-python#v267'] }

      it 'builds with the same Python version as the last build' do
        app.deploy do |app|
          update_buildpacks(app, [:default])
          app.commit!
          app.push!
          expect(clean_output(app.output)).to include(<<~OUTPUT)
            remote: -----> Python app detected
            remote: -----> No Python version was specified. Using the same major version as the last build: Python 3.12
            remote:        To use a different version, see: https://devcenter.heroku.com/articles/python-runtimes
            remote: -----> Discarding cache since:
            remote:        - The Python version has changed from 3.12.7 to #{LATEST_PYTHON_3_12}
            remote:        - The pip version has changed from 24.0 to #{PIP_VERSION}
            remote: -----> Installing Python #{LATEST_PYTHON_3_12}
            remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          OUTPUT
          expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_12}")
        end
      end
    end
  end

  context 'when .python-version contains Python 3.9' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    it 'builds with Python 3.9 but shows a deprecation warning' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.9 specified in .python-version
          remote: 
          remote:  !     Warning: Support for Python 3.9 is ending soon!
          remote:  !     
          remote:  !     Python 3.9 will reach its upstream end-of-life in October 2025,
          remote:  !     at which point it will no longer receive security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, support for Python 3.9 will be removed from this
          remote:  !     buildpack on 7th January 2026.
          remote:  !     
          remote:  !     Upgrade to a newer Python version as soon as possible, by
          remote:  !     changing the version in your .python-version file.
          remote:  !     
          remote:  !     For more information, see:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote: 
          remote: -----> Installing Python #{LATEST_PYTHON_3_9}
          remote: -----> Installing pip #{PIP_VERSION}, setuptools #{SETUPTOOLS_VERSION} and wheel #{WHEEL_VERSION}
          remote: -----> Installing SQLite3
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
        expect(app.run('python -V')).to include("Python #{LATEST_PYTHON_3_9}")
      end
    end
  end

  context 'when .python-version contains Python 3.10' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.10') }

    include_examples 'builds with the requested Python version', '3.10', LATEST_PYTHON_3_10
  end

  context 'when .python-version contains Python 3.11' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.11') }

    include_examples 'builds with the requested Python version', '3.11', LATEST_PYTHON_3_11
  end

  context 'when .python-version contains Python 3.12' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.12') }

    include_examples 'builds with the requested Python version', '3.12', LATEST_PYTHON_3_12
  end

  context 'when .python-version contains Python 3.13' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.13') }

    include_examples 'builds with the requested Python version', '3.13', LATEST_PYTHON_3_13
  end

  context 'when .python-version contains an invalid Python version string' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_file_invalid_version', allow_failure: true) }

    it 'aborts the build with an invalid .python-version message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in .python-version.
          remote:  !     
          remote:  !     The Python version specified in your .python-version file
          remote:  !     isn't in the correct format.
          remote:  !     
          remote:  !     The following version was found:
          remote:  !       3.12.0invalid  
          remote:  !     
          remote:  !     However, the Python version must be specified as either:
          remote:  !     1. The major version only: 3.X  (recommended)
          remote:  !     2. An exact patch version: 3.X.Y
          remote:  !     
          remote:  !     Don't include quotes or a 'python-' prefix. To include
          remote:  !     comments, add them on their own line, prefixed with '#'.
          remote:  !     
          remote:  !     For example, to request the latest version of Python #{DEFAULT_PYTHON_MAJOR_VERSION},
          remote:  !     update your .python-version file so it contains:
          remote:  !     #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:  !     
          remote:  !     We strongly recommend that you use the major version form
          remote:  !     instead of pinning to an exact version, since it will allow
          remote:  !     your app to receive Python security updates.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when .python-version does not contain a Python version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_file_no_version', allow_failure: true) }

    it 'aborts the build with a no version string found message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in .python-version.
          remote:  !     
          remote:  !     No Python version was found in your .python-version file.
          remote:  !     
          remote:  !     Update the file so that it contains a valid Python version.
          remote:  !     
          remote:  !     For example, to request the latest version of Python #{DEFAULT_PYTHON_MAJOR_VERSION},
          remote:  !     update your .python-version file so it contains:
          remote:  !     #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:  !     
          remote:  !     If the file already contains a version, check the line doesn't
          remote:  !     begin with a '#', otherwise it will be treated as a comment.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when .python-version contains multiple Python versions' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_file_multiple_versions', allow_failure: true) }

    it 'aborts the build with a multiple versions not supported message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in .python-version.
          remote:  !     
          remote:  !     Multiple versions were found in your .python-version file:
          remote:  !     
          remote:  !     // invalid comment
          remote:  !     3.12
          remote:  !     2.7
          remote:  !     
          remote:  !     Update the file so it contains only one Python version.
          remote:  !     
          remote:  !     If you have added comments to the file, make sure that those
          remote:  !     lines begin with a '#', so that they are ignored.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when .python-version contains an EOL Python 3.x version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_eol', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.8 specified in .python-version
          remote: 
          remote:  !     Error: The requested Python version has reached end-of-life.
          remote:  !     
          remote:  !     Python 3.8 has reached its upstream end-of-life, and is
          remote:  !     therefore no longer receiving security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, it's no longer supported by this buildpack:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote:  !     
          remote:  !     Please upgrade to at least Python 3.9 by changing the
          remote:  !     version in your .python-version file.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when .python-version contains an non-existent Python major version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_non_existent_major', allow_failure: true) }

    it 'aborts the build with an invalid .python-version message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.999 specified in .python-version
          remote: 
          remote:  !     Error: The requested Python version isn't recognised.
          remote:  !     
          remote:  !     The requested Python version 3.999 isn't recognised.
          remote:  !     
          remote:  !     Check that this Python version has been officially released,
          remote:  !     and that the Python buildpack has added support for it:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote:  !     
          remote:  !     If it has, make sure that you are using the latest version
          remote:  !     of this buildpack, and haven't pinned to an older release:
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
          remote:  !     
          remote:  !     Otherwise, switch to a supported version (such as Python #{DEFAULT_PYTHON_MAJOR_VERSION})
          remote:  !     by changing the version in your .python-version file.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when .python-version contains a non-existent Python patch version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_version_non_existent_patch', allow_failure: true) }

    it 'aborts the build with a version not available message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Python app detected
          remote: -----> Using Python 3.12.999 specified in .python-version
          remote: -----> Installing Python 3.12.999
          remote:        curl: \\(22\\) The requested URL returned error: 404.*
          remote:        zstd: /\\*stdin\\*\\\\: unexpected end of file 
          remote:        tar: Child returned status 1
          remote:        tar: Error is not recoverable: exiting now
          remote: 
          remote:  !     Error: The requested Python version isn't available.
          remote:  !     
          remote:  !     Your app's .python-version file specifies a Python version
          remote:  !     of 3.12.999, however, we couldn't find that version on S3.
          remote:  !     
          remote:  !     Check that this Python version has been released upstream,
          remote:  !     and that the Python buildpack has added support for it:
          remote:  !     https://www.python.org/downloads/
          remote:  !     https://github.com/heroku/heroku-buildpack-python/blob/main/CHANGELOG.md
          remote:  !     
          remote:  !     If it has, make sure that you are using the latest version
          remote:  !     of this buildpack, and haven't pinned to an older release:
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#view-your-buildpacks
          remote:  !     https://devcenter.heroku.com/articles/managing-buildpacks#classic-buildpacks-references
          remote:  !     
          remote:  !     We also strongly recommend that you do not pin your app to an
          remote:  !     exact Python version such as 3.12.999, and instead only specify
          remote:  !     the major Python version of 3.12 in your .python-version file.
          remote:  !     This will allow your app to receive the latest available Python
          remote:  !     patch version automatically, and prevent this type of error.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end

  context 'when runtime.txt contains an invalid Python version string' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_invalid_version', allow_failure: true) }

    it 'aborts the build with an invalid runtime.txt message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: 
          remote:  !     Error: Invalid Python version in runtime.txt.
          remote:  !     
          remote:  !     The Python version specified in your runtime.txt file isn't
          remote:  !     in the correct format.
          remote:  !     
          remote:  !     The following file contents were found, which aren't valid:
          remote:  !     python-3.12.0invalid
          remote:  !     
          remote:  !     However, the runtime.txt file is deprecated since it has
          remote:  !     been replaced by the .python-version file. As such, we
          remote:  !     recommend that you switch to using a .python-version file
          remote:  !     instead of fixing your runtime.txt file.
          remote:  !     
          remote:  !     Please delete your runtime.txt file and create a new file named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' at the start of the filename.
          remote:  !     
          remote:  !     In the new file, specify your app's Python version without
          remote:  !     quotes or a 'python-' prefix. For example:
          remote:  !     #{DEFAULT_PYTHON_MAJOR_VERSION}
          remote:  !     
          remote:  !     We strongly recommend that you use the major version form
          remote:  !     instead of pinning to an exact version, since it will allow
          remote:  !     your app to receive Python security updates.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  context 'when runtime.txt contains an EOL Python 2.x version' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_eol_version', allow_failure: true) }

    it 'aborts the build with an EOL message' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 2.7.18 specified in runtime.txt
          remote: 
          remote:  !     Error: The requested Python version has reached end-of-life.
          remote:  !     
          remote:  !     Python 2.7 has reached its upstream end-of-life, and is
          remote:  !     therefore no longer receiving security updates:
          remote:  !     https://devguide.python.org/versions/#supported-versions
          remote:  !     
          remote:  !     As such, it's no longer supported by this buildpack:
          remote:  !     https://devcenter.heroku.com/articles/python-support#supported-python-versions
          remote:  !     
          remote:  !     Please upgrade to at least Python 3.9 by changing the
          remote:  !     version in your runtime.txt file.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        OUTPUT
      end
    end
  end

  # This also tests runtime.txt support for the major version only syntax, as well as the handling
  # of runtime.txt files that contain stray whitespace.
  context 'when there is both a runtime.txt and .python-version file' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/runtime_txt_and_python_version_file') }

    it 'builds with the version from runtime.txt' do
      app.deploy do |app|
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in runtime.txt
          remote: 
          remote:  !     Warning: The runtime.txt file is deprecated.
          remote:  !     
          remote:  !     The runtime.txt file is deprecated since it has been replaced
          remote:  !     by the more widely supported .python-version file:
          remote:  !     https://devcenter.heroku.com/changelog-items/3141
          remote:  !     
          remote:  !     Please delete your runtime.txt file and create a new file named:
          remote:  !     .python-version
          remote:  !     
          remote:  !     Make sure to include the '.' at the start of the filename.
          remote:  !     
          remote:  !     In the new file, specify your app's Python version without
          remote:  !     quotes or a 'python-' prefix. For example:
          remote:  !     3.13
          remote:  !     
          remote:  !     We strongly recommend that you use the major version form
          remote:  !     instead of pinning to an exact version, since it will allow
          remote:  !     your app to receive Python security updates.
          remote:  !     
          remote:  !     In the future support for runtime.txt will be removed and
          remote:  !     this warning will be made an error.
          remote: 
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
        OUTPUT
      end
    end
  end

  context 'when the requested Python version has changed since the last build' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/python_3.9') }

    it 'builds with the new Python version after removing the old install' do
      app.deploy do |app|
        File.write('.python-version', '3.13')
        app.commit!
        app.push!
        expect(clean_output(app.output)).to include(<<~OUTPUT)
          remote: -----> Python app detected
          remote: -----> Using Python 3.13 specified in .python-version
          remote: -----> Discarding cache since:
          remote:        - The Python version has changed from #{LATEST_PYTHON_3_9} to #{LATEST_PYTHON_3_13}
          remote: -----> Installing Python #{LATEST_PYTHON_3_13}
          remote: -----> Installing pip #{PIP_VERSION}
          remote: -----> Installing dependencies using 'pip install -r requirements.txt'
          remote:        Collecting typing-extensions==4.12.2 (from -r requirements.txt (line 2))
        OUTPUT
      end
    end
  end
end
