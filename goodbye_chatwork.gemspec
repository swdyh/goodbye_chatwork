# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goodbye_chatwork/version'

Gem::Specification.new do |spec|
  spec.name          = "goodbye_chatwork"
  spec.version       = GoodbyeChatwork::VERSION
  spec.authors       = ["swdyh"]
  spec.email         = ["youhei@gmail.com"]
  spec.summary       = %q{export Chatwork(chatwork.com) logs}
  spec.description   = %q{This is Chatwork(chatwork.com) log exporter. This can be used also when you can not use API.}
  spec.homepage      = "https://github.com/swdyh/goodbye_chatwork"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "faraday-cookie_jar"
end
