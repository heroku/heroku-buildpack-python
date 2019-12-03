require_relative '../spec_helper'

describe "Python!!!!!!!!!!!" do
  it "🐍" do
    Hatchet::Runner.new('python-getting-started', stack: DEFAULT_STACK).deploy do |app|
      expect(app.output).to           match(/Installing pip/)
      expect(app.run('python -V')).to match(/3.6.9/)
    end
  end
end
