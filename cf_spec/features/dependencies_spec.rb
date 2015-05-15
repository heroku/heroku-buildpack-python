require 'spec_helper'
require 'support/python_environment'

describe 'dependencies in the manifest' do
  context 'for Python 2' do
    before { @env = PythonEnvironment.new('flask_web_app') }

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

  context 'for Python 3' do
    before { @env = PythonEnvironment.new('flask_web_app_python_3') }

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
end

