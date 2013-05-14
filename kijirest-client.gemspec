# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kijirest/version'

Gem::Specification.new do |spec|
  spec.name          = "kijirest-client"
  spec.version       = KijiRest::VERSION
  spec.authors       = ["wibidata"]
  spec.email         = ["dev@kiji.org"]
  spec.description   = %q{Client for the KIJI REST server}
  spec.summary       = %q{Client for the KIJI REST server}
  spec.homepage      = "http://www.kiji.org"
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
