# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'NLTK corpora support' do
  context 'when the NLTK package is installed and nltk.txt is present' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_dependency_and_nltk_txt') }

    it 'installs the specified NLTK corpora' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Downloading NLTK corpora...
          remote: -----> Downloading NLTK packages: city_database stopwords
          remote:        .*: RuntimeWarning: 'nltk.downloader' found in sys.modules after import of package 'nltk', but prior to execution of 'nltk.downloader'; this may result in unpredictable behaviour
          remote:        \\[nltk_data\\] Downloading package city_database to
          remote:        \\[nltk_data\\]     /app/.heroku/python/nltk_data...
          remote:        \\[nltk_data\\]   Unzipping corpora/city_database.zip.
          remote:        \\[nltk_data\\] Downloading package stopwords to
          remote:        \\[nltk_data\\]     /app/.heroku/python/nltk_data...
          remote:        \\[nltk_data\\]   Unzipping corpora/stopwords.zip.
        REGEX

        # TODO: Add a test that the downloaded corpora can be found at runtime.
      end
    end
  end

  context 'when the NLTK package is installed but there is no nltk.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_dependency_only') }

    it 'warns that nltk.txt was not found' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Downloading NLTK corpora...
          remote:        'nltk.txt' not found, not downloading any corpora
        REGEX
      end
    end
  end

  context 'when only nltk.txt is present' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_txt_but_no_dependency') }

    it 'does not try to install the specified NLTK corpora' do
      app.deploy do |app|
        expect(app.output).not_to include('NLTK')
        expect(app.output).not_to include('nltk_data')
      end
    end
  end

  context 'when nltk.txt contains invalid entries' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_txt_invalid', allow_failure: true) }

    it 'fails the build' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX, Regexp::MULTILINE))
          remote: -----> Downloading NLTK corpora...
          remote: -----> Downloading NLTK packages: invalid!
          remote:        .+: RuntimeWarning: 'nltk.downloader' found in sys.modules after import of package 'nltk', but prior to execution of 'nltk.downloader'; this may result in unpredictable behaviour
          remote:        \\[nltk_data\\] Error loading invalid!: Package 'invalid!' not found in
          remote:        \\[nltk_data\\]     index
          remote:        Error installing package. Retry\\? \\[n/y/e\\]
          remote:        Traceback \\(most recent call last\\):
          remote:        .+
          remote:        EOFError: EOF when reading a line
          remote: 
          remote:  !     Error: Unable to download NLTK data.
          remote:  !     
          remote:  !     The 'python -m nltk.downloader' command to download NLTK
          remote:  !     data didn't exit successfully.
          remote:  !     
          remote:  !     See the log output above for more information.
          remote: 
          remote:  !     Push rejected, failed to compile Python app.
        REGEX
      end
    end
  end
end
