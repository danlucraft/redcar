
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
            adapter = open_adapter(protocol, host, user, pw, [])
            open_remote_project(adapter, path)
          end
        end
      rescue => e
        puts "Error connecting: #{e.class}: #{e.message}"
        puts e.backtrace
        Application::Dialog.message_box("Error connecting: #{e.message}", :type => :error)
      end

      def self.get_password
        result = Redcar::Application::Dialog.password_input("Remote Connection", "Enter password")
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
            #restore_last_session
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
        @storage ||= begin
          storage = Plugin::Storage.new('project_plugin')
          storage.set_default('reveal_files_in_project_tree',true)
          storage.set_default('reveal_files_only_when_tree_is_focussed',true)
          storage
        end
      end

      def self.reveal_files?
        storage['reveal_files_in_project_tree']
      end

      def self.reveal_files=(toggle)
        storage['reveal_files_in_project_tree'] = toggle
      end

      def self.reveal_file_only_when_tree_focussed?
        storage['reveal_files_only_when_tree_is_focussed']
      end

      def self.reveal_file?(project)
        if project and tree = project.tree
          if reveal_files? and project.window.trees_visible?
            ftree = project.window.treebook.focussed_tree
            unless tree != ftree and reveal_file_only_when_tree_focussed?
              true
            end
          end
        end
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
        return unless large_file_airbag(path)
        tab = win.new_tab(Redcar::EditTab)
        mirror = FileMirror.new(path, adapter)
        tab.edit_view.document.mirror = mirror
        tab.edit_view.reset_undo
        tab.focus
      end

      def self.file_too_large?(path)
        File.size(path) > file_size_limit
      end

      # Prompts the user before opening the given path if it's above self.file_size_limit.
      def self.large_file_airbag(path)
        if file_too_large?(path)
          Application::Dialog.message_box(
            "This file is larger than 10MB which may crash Redcar.\n\nAre you sure you want to open it?",
            :type => :warning,
            :buttons => :yes_no) == :yes
        else
          true
        end
      end

      def self.find_projects_containing_path(path)
        open_projects.select {|p|
          p.contains_path?(path)
        }.sort_by {|p| path.split(//).length-p.path.split(//).length}
      end

      def self.open_file(path, adapter=Adapters::Local.new)
        if tab = find_open_file_tab(path)
          tab.focus
          return
        end
        if project = find_projects_containing_path(path).first
          window = project.window
        else
          window = windows_without_projects.first || Redcar.app.new_window
          Project::Recent.store_path(path)
        end
        open_file_in_window(path, window, adapter)
        window.focus
      end

      def self.pop_first_line_option(args)
        if args.include? '-l'
          argix = args.index('-l')
          raise ArgumentError, "The -l Option expects an Argument" unless args[argix + 1]
          numbers = args[argix + 1].split(',')
          first_num = numbers.delete_at(0)
          if (args[argix + 1] = numbers.join(',')).empty?
            args.delete_at(argix); args.delete_at(argix)
          end
          first_num
        elsif match = args.select {|a| /^\-l\d+$/.match a }.first
          args.delete(args.index(match))
          match[2..-1]
        end
      end

      def self.scroll_to_line(arg)
        begin
          doc = Redcar.app.focussed_notebook_tab.edit_view.document
          lineix = arg.to_i - 1
          doc.scroll_to_line(lineix)
          doc.cursor_offset = doc.offset_at_line(lineix)
        rescue Exception
          raise ArgumentError, 'The "-l" Option expects a number as Argument'
        end
      end

      def self.open_tab_with_content(text)
        win = Redcar.app.focussed_window || Redcar.app.new_window
        tab = win.new_tab(Redcar::EditTab)
        tab.edit_view.document.text = text
        tab.edit_view.reset_undo
        tab.focus
      end

      PROJECT_LOCKED_MESSAGE = "Project appears to be locked by another Redcar process!\nOpen anway?"
      
      # Opens a new Tree with a DirMirror and DirController for the given
      # path, in a new window.
      #
      # @param [String] path  the path of the directory to view
      def self.open_project_for_path(path)
        open_projects.each do |project|
          if project.path == path
            project.window.focus
            return
          end
        end
        project = Project.new(path)
        should_open = true
        if project.locked?
          should_open = Application::Dialog.message_box(PROJECT_LOCKED_MESSAGE, :type => :warning, :buttons => :yes_no)
        end
        if should_open
          win = Redcar.app.focussed_window
          win = Redcar.app.new_window if !win or Manager.in_window(win)
          project.open(win) if project.ready?
        end
      end

      # Opens a subproject in a new window
      # @param [String] project_path  the project path to fork
      # @param [String] path  the path of the directory to view
      def self.open_subproject(project_path,path)
        win = Redcar.app.focussed_window
        win = Redcar.app.new_window if !win or Manager.in_window(win)
        project = Redcar::Project::SubProject.new(project_path,path).tap do |p|
          p.open(win) if p.ready?
          win.title = "Subproject: #{File.basename(path)} in #{File.basename(project_path)}"
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
            linearg = pop_first_line_option(args)
            scroll_to_line(linearg) if linearg
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

      def self.update_tab_for_path(path,new_path=nil)
        if tab = Manager.find_open_file_tab(path)
          if new_path
            mirror = Project::FileMirror.new(new_path)
            tab.edit_view.document.mirror = mirror
          else
            tab.update_for_file_changes
          end
        end
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

      def self.menus
        Menu::Builder.build do
          sub_menu "File" do
            group(:priority => 0) do
              item "Open", Project::FileOpenCommand
              item "Reload File", Project::FileReloadCommand
              item "Open Directory", Project::DirectoryOpenCommand
              item "Open Recent...", Project::FindRecentCommand
              
              separator
              item "Save", Project::FileSaveCommand
              item "Save As", Project::FileSaveAsCommand
            end
          end
          
          sub_menu "Project", :priority => 15 do
            group(:priority => :first) do
              item "Find File", Project::FindFileCommand
              # item "Refresh Directory", Project::RefreshDirectoryCommand
            end
            item "Reveal Open File in Tree", :command => Project::ToggleRevealInProject, :type => :check, :active => Project::Manager.reveal_files?
          end
        end
      end

      # Uses our own context menu hook to provide context menu entries
      # @return [Menu]
      def self.project_context_menus(tree, node, controller)
        if node
          if node.directory?
            enclosing_dir = node.path
          else
            enclosing_dir = node.directory
          end
        else
          enclosing_dir = tree.tree_mirror.path
        end
        Menu::Builder.build do
          group(:priority => :first) do
            item("New File")        { controller.new_file(tree, node) }
            item("New Directory")   { controller.new_dir(tree, node)  }
          end
          separator
          sub_menu "Open Directory" do
            group(:priority => 30) do
              item("in File Browser") { Project::OpenDirectoryInExplorerCommand.new(enclosing_dir).run }
              item("in Command Line") { Project::OpenDirectoryInCommandLineCommand.new(enclosing_dir).run }
              unless enclosing_dir == tree.tree_mirror.path
                item("as new Project") { Manager.open_project_for_path(enclosing_dir) }
                item("as Subproject")  { Manager.open_subproject(tree.tree_mirror.path,enclosing_dir) }
              end
            end
          end
          if not node.nil?
            group(:priority => 15) do
              separator
              if tree.selection.length > 1
                dirs = tree.selection.map {|node| node.parent_dir }
                if dirs.uniq.length == 1 and node.adapter.is_a?(Adapters::Local)
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
        attr_accessor :file_size_limit
        attr_reader :open_project_sensitivity
      end
      self.file_size_limit = 5242880
    end
  end
end
