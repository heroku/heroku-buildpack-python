# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'NLTK corpora support' do
  context 'when the NLTK package is installed and nltk.txt is present' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_dependency_and_nltk_txt') }

    it 'installs the specified NLTK corpora' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Downloading NLTK corpora…
          remote: -----> Downloading NLTK packages: city_database stopwords
          remote: /app/.heroku/python/lib/python3.6/runpy.py:125: RuntimeWarning: 'nltk.downloader' found in sys.modules after import of package 'nltk', but prior to execution of 'nltk.downloader'; this may result in unpredictable behaviour
          remote:   warn\\(RuntimeWarning\\(msg\\)\\)
          remote: \\[nltk_data\\] Downloading package city_database to
          remote: \\[nltk_data\\]     /tmp/build_.*/.heroku/python/nltk_data...
          remote: \\[nltk_data\\]   Unzipping corpora/city_database.zip.
          remote: \\[nltk_data\\] Downloading package stopwords to
          remote: \\[nltk_data\\]     /tmp/build_.*/.heroku/python/nltk_data...
          remote: \\[nltk_data\\]   Unzipping corpora/stopwords.zip.
        REGEX
      end
    end
  end

  context 'when the NLTK package is installed but there is no nltk.txt' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_dependency_only') }

    it 'warns that nltk.txt was not found' do
      app.deploy do |app|
        expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
          remote: -----> Downloading NLTK corpora…
          remote:  !     'nltk.txt' not found, not downloading any corpora
          remote:  !     Learn more: https://devcenter.heroku.com/articles/python-nltk
        REGEX
      end
    end
  end

  context 'when only nltk.txt is present' do
    let(:app) { Hatchet::Runner.new('spec/fixtures/nltk_txt_but_no_dependency') }

    it 'does not try to install the specified NLTK corpora' do
      app.deploy do |app|
        expect(app.output.downcase).not_to include('nltk')
      end
    end
  end
end
