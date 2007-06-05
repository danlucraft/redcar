
class Test::Unit::TestCase
  def startup(options={:output => :silent})
    Redcar.startup(options)
    @win = Redcar.current_window
    @win.show_all
    (@win.panes[0].first||null).name = "first"
  end
  
  def run_gtk
    Gtk.main_iteration while Gtk.events_pending?
  end
  
  def load_test_custom_files
    FileUtils.mv(Redcar.ROOT_PATH + "/custom/arrangements.yaml",
                 Redcar.ROOT_PATH + "/custom/arrangements.yaml.backup")
    FileUtils.cp(Redcar.ROOT_PATH + "/test/fixtures/arrangements.yaml",
                 Redcar.ROOT_PATH + "/custom/arrangements.yaml")
  end
  
  def restore_custom_files
    FileUtils.mv(Redcar.ROOT_PATH + "/custom/arrangements.yaml.backup",
                 Redcar.ROOT_PATH + "/custom/arrangements.yaml")
  end
  
  def shutdown
    Redcar.windows = []
    @win.hide_all
  end
  
  def assert_tabs(exp, tabs)
    assert_equal exp.length, tabs.length
    exp.zip(tabs) do |exp_text, tab|
      assert_equal exp_text, tab.name
    end
  end
end
