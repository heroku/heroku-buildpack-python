# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Python getting started project' do
  it 'builds successfully' do
    Hatchet::Runner.new('python-getting-started').deploy do |app|
      # TODO: Decide what to do with this test given it mostly duplicates the one in django_spec.rb.
      expect(clean_output(app.output)).to match(Regexp.new(<<~REGEX))
        remote: -----> \\$ python manage.py collectstatic --noinput
        remote:        \\d+ static files copied to '/tmp/build_.*/staticfiles', \\d+ post-processed.
      REGEX
    end
  end
end
