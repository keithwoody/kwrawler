# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kwrawler/version'

Gem::Specification.new do |spec|
  spec.name          = "kwrawler"
  spec.version       = Kwrawler::VERSION
  spec.authors       = ["Keith Woody"]
  spec.email         = ["keith.woody@gmail.com"]
  spec.description   = %q{A gem to crawl a single domain and output a sitemap}
  spec.summary       = %q{Krawler.crawl( url ) => sitemap}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "guard-rspec"

  spec.add_runtime_dependency "nokogiri"
end
