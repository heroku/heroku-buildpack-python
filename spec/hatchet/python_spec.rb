require_relative '../spec_helper'

describe "Default Python Deploy" do

  def set_python_version(d, v)
    Dir.chdir(d) do
      File.open('runtime.txt', 'w') do |f|
        f.puts "python-#{v}"
      end
      `git add runtime.txt && git commit -am "setting python version"`
    end
  end

  before(:each) do
    set_python_version(app.directory, python_version)
    init_app(app)
  end

  ["3.7.6", "3.8.2"].each do |version|
    context "on python-#{version}" do
      let(:app) { Hatchet::Runner.new('python-getting-started', stack: DEFAULT_STACK) }
      let(:python_version) { version }
      it "🐍" do
        app.deploy do |app|
          # What should happen on first deploy
          expect(app.output).to           match(/Installing pip/)

          # What should not happen
          expect(app.output).to_not match("Requirements file has been changed, clearing cached dependencies")
          expect(app.output).to_not match("No change in requirements detected, installing from cache")
          expect(app.output).to_not match("No such file or directory")
          expect(app.output).to_not match("cp: cannot create regular file")

          # Redeploy with changed requirements file
          run!(%Q{echo "" >> requirements.txt})
          run!(%Q{echo "flask" >> requirements.txt})
          run!(%Q{git add . ; git commit --allow-empty -m next})
          app.push!

          # Check the cache to have cleared
          expect(app.output).to match("Requirements file has been changed, clearing cached dependencies")

          # What should not happen when the requirements file is changed
          expect(app.output).to_not match("No dependencies found, preparing to install")
          expect(app.output).to_not match("No change in requirements detected, installing from cache")

          run!(%Q{git commit --allow-empty -m next})
          app.push!

          # With no changes on redeploy, the cache should
          expect(app.output).to match("No change in requirements detected, installing from cache")

          # With no changes on redeploy, the cache should not
          expect(app.output).to_not match("Requirements file has been changed, clearing cached dependencies")
          expect(app.output).to_not match("No dependencies found, preparing to install")

          expect(app.run('python -V')).to match(version)
        end
      end
    end
  end
end
