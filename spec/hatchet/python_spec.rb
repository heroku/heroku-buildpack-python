require_relative '../spec_helper'

describe "Default Python Deploy" do
  it "🐍" do
    Hatchet::Runner.new('python-getting-started', stack: DEFAULT_STACK).deploy do |app|
      expect(app.output).to           match(/Installing pip/)
      expect(app.run('python -V')).to match(/3.6.10/)


      expect(app.output).to_not match("Clearing cached dependencies")

      # Redeploy
      run!(%Q{echo "flask" >> requirements.txt})
      run!(%Q{git add . ; git commit --allow-empty -m next})
      app.push!

      # Check for the cache tohave cleared
      expect(app.output).to match("Clearing cached dependencies")

      run!(%Q{git commit --allow-empty -m next})
      app.push!

      # The cache should not clear with no changes
      expect(app.output).to_not match("Clearing cached dependencies")

    end
  end
end
