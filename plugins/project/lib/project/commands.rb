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
          result = Application::Dialog.message_box(
            "This tab has unsaved changes. \n\nReload?",
            :buttons => :yes_no_cancel
          )
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

        Manager.connect_to_remote(
          selected[:protocol],
          selected[:host],
          selected[:user],
          selected[:path],
          ConnectionManager::PrivateKeyStore.paths
        )
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
        Manager.connect_to_remote(
            protocol.value,
            host.value,
            user.value,
            path.value,
            ConnectionManager::PrivateKeyStore.paths
          )
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

    class DirectoryCloseCommand < ProjectCommand

      def execute
        project.close
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

    class RevealInProjectCommand < ProjectCommand
      def execute
        tab = Redcar.app.focussed_window.focussed_notebook_tab
        return unless tab.is_a?(EditTab)

        path = tab.edit_view.document.mirror.path
        tree = project.tree
        current = tree.tree_mirror.top
        while current.any?
          ancestor_node = current.detect {|node| path =~ /^#{node.path}($|\/)/}
          tree.expand(ancestor_node)
          current = ancestor_node.children if ancestor_node
        end
        tree.select(ancestor_node)
        project.window.treebook.focus_tree(project.tree)
      end
    end

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
        if SPOON_AVAILABLE and ::Spoon.supported?
          ::Spoon.spawn(app, *options)
        else
          # TODO: This really needs proper escaping.
          if options
            options = options.map {|o| "\"#{o}\""}.join(' ')
          else
            options = ""
          end
          Thread.new do
            system("#{app} #{options}")
            puts "  Finished: #{app} #{options}"
          end
        end
      end
    end

    class OpenDirectoryInExplorerCommand < OpenCommand
      def execute(options=nil)
        @path ||= options[:value]
        command = self
        preferred = Manager.storage['preferred_file_browser']
        case Redcar.platform
        when :osx
          # Spoon doesn't seem to like `open`
          system('open', '-a', 'Finder', path)
        when :windows
          run_application('explorer.exe', path.gsub("/","\\"))
        when :linux
          app = {
            'Thunar' => [path],
            'nautilus' => [path],
            'konqueror' => [path],
            'kfm' => [path],
          }
          if preferred and app[preferred] and find(preferred)
            run = preferred
          else
            run = app.keys.map {|a| command.find(a)}.find{|a| a}
            Manager.storage['preferred_file_browser'] = run if not preferred
          end
          if run
            run_application(run, *app[File.basename(run)])
          else
            Application::Dialog.message_box("Sorry, we couldn't find your file manager. Please let us know what file manager you use, so we can fix this!")
          end
        end
      end
    end

    class OpenDirectoryInCommandLineCommand < OpenCommand
      def execute(options=nil)
        @path ||= options[:value]
        command = self
        preferred = Manager.storage['preferred_command_line']
        case Redcar.platform
        when :osx
          unless preferred
            preferred = "Terminal"
            Manager.storage['preferred_command_line'] = preferred
          end
          command = <<-BASH.gsub(/^\s{12}/, '')
            osascript <<END
              tell application "#{preferred}"
                do script "cd \\\"#{path}\\\""
                activate
              end tell
            END
          BASH
          # Spoon doesn't seem to work with `osascript`
          system(command)
        when :windows
          run_application('start cmd.exe', '/kcd ' + path.gsub("/","\\"))
        when :linux
          app = {
            'xfce4-terminal' => ["--working-directory=#{path}"],
            'gnome-terminal' => ["--working-directory=#{path}"],
            'konsole' => ["--workdir", path],
          }
          if preferred and app[preferred] and find(preferred)
            run = preferred
          else
            run = app.keys.map {|a| command.find(a)}.find{|a| a}
            Manager.storage['preferred_command_line'] = run if not preferred
          end
          if run and app[File.basename(run)]
            run_application(run, *app[File.basename(run)])
          else
            Application::Dialog.message_box("Sorry, we couldn't find your command line. Please let us know what command line you use, so we can fix this!")
          end
        end
      end
    end
  end
end
