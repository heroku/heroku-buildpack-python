class PythonEnvironment
  attr_reader :app

  def initialize(app_name)
    @app = Machete.deploy_app(app_name)
  end

  def execute(file: nil, code: nil, &block)
    if file
      file_path = File.join(Dir.pwd, 'cf_spec', 'fixtures', 'features', file)
      code = File.read(file_path)
    end

    code.gsub!(/^#{code.scan(/^\s*/).min_by{|l|l.length}}/, "")

    app_url = Machete::CF::CLI.url_for_app(app)
    response = HTTParty.post("http://#{app_url}/execute", body: {code: code})
    yield(response.body)
  end
end
