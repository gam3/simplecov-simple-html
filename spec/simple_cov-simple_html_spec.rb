
require 'test_helper'

module SimpleCov
  # Formatter namespace for SimpleCov
  module Formatter
    describe SimpleHTMLFormatter do
      describe "#initialize" do
        it 'must return instance of SimpleHTMLFormatter' do
	  SimpleHTMLFormatter.new.must_be_instance_of SimpleHTMLFormatter
	end
      end
      describe "#format" do
	before do
	  @formater = SimpleHTMLFormatter.new()
	end
	it 'should format' do
	  SimpleCov.stub(:coverage_path, 'test/temp_coverage') do
	    @mock = Minitest::Mock.new
	    @s_mock = Minitest::Mock.new
	    @s_mock.expect(:each, [])
	    @s_mock.expect(:each, [])
	    @s_mock.expect(:each_key, [])
	    @s_mock.expect(:to_a, [])
	    @s_mock.expect(:size, 4)
	    @s_mock.expect(:lines_of_code, 4)
	    @s_mock.expect(:covered_lines, 4)
	    @s_mock.expect(:missed_lines, 4)
	    @s_mock.expect(:covered_strength, 20.1)
	    @s_mock.expect(:covered_strength, 20.1)
	    @s_mock.expect(:covered_percent, 20.1)
	    @s_mock.expect(:covered_percent, 20.1)
	    @s_mock.expect(:covered_percent, 20.1)
	    @s_mock.expect(:covered_percent, 20.1)
	    @mock.expect(:groups, @s_mock)
	    @mock.expect(:groups, @s_mock)
	    @mock.expect(:source_files, @s_mock)
	    @mock.expect(:source_files, @s_mock)
	    @mock.expect(:source_files, @s_mock)
	    @mock.expect(:command_name, 'bob')
	    @mock.expect(:command_name, 'bob')
	    @mock.expect(:covered_lines, 1)
	    @mock.expect(:covered_lines, 1)
	    @mock.expect(:covered_lines, 1)
	    @mock.expect(:covered_percent, 1)
	    @mock.expect(:total_lines, 1)
	    lambda { @formater.format(@mock); }.must_output(/Coverage report generated for bob/, '')
	  end
	end
      end
      after do

      end
    end
  end
end
