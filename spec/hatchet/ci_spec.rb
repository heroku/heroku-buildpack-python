require_relative '../spec_helper'

describe "Heroku CI" do
  it "works" do
    before_deploy = Proc.new do
      File.open("app.json", "w+") do |f|
        f.puts <<~EOM
          {
            "environments": {
              "test": {
                "scripts": {
                  "test": "nosetests"
                }
              }
            }
          }
        EOM
      end

      run!("echo nose >> requirements.txt")
    end

    Hatchet::Runner.new("python_default", before_deploy: before_deploy).run_ci do |test_run|
      expect(test_run.output).to match("Downloading nose")
      expect(test_run.output).to match("OK")

      test_run.run_again

      expect(test_run.output).to match("installing from cache")
      expect(test_run.output).to_not match("Downloading nose")
    end
  end
end
