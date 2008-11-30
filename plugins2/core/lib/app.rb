
# This is the Redcar API documentation for plugin authors and developers.
# For documentation regarding the day to day use of Redcar as an editor
# please refer to http://www.redcaride.com/doc/user_guide/index.html.
module Redcar
  # Application wide configuration. App manages Redcar::Windows (of which
  # there may only be one currently).
  module App
    def self.[]=(name, val)
      bus("/redcar/appdata/#{name}").data = val
    end

    def self.[](name)
      if slot = bus("/redcar/appdata/#{name}", true)
        slot.data
      end
    end

    def self.load
      Hook.register :open_window
      Hook.register :close_window
      FreeBASE::Properties.new("Redcar Application Data",
                               Redcar::VERSION,
                               bus('/redcar/appdata'),
                               Redcar::ROOT + "/custom/appdata.yaml")
      Redcar::App[:execution] = (Redcar::App[:execution]||0) + 1
      create_logger
    end

    # Quits the application. All plugins are stopped first.
    def self.quit
      unless @gtk_quit
        @logger.info "system shutdown"
        bus["/system/shutdown"].call(nil)
        Gtk.main_quit
      end
      @gtk_quit = true
    end

    # Creates a new window.
    def self.new_window(focus = true)
      return nil if @window
      @logger.info "new window"
      Hook.trigger :open_window do
        @window = Redcar::Window.new
      end
    end

    # Returns an array of all Redcar windows.
    def self.windows
      [@window]
    end

    # Returns the currently focussed window.
    def self.focussed_window
      @window
    end

    # Closes the given window. If close_if_no_win is true (the default)
    # then Redcar will quit if there are no more windows.
    def self.close_window(window, close_if_no_win=true)
      is_win = !windows.empty?
      if window
        Hook.trigger :close_window do
          window.panes.each {|pane| pane.tabs.each {|tab| tab.close} }
          @window = nil if window == @window
          window.hide_all if window
        end
      end
      quit if close_if_no_win and is_win
    end

    # Closes all Redcar windows. If close_if_no_win is true (the
    # default) then Redcar will quit.
    def self.close_all_windows(close_if_no_win=true)
      is_win = !windows.empty?
      close_window(@window, close_if_no_win)
      quit if close_if_no_win and is_win
    end

    # Load a Marhshalled object from the cache.
    def self.with_cache(dir, name)
      unless cache_dir = Redcar::ROOT + "/cache/"
        raise "called App.with_cache without a cache_dir"
      end
      unless File.exist?(cache_dir + "#{dir}/")
        FileUtils.mkdir cache_dir + "#{dir}/"
      end
      if File.exist?(cache_dir + "#{dir}/#{name}.dump")
        str = File.read(cache_dir + "#{dir}/#{name}.dump")
        obj = Marshal.load(str)
      else
        obj = yield
        File.open(cache_dir + "#{dir}/#{name}.dump", "w") do |fout|
          fout.puts Marshal.dump(obj)
        end
        obj
      end      
    end
    
    def self.clipboard
      Gtk::Clipboard.get(Gdk::Atom.intern("CLIPBOARD"))
    end

    ENV_VARS =  %w(RUBYLIB TM_RUBY TM_BUNDLE_SUPPORT TM_CURRENT_LINE)+
      %w(TM_CURRENT_LINE TM_LINE_INDEX TM_LINE_NUMBER TM_SELECTED_TEXT)+
      %w(TM_DIRECTORY TM_FILEPATH TM_SCOPE TM_SOFT_TABS TM_SUPPORT_PATH)+
      %w(TM_TAB_SIZE TM_FILENAME)

    def self.set_environment_variables
      ENV_VARS.each do |var|
        ENV[var] = nil
      end

      ENV['RUBYLIB'] = (ENV['RUBYLIB']||"")+":textmate/Support/lib"

      ENV['TM_RUBY'] = "/usr/bin/ruby"
      if @bundle_uuid
        ENV['TM_BUNDLE_SUPPORT'] = Redcar.image[@bundle_uuid][:directory]+"Support"
      end
      if Redcar.tab and Redcar.tab.class.to_s == "Redcar::EditTab"
        ENV['TM_CURRENT_LINE'] = Redcar.doc.get_line
        ENV['TM_LINE_INDEX'] = Redcar.doc.cursor_line_offset.to_s
        ENV['TM_LINE_NUMBER'] = (Redcar.doc.cursor_line+1).to_s
        if Redcar.doc.selection?
          ENV['TM_SELECTED_TEXT'] = Redcar.doc.selection
        end
        if Redcar.tab.filename
          ENV['TM_DIRECTORY'] = File.dirname(Redcar.tab.filename)
          ENV['TM_FILEPATH'] = Redcar.tab.filename
          ENV['TM_FILENAME'] = File.basename(Redcar.tab.filename)
        end
        if Redcar.doc.cursor_scope
          ENV['TM_SCOPE'] = Redcar.doc.cursor_scope.hierarchy_names(true)
        end
      end
      ENV['TM_SOFT_TABS'] = "YES"
      ENV['TM_SUPPORT_PATH'] = textmate_share_dir + "Support"
      ENV['TM_TAB_SIZE'] = "2"
    end
    
    def self.textmate_share_dir
      if File.exist?("/usr/local/share/textmate")
        "/usr/local/share/textmate/"
      elsif File.exist?("/usr/share/textmate/")
        "/usr/share/textmate/"
      else
        raise "Can't find the textmate share directory in /usr/local/share/textmate.'"
      end
    end
  end
end

# Some useful methods for finding the currently focussed objects.
module Redcar
  # The current or last focussed Document.
  def self.doc
    if tab
      tab.document
    end
  end

  # The current or last focussed Tab
  def self.tab
    if win
      win.focussed_tab
    end
  end

  # The current or last focussed Window
  def self.win
    Redcar::App.focussed_window
  end
end
