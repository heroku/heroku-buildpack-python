require_relative '../spec_helper'

describe "Python" do
  describe "cache" do
    it "functions correctly" do
      Hatchet::Runner.new("python_default").deploy do |app|
        expect(app.output).to match(/Installing pip/)

        expect(app.output).to_not match("Requirements file has been changed, clearing cached dependencies")
        expect(app.output).to_not match("No change in requirements detected, installing from cache")
        expect(app.output).to_not match("No such file or directory")
        expect(app.output).to_not match("cp: cannot create regular file")

        # Redeploy with changed requirements file
        run!(%Q{echo "" >> requirements.txt})
        run!(%Q{echo "pygments" >> requirements.txt})
        run!(%Q{git add . ; git commit --allow-empty -m next})
        app.push!

        # Check the cache to have cleared
        expect(app.output).to match("Requirements file has been changed, clearing cached dependencies")
        expect(app.output).to_not match("No dependencies found, preparing to install")
        expect(app.output).to_not match("No change in requirements detected, installing from cache")

        # With no changes on redeploy, the cache should be present
        run!(%Q{git commit --allow-empty -m next})
        app.push!

        expect(app.output).to match("No change in requirements detected, installing from cache")
        expect(app.output).to_not match("Requirements file has been changed, clearing cached dependencies")
        expect(app.output).to_not match("No dependencies found, preparing to install")
      end
    end
  end

  describe "python versions" do
    let(:stack) { ENV["HEROKU_TEST_STACK"] || DEFAULT_STACK }
    it "works with 3.7.6" do
      version = "3.7.6"
      before_deploy = -> { run!(%Q{echo "python-#{version}" >> runtime.txt}) }
      Hatchet::Runner.new("python_default", before_deploy: before_deploy, stack: stack).deploy do |app|
        expect(app.run('python -V')).to match(version)
      end
    end

    it "works with 3.8.2" do
      version = "3.8.2"
      before_deploy = -> { run!(%Q{echo "python-#{version}" >> runtime.txt}) }
      Hatchet::Runner.new("python_default", before_deploy: before_deploy, stack: stack).deploy do |app|
        expect(app.run('python -V')).to match(version)
      end
    end

    it "fails with a bad version" do
      version = "3.8.2.lol"
      before_deploy = -> { run!(%Q{echo "python-#{version}" >> runtime.txt}) }
      Hatchet::Runner.new("python_default", before_deploy: before_deploy, stack: stack, allow_failure: true).deploy do |app|
        expect(app.output).to match("not available for this stack")
      end
    end
  end

  it "getting started app has no relative paths" do
    buildpacks = [
      :default,
      "https://github.com/sharpstone/force_absolute_paths_buildpack"
    ]
    Hatchet::Runner.new("python-getting-started", buildpacks: buildpacks).deploy do |app|
      # Deploy works
    end
  end
end
