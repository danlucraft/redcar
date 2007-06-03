
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestTooltip < Test::Unit::TestCase
  def setup
    startup
  end
  
  def test_create_window
    Redcar::Tooltip.new
  end
end
