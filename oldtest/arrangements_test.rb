
require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'
require 'fileutils'

class TestArrangements < Test::Unit::TestCase

  def setup
    startup
    load_test_custom_files
  end
  
  def teardown
    restore_custom_files
    shutdown
  end

  def test_saveable_object1
    assert_equal({ "types" => ["Redcar::TextTab"], 
                   "tab_position" => "top", 
                   "tab_angle" => "horizontal" }, @win.saveable_object)
  end

  def test_saveable_object2
    pane1, pane2 = @win.current_pane.split_horizontal
    pane2b, pane3 = @win.current_pane.split_vertical
    assert_equal({ "split" => "horizontal", 
                   "left" => { 
                     "types" => ["Redcar::TextTab"], 
                     "tab_position" => "top", 
                     "tab_angle" => "horizontal" }, 
                   "position" => 200.0,
                   "right" => {
                     "split" => "vertical", 
                     "position" => 200.0,
                     "top" => { 
                       "types" => [], 
                       "tab_position" => "top", 
                       "tab_angle" => "horizontal" }, 
                     "bottom" => { 
                       "types" => [], 
                       "tab_position" => "top", 
                       "tab_angle" => "horizontal" }
                   }
                 }, @win.saveable_object)
  end
  
  def test_saveable_object3
    pane1, pane2 = @win.current_pane.split_horizontal
    pane2b, pane3 = @win.current_pane.split_vertical
    Redcar.current_pane.new_tab
    Redcar.current_pane.new_tab
    Redcar.current_pane.new_tab
    assert_equal({ "split" => "horizontal", 
                   "left" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }, 
                   "position" => 200.0,
                   "right" => {
                     "split" => "vertical", 
                     "position" => 200.0,
                     "top" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }, 
                     "bottom" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" }
                   }
                 }, @win.saveable_object)
  end
   
  def test_saveable_object4
    Redcar.current_pane.new_tab
    Redcar.current_pane.new_tab
    Redcar.current_pane.new_tab
    @win.current_pane.split_horizontal
    assert_equal({ "split" => "horizontal", 
                   "left" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" }, 
                   "position" => 200.0,
                   "right" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
                 }, @win.saveable_object)
  end
   
  def test_apply_arrangement
    @win.current_pane.new_tab
    @win.current_pane.split_vertical
    arr = { 
      "split" => "horizontal",
      "position" => 0.0,
      "left" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
      "right" => {
        "split" => "vertical",
        "position" => 0.0,
        "top" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
        "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
      }
    }
    @win.apply_arrangement arr
    assert_equal(arr, @win.saveable_object)
    
    assert_tabs ["first", "#new1"], @win.panes_struct[0]["right"]["top"].all
  end
  
  def test_apply_arrangement2
    @win.current_pane.new_tab
    @win.current_pane.new_tab
    pane1, pane2 = @win.current_pane.split_horizontal
    pane2b, pane3 = @win.current_pane.split_vertical
    
    arr = {
      "split" => "horizontal",
      "position" => 0.0,
      "left" => {
        "split" => "vertical",
        "position" => 0.0,
        "top" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
        "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
      },
      "right" => {
        "split" => "vertical",
        "position" => 0.0,
        "top" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
        "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
      }
    }
      
    @win.apply_arrangement arr
    assert_equal(arr, @win.saveable_object)
    assert_tabs ["first", "#new1", "#new2"], @win.panes_struct[0]["right"]["top"].all
  end
  
#   def test_load_arrangements_if_not_found
#     FileUtils.mv(Redcar.CUSTOM_DIR + "/arrangements.yaml",
#                  Redcar.CUSTOM_DIR + "/arrangements.yaml.backup")
    
#     assert !File.exists?(Redcar.CUSTOM_DIR + "/arrangements.yaml")
#     assert_equal({"default" => Redcar::DEFAULT_ARRANGEMENT}, Redcar.arrangements)
#     assert File.exists?(Redcar.CUSTOM_DIR + "/arrangements.yaml")
   
#     FileUtils.mv(Redcar.CUSTOM_DIR + "/arrangements.yaml.backup",
#                  Redcar.CUSTOM_DIR + "/arrangements.yaml")
#   end
  
  def test_load_arrangements
    arr = {
      "split" => "horizontal",
      "position" => 0.25,
      "left" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
      "right" => {
        "split" => "vertical",
        "position"=>0.713235294117647,
        "top" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
        "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
      }
    }
    assert_equal Redcar::DEFAULT_ARRANGEMENT, Redcar.arrangements(true)["default"]
    assert_equal arr, Redcar.arrangements["rails"]
  end
  
  def test_update_arrangements
    assert_equal Hash, Redcar.arrangements.class
  end
  
  def test_tab_get_type
    assert_equal "Redcar::TextTab", Redcar::Arrangements.get_type(Redcar.current_tab)
  end
  
  def test_places_tab_correctly_on_creation
    arr = {
      "split" => "horizontal",
      "position" => 0.25,
      "left" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
      "right" => {
        "split" => "vertical",
        "position"=>0.713235294117647,
        "top" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
        "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }
      }
    }
    @win.apply_arrangement arr
    Redcar.current_pane.new_tab
    assert_equal 1, @win.panes_struct[0]["right"]["top"].all.length
  end
end
