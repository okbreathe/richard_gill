# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = "richard_gill"
  spec.version       = RichardGill::VERSION
  spec.authors       = ["Asher"]
  spec.email         = ["asher@okbreathe.com"]

  spec.summary       = %q{Simple Versioning for DataMapper Models}
  spec.description   = %q{Simple Versioning for DataMapper Models}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "thoughtbot-shoulda", ">= 0"
  spec.add_dependency "dm-core", ">= 1.0.0"
  spec.add_dependency "dm-types" , ">= 1.0.0"
  spec.add_dependency "dm-timestamps" , ">= 1.0.0"
  spec.add_dependency "dm-aggregates", ">= 1.0.0"
  spec.add_dependency "activesupport", ">=2.3.5"
end
