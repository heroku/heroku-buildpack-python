require 'zip'
require 'tmpdir'
require 'json'

module CloudFoundry
  module BuildpackPackager
    EXCLUDE_FROM_BUILDPACK = [
        /\.git/,
        /\.gitignore/,
        /\.{1,2}$/
    ]

    class << self
      def package
        Dir.mktmpdir do |temp_dir|
          copy_buildpack_contents(temp_dir)
          download_dependencies(temp_dir) unless ENV['ONLINE']
          compress_buildpack(temp_dir)
        end
      end

      private

      def copy_buildpack_contents(target_path)
        run_cmd "cp -r * #{target_path}"
      end

      def download_dependencies(target_path)
        dependency_path = File.join(target_path, 'dependencies')

        dependencies.each do |version|
          run_cmd "echo 0"
        end
      end

      def dependencies
        []
      end

      def in_pack?(file)
        !EXCLUDE_FROM_BUILDPACK.any? { |re| file =~ re }
      end

      def compress_buildpack(target_path)
        Zip::File.open('python_buildpack.zip', Zip::File::CREATE) do |zipfile|
          Dir.glob(File.join(target_path, "**", "**"), File::FNM_DOTMATCH).each do |file|
            zipfile.add(file.sub(target_path + '/', ''), file) if (in_pack?(file))
          end
        end
      end

      def run_cmd(cmd)
        puts "$ #{cmd}"
        `#{cmd}`
      end
    end
  end
end
