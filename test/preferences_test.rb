
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestPreferences < Test::Unit::TestCase
  include Redcar
  
  def setup
  end
  
  def teardown
    Redcar.clear("preferences/Example/Name/type")
    Redcar.clear("preferences/Example/Name/value")
  end
  
  class PluginExample
    include Redcar::Preferences
    preferences "Example" do |p|
      p.add "Name", :type => :string, :default => "Example Plugin"
    end
  end
  
  def test_001_preferences_group
    assert_equal "string", Redcar["preferences/Example/Name/type"]
    assert_equal "Example Plugin", Redcar["preferences/Example/Name/value"]
    assert_equal "Example Plugin", PluginExample.Preferences["Name"]
  end
  
  def test_002_preferences_group
    PluginExample.Preferences["Name"] = "New Name"
    assert_equal "New Name", Redcar["preferences/Example/Name/value"]
    assert_equal "New Name",  PluginExample.Preferences["Name"]
  end
end
