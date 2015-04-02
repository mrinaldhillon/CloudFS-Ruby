# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudfs/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudfs"
  spec.version       = CloudFS::VERSION
  spec.authors       = ['Bitcasa Inc.']
  spec.email         = ['sdks@bitcasa.com']
  spec.summary       = 'CloudFS SDK for Ruby'
  spec.description   = 'Allow developers to easliy access Bitcasa CloudFS'
  spec.homepage      = "https://github.com/bitcasa/CloudFS-Ruby"
	spec.license			 = "MIT"
  spec.files         = Dir['lib/**/*', '.yardopts']
  spec.test_files    = Dir['spec/**/*_spec.rb']
  spec.require_paths = ['lib']
  spec.has_rdoc      = 'yard'
	spec.platform    = Gem::Platform::RUBY
	spec.required_ruby_version = '>= 2.0.0'
	spec.add_runtime_dependency 'httpclient', '>= 2.6.0'
	spec.add_runtime_dependency 'multi_json', '>= 1.10.0'
  spec.add_development_dependency 'minitest', '~> 5.5.1'
end
