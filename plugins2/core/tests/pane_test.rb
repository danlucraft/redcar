
module Redcar
  module PluginTests
    class PaneTest < Test::Unit::TestCase
      def setup
        Redcar::App.close_window(win, false)
        Redcar::App.new_window
      end
      
      def teardown
        win.tabs.each(&:close)
      end
      
      def test_tabs
        tab1 = win.new_tab(Tab, Gtk::Label.new("foo"))
        tab2 = win.new_tab(Tab, Gtk::Label.new("bar"))
        tab3 = win.new_tab(Tab, Gtk::Label.new("baz"))
        assert_equal 3, win.panes.first.tabs.length
        tab3.close
        assert_equal 2, win.panes.first.tabs.length
        tab1.close
        assert_equal 1, win.panes.first.tabs.length
        tab2.close
        assert_equal 0, win.panes.first.tabs.length
      end
      
      def test_active_tab
        tab1 = win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab1, win.panes.first.active_tab
        tab2 = win.new_tab(Tab, Gtk::Label.new("bar"))
        assert_equal tab1, win.panes.first.active_tab
        win.panes.first.focus_tab(tab2)
        assert_equal tab2, win.panes.first.active_tab
      end

      def test_move_tab
        win.new_tab(Tab, Gtk::Label.new("foo"))
        win.new_tab(Tab, Gtk::Label.new("bar"))
        win.split_horizontal(win.panes.first)
        p1 = win.panes.last
        p2 = win.panes.first
        assert_equal 2, p1.tabs.length
        assert_equal 0, p2.tabs.length
        p1.move_tab(p1.tabs.first, p2)
        assert_equal 1, p1.tabs.length
        assert_equal 1, p2.tabs.length
      end
    end
  end
end
