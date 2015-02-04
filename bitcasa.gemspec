# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitcasa/version'

Gem::Specification.new do |spec|
  spec.name          = "bitcasa-sdk"
  spec.version       = Bitcasa::VERSION
 	spec.version       = '0.0.1'
  spec.authors       = ['Bitcasa Inc.']
  spec.email         = ['dstrong@bitcasa.com']
  spec.summary       = 'Bitcasa Ruby SDK'
  spec.description   = 'Bitcasa SDK for CloudFS cloud storage filesystem'
  spec.homepage      = "https://github.com/Izeltech-bitcasa/bitcasa-sdk-ruby.git"
	spec.license			 = "MIT"
  spec.files         = Dir['lib/**/*', 'tests/**/*', '.yardopts']
  spec.has_rdoc      = false
  spec.require_paths = ['lib']
	spec.platform    = Gem::Platform::RUBY
	spec.required_ruby_version = '>= 2.0.0'
	spec.add_runtime_dependency 'httpclient', '>= 2.6.0'
	spec.add_runtime_dependency 'multi_json', '>= 1.10.0'
end
