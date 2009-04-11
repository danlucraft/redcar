
# This is the Redcar API documentation for Redcar developers and plugin 
# authors.
# For documentation regarding the day to day use of Redcar as an editor
# please refer to http://www.redcaride.com/doc/user_guide/index.html.
module Redcar
  # Application wide configuration. App manages Redcar::Windows (of which
  # there may only be one currently).
  module App
    include FreeBASE::DataBusHelper

    # Set key-value pair to be stored in the databus. This
    # is persistent across application instances.
    def self.[]=(key, val)
      bus("/redcar/appdata/#{key}").data = val
    end
    
    # Retrieve a value associated with this key. This
    # may have been set in a previous instance of the application.
    def self.[](name)
      if slot = bus("/redcar/appdata/#{name}", true)
        slot.data
      end
    end
    
    def self.home_dot_dir
      dir = File.expand_path("~/.redcar/")
      FileUtils.mkdir(dir) unless File.exist?(dir)
      dir
    end
    
    def self.load
      Hook.register :open_window
      Hook.register :close_window
      FreeBASE::Properties.new("Redcar Application Data",
                               Redcar::VERSION,
                               bus('/redcar/appdata'),
                               home_dot_dir + "/appdata.yaml")
      Redcar::App[:execution] = (Redcar::App[:execution]||0) + 1
    end
    
    # Quits the application. All plugins are stopped first.
    def self.quit
      puts "quit"
      windows.each do |w|
        close_window(w, false)
      end
      unless @gtk_quit
        log.info "[App] system shutdown"
        bus["/system/shutdown"].call(nil)
        Gtk.main_quit
      end
      @gtk_quit = true
    end

    # Application-wide logger. Plugins may use this for
    # logging.
    def self.log
      if ARGV.include?("--log") or 
          (defined?(Redcar::Testing::InternalCucumberRunner) and
          Redcar::Testing::InternalCucumberRunner.in_cucumber_process)
        if ENV["REDCAR_DEBUG"]
          @logger ||= Logger.new(STDOUT)
        else
          @logger ||= Logger.new(Redcar::ROOT + "/redcar.log")
        end
      else
        @logger ||= Logger.new(nil)
      end
    end

    # Creates a new window.
    def self.new_window(focus = true)
      return nil if @window
      log.info "[App] new window"
      Hook.trigger :open_window do
        @window = Redcar::Window.new
      end
    end

    # Returns an array of all Redcar windows.
    def self.windows
      [@window].compact
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

    # Load a Marshalled object from the cache.
    def self.with_cache(dir, name)
      cache_dir = Redcar::ROOT + "/cache/"
      unless File.exist?(cache_dir)
        FileUtils.mkdir(cache_dir)
      end
      cache_dir = cache_dir + "0_2/"
      unless File.exist?(cache_dir)
        FileUtils.mkdir(cache_dir)
      end
      
      unless File.exist?(cache_dir + "#{dir}/")
        FileUtils.mkdir cache_dir + "#{dir}/"
      end
      cache_file = cache_dir + "/#{dir}/#{name}.dump"
      if File.exist?(cache_file)
        obj = Marshal.load(File.read(cache_file))
      else
        obj = yield
        File.open(cache_file, "w") do |fout|
          fout.puts Marshal.dump(obj)
        end
      end
      obj
    end
    
    def self.clipboard
      Gtk::Clipboard.get(Gdk::Atom.intern("CLIPBOARD"))
    end

    ENV_VARS =  %w(RUBYLIB TM_RUBY TM_BUNDLE_SUPPORT TM_CURRENT_LINE)+
      %w(TM_CURRENT_LINE TM_LINE_INDEX TM_LINE_NUMBER TM_SELECTED_TEXT)+
      %w(TM_DIRECTORY TM_FILEPATH TM_SCOPE TM_SOFT_TABS TM_SUPPORT_PATH)+
      %w(TM_TAB_SIZE TM_FILENAME)

    def self.set_environment_variables(bundle=nil)
      ENV_VARS.each do |var|
        ENV[var] = nil
      end
      @env_variables ||= []
      @env_variables.each {|name| ENV[name] = nil}

      ENV['REDCAR_BIN'] = Redcar::ROOT + "/bin/redcar"
      ENV['RUBYLIB'] = (ENV['RUBYLIB']||"")+":#{textmate_share_dir}/Support/lib"
      ENV['TM_RUBY'] = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
      
      if bundle
        ENV['TM_BUNDLE_SUPPORT'] = bundle.dir+"/Support"
      end
      current_scope = nil
      if Redcar.tab and Redcar.tab.class.to_s == "Redcar::EditTab"
        line = Redcar.doc.get_line
        line = line[0..-2] if line[-1..-1] == "\n"
        ENV['TM_CURRENT_LINE'] = line
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
          current_scope = Redcar.doc.cursor_scope.hierarchy_names(true)
          ENV['TM_SCOPE'] = current_scope
        end
      end
      ENV['TM_SOFT_TABS'] = "YES"
      ENV['TM_SUPPORT_PATH'] = textmate_share_dir + "/Support"
      ENV['BASH_ENV'] = "#{App.textmate_share_dir}/Support/lib/bash_init.sh"
      ENV['TM_TAB_SIZE'] = "2"

      preferences = {}
      Bundle.bundles.each do |this_bundle|
        this_bundle.preferences.each do |name, prefs|
          scope = prefs["scope"]
          if scope
            next unless current_scope
            next unless match = Gtk::Mate::Matcher.get_match(scope, current_scope)
          end
          settings = prefs["settings"]
          if shell_variables = settings["shellVariables"]
            if preferences[name]
              prev_match, _ = preferences[name]
              if Gtk::Mate::Matcher.compare_match(current_scope, prev_match, match) < 0
                preferences[name] = [match, shell_variables]
              end
            else
              preferences[name] = [match, shell_variables]
            end
          end
        end
      end
      
      preferences.each do |name, pair|
        shell_variables = pair.last
        shell_variables.each do |variable_hash|
          name = variable_hash["name"]
          @env_variables << name unless @env_variables.include?(name)
          ENV[name] = variable_hash["value"]
        end        
      end
    end
    
    def self.textmate_share_dir
      File.join(Redcar::ROOT, "textmate")
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
