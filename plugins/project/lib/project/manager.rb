
module Redcar
  class Project
    class Manager

      def self.connect_to_remote(protocol, host, user, path, private_key_files = [])
        if protocol == "SFTP" and private_key_files.any?
          begin
            adapter = open_adapter(protocol, host, user, nil, private_key_files)
            open_remote_project(adapter, path)
          rescue Net::SSH::AuthenticationFailed
            if pw = get_password
              adapter = open_adapter(protocol, host, user, pw, [])
              open_remote_project(adapter, path)
            end
          end
        else
          if pw = get_password
            adapter = open_adapter(protocol, host, user, password, [])
            open_remote_project(adapter, path)
          end
        end
      rescue => e
        puts "Error connecting: #{e.class}: #{e.message}"
        puts e.backtrace
        Application::Dialog.message_box("Error connecting: #{e.message}", :type => :error)
      end
      
      def self.get_password
        result = Redcar::Application::Dialog.input("Password", "Enter password")
        result[:value] if result
      end

      # Opens a new Tree with a DirMirror and DirController for the given
      # path, in a new window.
      #
      # @param [String] path  the path of the directory to view
      def self.open_remote_project(adapter, path)
        win = Redcar.app.focussed_window
        win = Redcar.app.new_window if !win or Manager.in_window(win) 
        project = Project.new(path, adapter)
        project.open(win) if project.ready?
      end

      def self.open_adapter(protocol, host, user, password, private_key_files)
        Adapters::Remote.new(protocol.downcase.to_sym, host, user, password, private_key_files)
      rescue Errno::ECONNREFUSED
        raise "connection refused connecting to #{host}"
      rescue SocketError
        raise "Cannot connect to #{host}. Error: #{$!.message}."
      end
      
      def self.open_projects
        Project.window_projects.values
      end
      
      # Returns the project in the given window
      # @param [Window] window
      # @return Project or nil
      def self.in_window(window)
        Project.window_projects[window]
      end
      
      def self.windows_without_projects
        Redcar.app.windows.reject {|w| in_window(w) }
      end
      
      # this will restore open files unless other files or dirs were passed
      # as command line parameters
      def self.start(args)
        unless handle_startup_arguments(args)
          unless Redcar.environment == :test
            restore_last_session
          end
        end
        init_current_files_hooks
        init_window_closed_hooks
        init_drb_listener
      end
      
      def self.init_window_closed_hooks
        Redcar.app.add_listener(:window_about_to_close) do |win|
          project = in_window(win)
          project.close if project
          self.save_file_list(win)
        end
      end
      
      def self.init_drb_listener
        return if ARGV.include?("--multiple-instance")
        @drb_service = DrbService.new
      end
      
      def self.storage
        @storage ||= Plugin::Storage.new('project_plugin')
      end
      
      def self.filter_path
        if Redcar.app.focussed_notebook_tab
          if mirror = EditView.focussed_document_mirror and mirror.is_a?(FileMirror)
            dir = File.dirname(mirror.path)
            return dir
          end
        end      
        storage['last_dir'] || File.expand_path(Dir.pwd)
      end
    
      def self.sensitivities
        [ @open_project_sensitivity = 
            Sensitivity.new(:open_project, Redcar.app, false, [:focussed_window]) do
              if win = Redcar.app.focussed_window
                win.treebook.trees.detect {|t| t.tree_mirror.is_a?(DirMirror) }
              end
            end
        ]
      end
      
      # Finds an EditTab with a mirror for the given path.
      #
      # @param [String] path  the path of the file being edited
      # @return [EditTab, nil] the EditTab that is editing it, or nil
      def self.find_open_file_tab(path)
        path = File.expand_path(path)
        all_tabs = Redcar.app.windows.map {|win| win.notebooks}.flatten.map {|nb| nb.tabs }.flatten
        all_tabs.find do |t| 
          t.is_a?(Redcar::EditTab) and 
          t.edit_view.document.mirror and 
          t.edit_view.document.mirror.is_a?(FileMirror) and 
          File.expand_path(t.edit_view.document.mirror.path) == path 
        end
      end
      
      # Opens a new EditTab with a FileMirror for the given path.
      #
      # @path  [String] path the path of the file to be edited
      # @param [Window] win  the Window to open the File in
      def self.open_file_in_window(path, win, adapter)
        tab = win.new_tab(Redcar::EditTab)
        mirror = FileMirror.new(path, adapter)
        tab.edit_view.document.mirror = mirror
        tab.edit_view.reset_undo
        tab.focus
      end
      
      def self.find_projects_containing_path(path)
        open_projects.select {|project| project.contains_path?(path) }
      end
      
      def self.open_file(path, adapter=Adapters::Local.new)
        if tab = find_open_file_tab(path)
          tab.focus
          return
        end
        if project = find_projects_containing_path(path).first
          p [:found_containing_project, project.path]
          window = project.window
        else
          p [:didn_t_find_containing_project]
          window = windows_without_projects.first || Redcar.app.new_window
        end
        open_file_in_window(path, window, adapter)
        window.focus
      end
      
      def self.open_tab_with_content(text)
        win = Redcar.app.focussed_window || Redcar.app.new_window
        tab = win.new_tab(Redcar::EditTab)
        tab.edit_view.document.text = text
        tab.edit_view.reset_undo
        tab.focus
      end
      
      # Opens a new Tree with a DirMirror and DirController for the given
      # path, in a new window.
      #
      # @param [String] path  the path of the directory to view
      def self.open_project_for_path(path)
        win = Redcar.app.focussed_window
        win = Redcar.app.new_window if !win or Manager.in_window(win) 
        project = Project.new(path).tap do |p|
          p.open(win) if p.ready?
        end
      end
      
      # The currently focussed Project, or nil if none.
      #
      # @return [Project]
      def self.focussed_project
        in_window(Redcar.app.focussed_window)
      end
      
      # saves away a list of the currently open files in
      # @param [win]
      def self.save_file_list(win)
        # create a list of open files
        file_list = []
        win.notebooks[0].tabs.each do |tab|
          if tab.document && tab.document.path
            file_list << tab.document.path
          end
        end
        storage['files_open_last_session'] = file_list      
      end
      
      # handles files and/or dirs passed as command line arguments
      def self.handle_startup_arguments(args)
        found_path_args = false
        args.each do |arg|
          if File.directory?(arg)
            found_path_args = true
            DirectoryOpenCommand.new(arg).run
          elsif File.file?(arg)
            found_path_args = true
            open_file(arg)
          end
        end
        args.each do |arg|
          if arg =~ /--untitled-file=(.*)/
            path = $1
            found_path_args = true
            open_untitled_path(path)
          end
        end
        found_path_args
      end
      
      def self.open_untitled_path(path)
        begin
          if File.file?(path) and contents = File.read(path)
            open_tab_with_content(contents)
          end
        rescue => e
          puts "Error opening untitled file #{path}"
          puts e.class.to_s + ":" + e.message
          puts e.backtrace
        end
      end
      
      # Attaches a new listener to tab focus change events, so we can 
      # keep the current_files list.
      def self.init_current_files_hooks
        Redcar.app.add_listener(:tab_focussed) do |tab|
          if tab and tab.document_mirror.respond_to?(:path)
            if project = Manager.in_window(tab.notebook.window)
              project.add_to_recent_files(tab.document_mirror.path)
            end
          end
        end
        attach_app_listeners
      end
      
      def self.attach_app_listeners
        Redcar.app.add_listener(:lost_focus) do
          Manager.open_projects.each {|project| project.lost_application_focus }
        end
        
        Redcar.app.add_listener(:window_focussed) do |win|
          Manager.in_window(win).andand.gained_focus
        end
      end
      
      # restores the directory/files in the last open window
      def self.restore_last_session
        if path = storage['last_open_dir']
          s = Time.now
          open_project_for_path(path)
        end
        
        if files = storage['files_open_last_session']
          files.each do |path|
            open_file(path)
          end
        end
      end

      def self.refresh_modified_file(path)
        path = File.expand_path(path)
        find_projects_containing_path(path).each do |project|
          project.refresh_modified_file(path)
        end
      end
      
      # Uses our own context menu hook to provide context menu entries
      # @return [Menu]
      def self.project_context_menus(tree, node, controller)
        Menu::Builder.build do
          group(:priority => :first) do
            item("New File")        { controller.new_file(tree, node) }
            item("New Directory")   { controller.new_dir(tree, node)  }
          end
          if not node.nil?
            group(:priority => 15) do
              separator
              if tree.selection.length > 1
                dirs = tree.selection.map {|node| node.parent_dir }
                if dirs.uniq.length == 1
                  item("Bulk Rename") { controller.rename(tree, node)   }
                end
              else
                item("Rename")        { controller.rename(tree, node)   }
              end
              item("Delete")          { controller.delete(tree, node)   }
            end
          end
          group(:priority => 75) do
            separator
            if DirMirror.show_hidden_files?
              item("Hide Hidden Files") do
                DirMirror.show_hidden_files = false
                tree.refresh
              end
            else
              item("Show Hidden Files") do
                DirMirror.show_hidden_files = true
                tree.refresh
              end
            end
          end
        end
      end
          
      class << self
        attr_reader :open_project_sensitivity
      end
    end
  end
end
