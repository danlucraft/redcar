
# note: saveable_object is defined in plugins/arrangements, but it
# gives a nice representation of the panes window so we use it here.

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'
require 'fileutils'

class TestPanes < Test::Unit::TestCase
  
  def setup
    load_test_custom_files
    startup
  end
  
  def teardown
    restore_custom_files
    shutdown
  end
  
  def test_replace_in_panes
    ps = @win.panes_struct
    pane1 = ps[0]
    @win.replace_in_panes(ps, 
                          pane1, 
                          { "split" => "horizontal",
                            "left" => "foo",
                            "right" => "bar"})
    ps2 = @win.panes_struct
    assert_equal [{ "split" => "horizontal",
                    "left" => "foo",
                    "right" => "bar"}], ps2
  end
  
  def test_replace_in_panes_deep
    ps = @win.panes_struct
    pane1 = ps[0]
    @win.replace_in_panes(ps, 
                          pane1, 
                          { "split" => "horizontal",
                            "left" => "foo",
                            "right" => "bar"})
    ps2 = @win.panes_struct
    @win.replace_in_panes(ps2, 
                          "bar", 
                          { "split" => "vertical",
                            "left" => "foo2",
                            "right" => "bar2"})
    assert_equal [{ "split" => "horizontal",
                    "left" => "foo",
                    "right" => 
                    { "split" => "vertical",
                      "left" => "foo2",
                      "right" => "bar2"}}], ps2
  end
  
  def test_replace_in_panes_remove
    ps = @win.panes_struct
    pane1 = ps[0]
    @win.replace_in_panes(ps, 
                                pane1, 
                                {"split" => "horizontal",
                                  "left" => "foo",
                                  "right" => "bar",
                                  "paned" => "foopaned"})
    @win.replace_in_panes(ps, 
                                "foopaned",
                                "zanzibar")
    ps2 = @win.panes_struct
    assert_equal(["zanzibar"], ps2)
  end
  
  def test_panes_on_window_startup
    assert_equal 1, @win.size
  end
  
  def test_current_pane
    assert cp = @win.current_pane
    assert_equal @win.panes_struct[0], cp
  end
  
  def test_split_horizontal
    @win.current_pane.split_horizontal
    assert_equal 2, @win.size
    assert_equal({ "split" => "horizontal",
                   "position" => 200.0,
                   "left" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
                   "right" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" } }, @win.saveable_object)
  end
  
  def test_split_vertical
    @win.current_pane.split_vertical
    assert_equal 2, @win.size
    assert_equal({ "split" => "vertical",
                   "position" => 200.0,
                   "top" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
                   "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" } }, @win.saveable_object)
  end
  
  def test_split_horizontal_and_vertical
    @win.current_pane.split_horizontal
    @win.current_pane.split_vertical
    assert_equal 3, @win.size
    assert_equal({ "split" => "horizontal",
                   "left" => { "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" },
                   "position" => 200.0,
                   "right" => 
                   { "split" => "vertical",
                     "position" => 200.0,
                     "top" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
                     "bottom" => { "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" } }}, @win.saveable_object)
  end
  
  def test_unify_horizontal
    pane1 = @win.current_pane
    pane1.split_horizontal
    pane2 = @win.current_pane
    nt = pane2.new_tab
    nt.name = "tab in pane two"
    pane2.unify
    assert_equal({ "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" }, 
                 @win.saveable_object)
    assert_equal 1, @win.size
    assert_tabs ["first", "tab in pane two"], @win.current_pane.all
  end
  
  def test_unify_high_level
    pnd, pane1, pane2 = @win.current_pane.split_horizontal
    pnd, pane2b, pane3 = @win.current_pane.split_vertical
    assert_equal pane2, pane2b
    pnd, pane3b, pane4 = @win.current_pane.split_vertical
    assert_equal pane3, pane3b
    pane1.first.name = "tab1"
    pane2.new_tab.name = "tab2"
    pane3.new_tab.name = "tab3"
    pane4.new_tab.name = "tab4"
    
    @win.panes_struct[0]["left"].unify
    assert_equal({ "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" }, 
                 @win.saveable_object)
    assert_equal 1, @win.size
    assert_tabs ["tab1", "tab2", "tab3", "tab4"], pane1.all
  end
  
  def test_unify_high_level_2
    arr = {"left"=>{ "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
      "split"=>"horizontal",
      "position"=>0.15,
      "right"=>
      {"left"=>
        {"bottom"=>{ "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" },
          "split"=>"vertical",
          "position"=>0.784926470588235,
          "top"=>{ "types" => ["Redcar::TextTab"], "tab_position" => "top", "tab_angle" => "horizontal" }},
        "split"=>"horizontal",
        "position"=>0.949554896142433,
        "right"=>{ "types" => [], "tab_position" => "top", "tab_angle" => "horizontal" }}}
    @win.apply_arrangement arr

    assert @win.panes_struct[0]["right"]["left"]["top"].unify
  end
  
  def test_new_tab
    assert_equal 1, @win.current_pane.count
    @win.current_pane.new_tab
    assert_equal 2, @win.current_pane.count
    assert_tabs ["first", "#new1"], @win.current_pane.all
  end
  
end
