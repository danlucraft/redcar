module Redcar
  class ProjectCommand < Command
    sensitize :open_project
    
    def project
      Project::Manager.in_window(win)
    end
  end

  class Project
    class FileOpenCommand < Command
      def initialize(path = nil)
        @path = path
      end
    
      def execute
        path = get_path
        if path
          Manager.open_file(path)
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
    
    class FileSaveCommand < EditTabCommand

      def execute
        tab = win.focussed_notebook.focussed_tab
        if tab.edit_view.document.mirror
          tab.edit_view.document.save!
        else
          FileSaveAsCommand.new.run
        end
      end
    end
    
    class FileSaveAsCommand < EditTabCommand
      
      def initialize(path = nil)
        @path = path
      end

      def execute
        tab = win.focussed_notebook.focussed_tab
        path = get_path
        if path
          contents = tab.edit_view.document.to_s
          new_mirror = FileMirror.new(path)
          new_mirror.commit(contents)
          tab.edit_view.document.mirror = new_mirror
          Manager.open_projects.each {|pr| pr.refresh}
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
          Manager.open_project_for_path(path)
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
    
  end
end