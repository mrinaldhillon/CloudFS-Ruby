# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudfs/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudfs_sdk"
  spec.version       = CloudFS::VERSION
  spec.authors       = ['Bitcasa Inc.']
  spec.email         = ['dstrong@bitcasa.com']
  spec.summary       = 'CloudFS SDK for Ruby'
  spec.description   = 'CloudFS Ruby SDK for Bitcasa cloud storage filesystem'
  spec.homepage      = "https://github.com/bitcasa/CloudFS-Ruby"
	spec.license			 = "MIT"
  spec.files         = Dir['lib/**/*', 'tests/**/*', '.yardopts']
  spec.require_paths = ['lib']
  spec.has_rdoc      = 'yard'
	spec.platform    = Gem::Platform::RUBY
	spec.required_ruby_version = '>= 2.0.0'
	spec.add_runtime_dependency 'httpclient', '>= 2.6.0'
	spec.add_runtime_dependency 'multi_json', '>= 1.10.0'
end
