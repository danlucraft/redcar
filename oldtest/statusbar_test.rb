
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'
require 'fileutils'

class TestStatusbar < Test::Unit::TestCase

  def setup
    startup
    Redcar.StatusBar.clear_histories
  end
  
  def teardown
    shutdown
  end

  def test_status_equals
    Redcar.StatusBar.main = "foobar"
    assert "foobar", Redcar.StatusBar.main
  end
  
  def test_status_history
    Redcar.StatusBar.main = "foo"
    Redcar.StatusBar.main = "bar"
    Redcar.StatusBar.main = "baz"
    assert ["bar", "foo"], Redcar.StatusBar.main_history(2)
  end
end
