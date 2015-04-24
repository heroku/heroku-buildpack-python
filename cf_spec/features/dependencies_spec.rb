require 'spec_helper'
require 'support/python_environment'

describe 'dependencies in the manifest' do
  before(:all) { @env = PythonEnvironment.new }

  describe '#libffi' do
    it 'can integrate with C-header files' do
      @env.execute(file: 'libffi.py') do |output|
        expect(output).to eq "hi there, world!\n"
      end
    end
  end

  describe '#libmemcache' do
    it 'can interact with memcache server' do
      @env.execute(file: 'libmemcache.py') do |output|
        expect(output).to eq "Could not connect\n"
      end
    end
  end
end

