module Redcar
  class ProjectCommand < Command
    sensitize :open_project

    def project
      Project::Manager.in_window(win)
    end
  end

  class Project
    class FileOpenCommand < Command
      def initialize(path = nil, adapter = Adapters::Local.new)
        @path = path
        @adapter = adapter
      end

      def execute
        path = get_path
        if path
          Manager.open_file(path, @adapter)
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
      def initialize(path = nil, adapter = Adapters::Local.new)
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

    class OpenRemoteSpeedbar < Redcar::Speedbar

      class << self
        attr_accessor :connection

        def connections
          ConnectionManager::ConnectionStore.new.connections
        end

        def connection_names
          if connections && connections.any?
            ['Select...', connections.map { |c| c.name }].flatten
          end
        end
      end

      def initialize
        connection.items = self.class.connection_names
      end

      label :connection_label, 'Connect to:'
      combo :connection

      button :connect, "Connect", "Return" do
        selected = self.class.connections.find { |c| c.name == connection.value }

        Manager.connect_to_remote(selected[:protocol], selected[:host],
          selected[:user], selected[:path], ConnectionManager::PrivateKeyStore.paths)
      end

      button :quick, "Quick Connection", "Ctrl+Q" do
        @speedbar = QuickOpenRemoteSpeedbar.new
        Redcar.app.focussed_window.open_speedbar(@speedbar)
      end

      button :manage, "Connections Manager", "Ctrl+M" do
        Redcar.app.focussed_window.close_speedbar
        Redcar::ConnectionManager::OpenCommand.new.run
      end
    end

    class QuickOpenRemoteSpeedbar < Redcar::Speedbar
      class << self
        attr_accessor :host
        attr_accessor :user
        attr_accessor :password
        attr_accessor :path
        attr_accessor :protocol
      end

      combo :protocol, %w(SFTP FTP), 'SFTP'

      label :host_label, "Host:"
      textbox :host

      label :user_label, "User:"
      textbox :user

      label :path_label, "Path:"
      textbox :path

      button :connect, "Connect", "Return" do
        Manager.connect_to_remote(protocol.value, host.value, user.value,
          path.value, ConnectionManager::PrivateKeyStore.paths)
      end
    end

    #class OpenRemoteCommand < Command
    #  def initialize(url=nil)
    #    @url = url
    #  end
    #
    #  def execute
    #    unless @url
    #      @speedbar = OpenRemoteSpeedbar.new
    #      win.open_speedbar(@speedbar)
    #    end
    #  end
    #end

    class FileSaveCommand < EditTabCommand
      def initialize(tab=nil)
        @tab = tab
      end

      def execute
        if tab.edit_view.document.mirror
          tab.edit_view.document.save!
          Project::Manager.refresh_modified_file(tab.edit_view.document.mirror.path)
        else
          FileSaveAsCommand.new.run
        end
        tab.update_for_file_changes
      end
    end

    class FileSaveAsCommand < EditTabCommand

      def initialize(tab=nil, path=nil)
        @tab  = tab
        @path = path
      end

      def execute
        path = get_path
        if path
          contents = tab.edit_view.document.to_s
          new_mirror = FileMirror.new(path)
          new_mirror.commit(contents)
          tab.edit_view.document.mirror = new_mirror
          Project::Manager.refresh_modified_file(tab.edit_view.document.mirror.path)
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

    class DirectoryOpenCommand < Command

      def initialize(path=nil)
        @path = path
      end

      def execute
        if path = get_path
          project = Manager.open_project_for_path(path)
          project.refresh
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
        if Manager.focussed_project.remote?
          Application::Dialog.message_box("Find file doesn't work in remote projects yet :(")
          return
        end
        dialog = FindFileDialog.new(Manager.focussed_project)
        dialog.open
      end
    end

    class FindRecentCommand < Command
      def execute
        FindRecentDialog.new.open
      end
    end

    class RevealInProjectCommand < ProjectCommand
      def execute
        if Project::Manager.reveal_file?(project)
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
        if SPOON_AVAILABLE and ::Spoon.supported? and Redcar.platform != :osx
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