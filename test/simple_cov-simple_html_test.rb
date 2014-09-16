require 'test_helper'

class TestSimpleCovSimpleHtml < MiniTest::Unit::TestCase
  def test_defined
    assert defined?(SimpleCov::Formatter::SimpleHTMLFormatter)
    assert defined?(SimpleCov::Formatter::SimpleHTMLFormatter::VERSION)
  end
end




