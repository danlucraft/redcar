
module Redcar
  module PluginTests
    class PaneTest < Test::Unit::TestCase
      def setup
        Redcar::App.close_window(Redcar.win, false)
        Redcar::App.new_window
      end

      def teardown
        Redcar.win.tabs.each(&:close)
      end

      def test_tabs
        tab1 = Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        tab2 = Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        tab3 = Redcar.win.new_tab(Tab, Gtk::Label.new("baz"))
        assert_equal 3, Redcar.win.panes.first.tabs.length
        tab3.close
        assert_equal 2, Redcar.win.panes.first.tabs.length
        tab1.close
        assert_equal 1, Redcar.win.panes.first.tabs.length
        tab2.close
        assert_equal 0, Redcar.win.panes.first.tabs.length
      end

      def test_active_tab
        tab1 = Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab1, Redcar.win.panes.first.active_tab
        tab2 = Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        assert_equal tab1, Redcar.win.panes.first.active_tab
        tab2.focus
        assert_equal tab2, Redcar.win.panes.first.active_tab
      end

      def test_move_tab
        Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        p1 = Redcar.win.panes.last
        p2 = Redcar.win.panes.first
        assert_equal 2, p1.tabs.length
        assert_equal 0, p2.tabs.length
        p1.move_tab(p1.tabs.first, p2)
        assert_equal 1, p1.tabs.length
        assert_equal 1, p2.tabs.length
      end
    end
  end
end
