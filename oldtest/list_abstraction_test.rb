

require File.dirname(__FILE__) + '/../lib/redcar'
require 'test/unit'
require File.dirname(__FILE__) + '/test_helper'

class TestList < Test::Unit::TestCase
  def setup
    @w = Gtk::Window.new
    @w.show_all
    @w.signal_connect("destroy") { Gtk.main_quit }
  end
  
  def teardown
    @w.hide
  end
  
  def test_table1
    la = Redcar::GUI::Table.new
    @w.add(la.treeview)
    la.treeview.show
  end
  
  def test_table1_and_replace
    la = Redcar::GUI::Table.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace %w{item1 item2 item3}
  end
  
  def test_table2_and_replace
    la = Redcar::GUI::Table.new({ :columns => 
                                       [{ :type=>String, 
                                          :heading => "name"}, 
                                        { :type=>String, 
                                          :heading => "address"}],
                                       :multiple_select => true
                                     })
    @w.add(la.treeview)
    la.treeview.show
    la.replace [%w{dan flat3}, %w{mithu quakers_court}]
  end
  
  def test_selected
    la = Redcar::GUI::Table.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace [["item1"], ["item2"], ["item3"]]
    la.select(2)
    assert_equal ["item3"], la.selected
  end
  
  def test_append
    la = Redcar::GUI::Table.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace [["item1"], ["item2"], ["item3"]]
    la << ["item4"]
    la.select(3)
    assert_equal ["item4"], la.selected
  end
  
  def test_rows
    la = Redcar::GUI::Table.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace [["item1"], ["item2"], ["item3"]]
    la << ["item4"]
    assert_equal [["item1"], ["item2"], ["item3"], ["item4"]], la.rows
  end
  
  def test_list
    la = Redcar::GUI::List.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace ["item1", "item2", "item3"]
    la << "item4"
    assert_equal ["item1", "item2", "item3", "item4"], la.rows
  end
  
  def test_list_selected
    la = Redcar::GUI::List.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace ["item1", "item2", "item3"]
    la.select(2)
    assert_equal "item3", la.selected
  end
  
  def test_set_background_colour
    la = Redcar::GUI::List.new
    @w.add(la.treeview)
    la.treeview.show
    la.replace ["item1", "item2", "item3"]
    la.background_colour(0, "FF0000")
  end
  
end
