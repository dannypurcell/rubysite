# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubysite/version'

Gem::Specification.new do |spec|
  spec.name          = "rubysite"
  spec.version       = Rubysite::VERSION
  spec.authors       = ["Danny Purcell"]
  spec.email         = ["d.purcell.jr+rubysite@gmail.com"]
  spec.description   = %q{Provides web access for methods in an including module. Turn a library into a web service by simply including Rubysite.}
  spec.summary       = %q{Turn a library into a web service by simply including Rubysite.}
  spec.homepage      = "http://github.com/dannypurcell/Rubysite"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "rake"
  spec.add_dependency 'rubycom'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency 'kramdown'
end
