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
    
    module OpenRemote
      def connect_to_remote(protocol, host, user, password, path)
        error = nil
        error = "You must provide a host name" if host.empty? 
  
        unless error
          Redcar.safely("Connecting to #{protocol} server #{host}") do
            begin
              project = Manager.open_remote_project(protocol, host, user, password, path)
              project.refresh

            rescue Errno::ECONNREFUSED
              error = "Connection refused connecting to #{host}"

            rescue SocketError
              error = "Cannot connect to #{host}. Error: #{$!.message}."

            rescue
              # gives a chance to protocols to handle their specific errors
              Project::Adapters::Remote::PROTOCOLS.values.each do |p|
                break if error = p.handle_error($!, host, user)
              end
            end
          end
        end
        
        Application::Dialog.message_box(error, :type => :error, :buttons => :ok) if error
      end
    end
    
    class OpenRemoteSpeedbar < Redcar::Speedbar
      include OpenRemote
      
      class << self
        attr_accessor :connection
        
        def connections
          storage = Redcar::Plugin::Storage.new('user_connections') || {}
          connections = storage[:connections]
        end
        
        def connection_names
          if connections && connections.any?
            ['Select...', connections.map { |c| c[:name] }].flatten
          else
            # TODO
            ['Add a new connection...']
          end
        end
      end
      
      label :connection_label, 'Connect to:'
      combo :connection, connection_names, 'Select...'
      
      button :connect, "Connect", "Return" do
        selected = self.class.connections.find { |c| c[:name] == connection.value }
        connect_to_remote(
          selected[:protocol], 
          selected[:host],
          selected[:user],
          selected[:password],
          selected[:path]
        )
      end
      
      button :quick, "Quick Connection", "Ctrl+Q" do
        @speedbar = QuickOpenRemoteSpeedbar.new
        Redcar.app.focussed_window.open_speedbar(@speedbar)
      end
      
      button :manage, "Connections Manager", "Ctrl+M" do
        Redcar.app.focussed_window.close_speedbar
        Redcar::ConnectionsManager::OpenCommand.new.run
      end
    end
    
    class QuickOpenRemoteSpeedbar < Redcar::Speedbar
      include OpenRemote

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

      label :password_label, "Password:"
      textbox :password

      label :path_label, "Path:"
      textbox :path
      
      button :connect, "Connect", "Return" do
        connect(protocol.value, host.value, user.value, password.value, path.value)
      end
    end
    
    class OpenRemoteCommand < Command
      def initialize(url=nil)
        @url = url
      end
      
      def execute
        unless @url
          @speedbar = OpenRemoteSpeedbar.new
          win.open_speedbar(@speedbar)
        end
      end
    end
    
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
          current = ancestor_node.children
        end
        tree.select(ancestor_node)
      end
    end
    
  end
end
