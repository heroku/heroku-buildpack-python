require_relative '../spec_helper'

describe "Default Python Deploy" do
  it "🐍" do
    Hatchet::Runner.new('python-getting-started', stack: DEFAULT_STACK).deploy do |app|

      # What should happen on first deploy
      expect(app.output).to           match(/Installing pip/)

      # What should not happen
      expect(app.output).to_not match("Requirements file has been changed, updating cache")
      expect(app.output).to_not match("No change in requirements detected, installing from cache")
      expect(app.output).to_not match("No such file or directory")
      expect(app.output).to_not match("cp: cannot create regular file")

      # Redeploy with changed requirements file
      run!(%Q{echo "" >> requirements.txt})
      run!(%Q{echo "flask" >> requirements.txt})
      run!(%Q{git add . ; git commit --allow-empty -m next})
      app.push!

      # Check for the cache to have cleared
      expect(app.output).to match("Requirements file has been changed, updating cache")

      # What should not happen when the requirements file is changed
      expect(app.output).to_not match("No dependencies found, preparing to install")
      expect(app.output).to_not match("No change in requirements detected, installing from cache")

      run!(%Q{git commit --allow-empty -m next})
      app.push!

      # With no changes on redeploy, the cache should
      expect(app.output).to match("No change in requirements detected, installing from cache")

      # With no changes on redeploy, the cache should not
      expect(app.output).to_not match("Requirements file has been changed, updating cache")
      expect(app.output).to_not match("No dependencies found, preparing to install")

      expect(app.run('python -V')).to match(/3.7.6/)
    end
  end
end
