
module Redcar
  module PluginTests
    class WindowTest < Test::Unit::TestCase

      def setup
        Redcar::App.close_window(Redcar.win, false)
        Redcar::App.new_window
      end

      def teardown
        Redcar.win.tabs.each(&:close)
      end

      def test_no_tabs_on_startup
        assert_equal 0, Redcar.win.tabs.length
      end

      def test_one_pane_on_startup
        assert_equal 1, Redcar.win.panes.length
        assert_equal 1, Redcar.win.notebooks_panes.length
      end

      def test_split_horizontal
        Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        assert_equal 2, Redcar.win.panes.length
        assert_equal 1, Redcar.win.tabs.length
        assert_equal 2, Redcar.win.notebooks_panes.length
      end

      def test_split_horizontal_no_tabs
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        assert_equal 2, Redcar.win.panes.length
        assert_equal 0, Redcar.win.tabs.length
        assert_equal 2, Redcar.win.notebooks_panes.length
      end

      def test_split_vertical
        Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        Redcar.win.split_vertical(Redcar.win.panes.first)
        assert_equal 2, Redcar.win.panes.length
        assert_equal 1, Redcar.win.tabs.length
        assert_equal 2, Redcar.win.notebooks_panes.length
      end

      def test_bunch_of_splits
        Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal 1, Redcar.win.panes.length
        Redcar.win.split_vertical(Redcar.win.panes.first)
        assert_equal 2, Redcar.win.panes.length
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        assert_equal 3, Redcar.win.panes.length
        Redcar.win.split_vertical(Redcar.win.panes.first)
        assert_equal 4, Redcar.win.panes.length
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        Redcar.win.unify_all
        assert_equal 1, Redcar.win.panes.length
        assert_equal 1, Redcar.win.tabs.length
        assert_equal 1, Redcar.win.notebooks_panes.length
      end

      def test_focussed_tab
        tab = Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab, Redcar.win.focussed_tab
      end

      def test_tabs_open_in_the_background
        tab1 = Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        assert_equal tab1, Redcar.win.focussed_tab
        tab2 = Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        assert_equal tab1, Redcar.win.focussed_tab
      end

      def test_focus_tab
        tab1 = Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        tab2 = Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        tab2.focus
        assert_equal tab2, Redcar.win.focussed_tab
        tab1.focus
        assert_equal tab1, Redcar.win.focussed_tab
      end

      def test_unify_keeps_tabs
        Redcar.win.new_tab(Tab, Gtk::Label.new("foo"))
        Redcar.win.new_tab(Tab, Gtk::Label.new("bar"))
        Redcar.win.new_tab(Tab, Gtk::Label.new("baz"))
        Redcar.win.split_horizontal(Redcar.win.panes.first)
        Redcar.win.panes.last.move_tab(Redcar.win.panes.last.tabs.first, Redcar.win.panes.first)
        assert_equal 3, Redcar.win.tabs.length
        assert_equal [1, 2], Redcar.win.panes.map{|p| p.tabs.length}
        Redcar.win.unify_all
        assert_equal 3, Redcar.win.tabs.length
        assert_equal [3], Redcar.win.panes.map{|p| p.tabs.length}
      end
    end
  end
end

