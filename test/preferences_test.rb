
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestPreferences < Test::Unit::TestCase
  include Redcar
  
  def setup
  end
  
  def teardown
    Redcar["preferences/Example/Name/type"] = "string"
    Redcar["preferences/Example/Name/value"] = "Example Plugin"
  end
  
  class PluginExample
    include Redcar::Preferences
    preferences "Example" do |p|
      p.add "Name", :type => :string, :default => "Example Plugin"
    end
  end
  
  class PluginExample2
    include Redcar::Preferences
    preferences "Example" do |p|
      p.add "Colour", :type => :string, :default => "Green"
    end
  end
  
  def test_001_make
    assert_equal "string", Redcar["preferences/Example/Name/type"]
    assert_equal "Example Plugin", Redcar["preferences/Example/Name/value"]
    assert_equal "Example Plugin", PluginExample.Preferences["Name"]
  end
  
  def test_002_change
    PluginExample.Preferences["Name"] = "New Name"
    assert_equal "New Name", Redcar["preferences/Example/Name/value"]
    assert_equal "New Name",  PluginExample.Preferences["Name"]
  end
  
  def test_003_change
    assert_equal "Green", Redcar["preferences/Example/Colour/value"]
  end
  
  def test_004_names
    assert Redcar::Preferences.plugin_names.include? "Example"
  end
  
end
