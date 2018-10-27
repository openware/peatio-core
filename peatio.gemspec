
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "peatio/version"

Gem::Specification.new do |spec|
  spec.name = "peatio"
  spec.version = Peatio::VERSION
  spec.authors = ["Louis B.", "Camille M."]
  spec.email = ["lbellet@heliostech.fr"]

  spec.summary = %q{Peatio is a gem for running critical core services}
  spec.description = %q{Peatio gem contains microservices and command line tools}
  spec.homepage = "https://www.peatio.tech"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "clamp"
  spec.add_dependency "amqp"
  spec.add_dependency "eventmachine"
  spec.add_dependency "em-websocket"
  spec.add_dependency "mysql2"
  spec.add_dependency "jwt"
  spec.add_dependency "bunny"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bump"
  spec.add_development_dependency "em-spec"
  spec.add_development_dependency "em-websocket-client"
  spec.add_development_dependency "bunny-mock"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop-github"
end
