

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestApplication < Test::Unit::TestCase
  def setup
    startup
  end
  def teardown
    shutdown
  end
  
  def test_event_hook
    Redcar.hook :test_event_hook do |obj|
      obj << "1"
    end
    str = ""
    Redcar.event :test_event_hook, str
    assert_equal "1", str    
  end
  
  def test_event_multi_hook
    Redcar.hook :test_event_multi_hook, :test_event_multi_hook2 do |obj|
      obj << "1"
    end
    str = ""
    Redcar.event :test_event_multi_hook, str
    Redcar.event :test_event_multi_hook2, str
    assert_equal "11", str    
  end
  
  def test_event_before
    Redcar::App.output_style = :chatty
    Redcar.hook :before_event_ba do |obj|
      obj << "2"
    end
    str = ""
    done = false
    Redcar.event :event_ba, str do 
      done = true
    end
    assert done
    assert_equal "2", str
  end
end
