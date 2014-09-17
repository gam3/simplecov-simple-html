
require 'test_helper'

require 'test'
require 'model/model'
require 'text/text'

class TestSimpleCovSimpleHtmlCoverage < MiniTest::Unit::TestCase
  def test_test
    assert_output("test\n", '') do 
      Test::Bob.test
    end
  end
  def test_initial
    assert_output("#initialize\n#test\n", '') do 
      Test::Bob.new.test
    end
  end
end




