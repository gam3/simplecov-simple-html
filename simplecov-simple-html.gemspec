# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'simplecov-simple-html/version'

Gem::Specification.new do |s|
  s.name        = "simplecov-simple-html"
  s.version     = SimpleCov::Formatter::SimpleHTMLFormatter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["G. Allen Morris III"]
  s.email       = ["gam3@gam3.net"]
  s.homepage    = "https://github.com/gam3/simplecov-simple-html"
  s.summary     = %Q{Simple HTML formatter for SimpleCov code coverage tool}
  s.description = %Q{Simple (non-javascript) HTML formatter for SimpleCov code coverage tool}

  s.rubyforge_project = "simplecov-simple-html"
  
  s.add_development_dependency 'rake'
  s.add_development_dependency 'sprockets'
  s.add_development_dependency 'sass'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
