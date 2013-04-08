module Redcar
  class ProjectCommand < Command
    sensitize :open_project

    def project
      Project::Manager.in_window(win)
    end
  end

  class Project
    class OpenFileCommand < Command
      def initialize(path = nil)
        @path = path
      end

      def execute
        path = get_path
        if path
          if File.readable? path
            Manager.open_file(path)
          else
            Application::Dialog.message_box(
              "Can't read #{path}, you don't have the permissions.",
              :type => :error,
              :buttons => :ok
            )
          end
        end
      end

      private

      def get_path
        @path || begin
          if path = Application::Dialog.open_file(:filter_path => Manager.filter_path)
            Manager.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end

    class FileReloadCommand < EditTabCommand
      def initialize(path = nil)
        @path = path
      end

      def execute
        if tab.edit_view.document.modified?
          result = Application::Dialog.message_box("This tab has unsaved changes. \n\nReload?",
            :buttons => :yes_no_cancel)
          case result
          when :yes
            tab.edit_view.document.update_from_mirror
          when :no
          when :cancel
          end
        else
          tab.edit_view.document.update_from_mirror
        end
      end
    end

    class SaveFileCommand < EditTabCommand
      def initialize(tab=nil)
        @tab = tab
      end

      def execute
        result = false
        if mirror = tab.edit_view.document.mirror and mirror.respond_to? :path
          path          = tab.edit_view.document.mirror.path
          dir           = File.dirname(path)
          writable_file = File.writable?(path)
          writable_dir  = File.writable?(dir) # this method buggy in windows: http://redmine.ruby-lang.org/issues/4712
          file_exists   = File.exist?(path)
          can_write     = writable_file || (!file_exists && writable_dir)
          if can_write
            begin
              tab.edit_view.document.save!
              Project::Manager.refresh_modified_file(tab.edit_view.document.mirror.path)
              result = true
            rescue Errno::EACCES # windows
              show_dialog = true
            end
          else
            show_dialog = true
          end

          if show_dialog
            Application::Dialog.message_box(
              "Can't save #{tab.edit_view.document.mirror.path}, you don't have the permissions.",
              :type => :error,
              :buttons => :ok
            )
            result = false
          end
        else
          result = SaveFileAsCommand.new.run
        end
        tab.update_for_file_changes
        result
      end
    end

    class SaveFileAsCommand < EditTabCommand

      def initialize(tab=nil, path=nil)
        @tab  = tab
        @path = path
      end

      def execute
        path = get_path
        if path
          if File.exists?(path) ? File.writable?(path) : File.writable?(File.dirname(path))
            contents = tab.edit_view.document.to_s
            new_mirror = FileMirror.new(path)
            new_mirror.commit(contents)
            tab.edit_view.document.mirror = new_mirror
            Project::Manager.refresh_modified_file(tab.edit_view.document.mirror.path)
            true
          else
            Application::Dialog.message_box(
              "Can't save #{path}, you don't have the permissions.",
              :type => :error,
              :buttons => :ok
            )
            false
          end
        else
          false
        end
      end

      private

      def get_path
        @path || begin
          if path = Application::Dialog.save_file(:filter_path => Manager.filter_path)
            Manager.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end

    ## TODO Finish implementing this.
    class SaveAllFileCommand < Command
      #sensitize :open_window
      
      def execute
        result = true
        
        save_command = SaveFileCommand.new
        
        win.all_tabs.select{|t| t.is_a? EditTab}.each do |tab|
          save_command.tab = tab
          result &= save_command.run
        end
        
        result
      end
    end

    class DirectoryOpenCommand < Command

      def initialize(path=nil)
        @path = path
      end

      def execute
        if path = get_path
          project = Manager.open_project_for_path(path)
          project.refresh if project
        end
      end

      private

      def get_path
        @path || begin
          if path = Application::Dialog.open_directory(:filter_path => Manager.filter_path)
            Manager.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end

    class RefreshDirectoryCommand < ProjectCommand

      def execute
        project.refresh
      end
    end

    class FindFileCommand < ProjectCommand

      def execute
        dialog = FindFileDialog.new(Manager.focussed_project)
        dialog.open
      end
    end

    class FindRecentCommand < Command
      def execute
        Redcar.app.make_sure_at_least_one_window_open
        FindRecentDialog.new.open
      end
    end

    class RevealInProjectCommand < ProjectCommand
      def execute
        if project
          tab = Redcar.app.focussed_window.focussed_notebook_tab
            if tab.is_a?(EditTab)
            return unless mirror = tab.edit_view.document.mirror and mirror.respond_to? :path
          else
            return
          end

          path = mirror.path
          tree = project.tree
          current = tree.tree_mirror.top
          while current.any?
            ancestor_node = current.detect {|node| path =~ /^#{node.path}($|\/)/ }
            return unless ancestor_node
            tree.expand(ancestor_node)
            current = ancestor_node.children
          end
          tree.select(ancestor_node)
          project.window.treebook.focus_tree(project.tree)
        end
      end
    end

    class ToggleRevealInProject < ProjectCommand
      def execute
        toggle = Project::Manager.reveal_files?
        Project::Manager.reveal_files = !toggle
      end
    end

    # FIXME: XXX: The rest of this file is outright ugly. The Redcar.platform ultimately
    # needs to return a platform object which we can dispatch to for commandlines,
    # configuration, escaping and all that.
    class OpenCommand < Command
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def find(executable)
        path = if Redcar.platform == :windows
          ENV['PATH'].split(';')
        else
          ENV['PATH'].split(':')
        end.find {|d| File.exist?(File.join(d, executable))}

        if path
          File.join(path, executable)
        else
          nil
        end
      end

      def run_application(app, *options)
        # TODO: Investigate why Spoon doesn't seem to work on osx
        if SPOON_AVAILABLE and Redcar.platform != :osx
          ::Spoon.spawn(app, *options)
        else
          # TODO: This really needs proper escaping.
          options = options.map {|o| %{ "#{o}" } }.join(' ')
          Thread.new do
            system("#{app} #{options}")
            puts "  Finished: #{app} #{options}"
          end
        end
      end
    end

    class OpenDirectoryInExplorerCommand < OpenCommand
      LinuxApps = {
        'Thunar'    => '%s',
        'nautilus'  => '%s',
        'konqueror' => '%s',
        'pcmanfm'   => '%s',
        'kfm'       => '%s'
      }

      def explorer_osx
        ['open -a Finder', path]
      end

      def explorer_windows
        ['explorer.exe', path.gsub("/", "\\")]
      end

      def explorer_linux
        preferred = Manager.storage['preferred_file_browser']
        run = preferred if LinuxApps[preferred] and find(preferred)
        LinuxApps.keys.detect {|a| run = @command.find(a) } unless run

        Manager.storage['preferred_file_browser'] = run unless preferred

        [run, LinuxApps[File.basename(run)] % path ] if run
      end

      def execute(options = nil)
        @path ||= options[:value]
        @command = self
        cmd = send(:"explorer_#{Redcar.platform}")
        if cmd
          run_application(*cmd)
        else
          Application::Dialog.message_box("Sorry, we couldn't start your file manager. Please let us know what file manager you use, so we can fix this!")
        end
      end
    end

    class OpenDirectoryInCommandLineCommand < OpenCommand
      LinuxApps = {
        'xfce4-terminal' => "--working-directory=%s",
        'gnome-terminal' => "--working-directory=%s",
        'lxterminal'     => "--working-directory=%s",
        'konsole'        => "--workdir %s"
      }

      def osx_terminal_script(preferred)
        if preferred.start_with? "iTerm"
          <<-OSASCRIPT
            tell the first terminal
              launch session "Default Session"
                tell the last session
                write text "cd \\\"#{path}\\\""
              end tell
            end tell
          OSASCRIPT
        else
          %{ do script "cd \\\"#{path}\\\"" }
        end
      end

      def commandline_osx
        preferred = (Manager.storage['preferred_command_line'] ||= "Terminal")
        <<-BASH.gsub(/^\s*/, '')
          osascript <<END
            tell application "#{preferred}"
              #{osx_terminal_script(preferred)}
              activate
            end tell
          END
        BASH
      end

      def commandline_windows
        ['start cmd.exe /kcd ', path.gsub("/","\\")]
      end

      def commandline_linux
        preferred = Manager.storage['preferred_command_line']
        run = preferred if LinuxApps[preferred] and find(preferred)
        LinuxApps.keys.detect {|a| run = @command.find(a) } unless run

        Manager.storage['preferred_command_line'] = run unless preferred

        [run, LinuxApps[File.basename(run)] % path ] if run
      end

      def execute(options = nil)
        @path ||= options[:value]
        @command = self
        cmd = send(:"commandline_#{Redcar.platform}")
        if cmd
          run_application(*cmd)
        else
          Application::Dialog.message_box("Sorry, we couldn't start your command line. Please let us know what command line you use, so we can fix this!")
        end
      end
    end
  end
end
