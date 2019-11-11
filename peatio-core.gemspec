# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "peatio/core/version"

Gem::Specification.new do |spec|
  spec.name = "peatio-core"
  spec.version = Peatio::Core::VERSION
  spec.authors = ["Louis B.", "Camille M."]
  spec.email = ["lbellet@heliostech.fr"]

  spec.summary = "Peatio is a gem for running critical core services"
  spec.description = "Peatio gem contains microservices and command line tools"
  spec.homepage = "https://www.peatio.tech"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", "> 5.2", "<= 6.0.0"
  spec.add_dependency "bunny"
  spec.add_dependency "jwt"
  spec.add_dependency "thin"

  spec.add_development_dependency "bump"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "irb"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop-github"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"
end
