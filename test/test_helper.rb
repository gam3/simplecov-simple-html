require 'simplecov'
require 'simplecov-simple-html'


SimpleCov.start do
  add_filter "/test/*_test.rb"
  add_filter "/spec/"
  coverage_dir 'test/coverage'
  formatter SimpleCov::Formatter::SimpleHTMLFormatter
  command_name 'MiniTest::Unit'
  add_group "Models", 'test/lib/model/*'
  add_group "Tests", 'test/lib/text/*'
end

gem 'minitest'
require 'minitest/autorun'

