require 'base_packager'
require 'json'

class BuildpackPackager < BasePackager

  def dependencies
    [
      "http://envy-versions.s3.amazonaws.com/python-2.7.0.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-2.7.1.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-2.7.2.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-2.7.3.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-2.7.6.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-3.2.0.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-3.2.1.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-3.2.2.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-3.2.3.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/python-3.4.0.tar.bz2",
      "http://envy-versions.s3.amazonaws.com/pypy-1.9.tar.bz2",
      "http://cl.ly/0a191R3K160t1w1P0N25/vendor-libmemcached.tar.gz"
    ]
  end

  def excluded_files
    []
  end
end

BuildpackPackager.new("python", ARGV.first.to_sym).package
