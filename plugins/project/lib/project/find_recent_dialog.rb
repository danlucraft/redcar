module Redcar
  class Project

    class FindRecentDialog < FilterListDialog
      def update_list(filter)
        recent = Project::Recent.storage['list']
        filter_and_rank_by(recent, filter)
      end

      def selected(path, ix)
        if File.exist?(File.expand_path(path))
          if File.directory?(path)
            Project::Manager.open_project_for_path(path)
            close
          elsif File.file?(File.expand_path(path))
            Project::Manager.open_file(path)
            close
          else
            Project::Recent.remove_path(path)
          end
        end
      end
    end
    
  end
end
