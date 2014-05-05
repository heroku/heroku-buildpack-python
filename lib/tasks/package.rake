require 'cloud_foundry/buildpack_packager'

desc 'package the buildpack as a zip with all dependencies'
task :package do
  CloudFoundry::BuildpackPackager.package
end