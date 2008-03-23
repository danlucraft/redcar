
module Redcar
  module PluginTests
    class WindowTest < Test::Unit::TestCase
      
      def setup
        Redcar::App.close_window(win, false)
        Redcar::App.new_window
      end
      
      def teardown
        win.tabs.each(&:close)
      end
      
      def test_no_tabs_on_startup
        assert_equal 0, win.tabs.length
      end
      
      def test_one_pane_on_startup
        assert_equal 1, win.panes.length
        assert_equal 1, win.notebooks_panes.length
      end
      
      def test_split_horizontal
        win.new_tab(Tab, Gtk::Label.new("foo"))
        win.split_horizontal(win.panes.first)
        assert_equal 2, win.panes.length
        assert_equal 1, win.tabs.length
        assert_equal 2, win.notebooks_panes.length
      end
      
      def test_split_horizontal_no_tabs
        win.split_horizontal(win.panes.first)
        assert_equal 2, win.panes.length
        assert_equal 0, win.tabs.length
        assert_equal 2, win.notebooks_panes.length
      end
      
      def test_split_vertical
        win.new_tab(Tab, Gtk::Label.new("foo"))
        win.split_vertical(win.panes.first)
        assert_equal 2, win.panes.length
        assert_equal 1, win.tabs.length
        assert_equal 2, win.notebooks_panes.length
      end
      
      def test_bunch_of_splits
        win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal 1, win.panes.length
        win.split_vertical(win.panes.first)
        assert_equal 2, win.panes.length
        win.split_horizontal(win.panes.first)
        assert_equal 3, win.panes.length
        win.split_vertical(win.panes.first)
        assert_equal 4, win.panes.length
        win.split_horizontal(win.panes.first)
        win.unify_all
        assert_equal 1, win.panes.length
        assert_equal 1, win.tabs.length
        assert_equal 1, win.notebooks_panes.length
      end
      
      def test_focussed_tab
        tab = win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab, win.focussed_tab
      end
      
      def test_tabs_open_in_the_background
        tab1 = win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab1, win.focussed_tab
        tab2 = win.new_tab(Tab, Gtk::Label.new("bar"))
        assert_equal tab1, win.focussed_tab
      end
      
      def test_focus_tab
        tab1 = win.new_tab(Tab, Gtk::Label.new("foo"))
        tab2 = win.new_tab(Tab, Gtk::Label.new("bar"))
        tab2.focus
        assert_equal tab2, win.focussed_tab
        tab1.focus
        assert_equal tab1, win.focussed_tab
      end
      
      def test_unify_keeps_tabs
        win.new_tab(Tab, Gtk::Label.new("foo"))
        win.new_tab(Tab, Gtk::Label.new("bar"))
        win.new_tab(Tab, Gtk::Label.new("baz"))
        win.split_horizontal(win.panes.first)
        win.panes.last.move_tab(win.panes.last.tabs.first, win.panes.first)
        assert_equal 3, win.tabs.length
        assert_equal [1, 2], win.panes.map{|p| p.tabs.length}
        win.unify_all
        assert_equal 3, win.tabs.length
        assert_equal [3], win.panes.map{|p| p.tabs.length}
      end
    end
  end
end
  
