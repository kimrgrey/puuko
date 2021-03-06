
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "puuko/version"

Gem::Specification.new do |spec|
  spec.name          = "puuko"
  spec.version       = Puuko::VERSION
  spec.authors       = ["Sergey Tsvetkov"]
  spec.email         = ["sergey.a.tsvetkov@gmail.com"]

  spec.summary       = "Everything I would like to take with me into the next journey through Web with Ruby"
  spec.description   = "This library is a set of things collected to simplify development of HTTP microservices using Ruby"
  spec.homepage      = "https://github.com/kimrgrey/puuko"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "sinatra", "~> 2.0.5"
  spec.add_dependency "sinatra-contrib",  "~> 2.0.5"
end
