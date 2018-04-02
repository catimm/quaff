# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/sparkpost/version'

Gem::Specification.new do |spec|
  spec.name          = 'sparkpost'
  spec.version       = SparkPost::VERSION
  spec.authors       = ['SparkPost', 'Aimee Knight', 'Mohammad Hossain']
  spec.email         = 'developers@sparkpost.com'
  spec.summary       = 'SparkPost Ruby API client'
  spec.homepage      = 'https://github.com/SparkPost/ruby-sparkpost'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'http', '0.9.8'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '<11'
  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency 'simplecov', '~> 0.11.1'
  spec.add_development_dependency 'webmock', '~> 1.22.3'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop', '~> 0.37.2'
end
