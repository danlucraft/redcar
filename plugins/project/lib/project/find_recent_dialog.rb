module Redcar
  class Project

    class FindRecentDialog < FilterListDialog
      def update_list(filter)
        recent = Project::Recent.storage['list']
        recent = recent.map do |path| 
          {:name => path.gsub(/^#{Regexp.escape(Redcar.home_dir)}\/?/, ""), :icon => :dir}
        end
        filter_and_rank_by(recent, filter) {|h| h[:name] }
      end

      def selected(item, ix)
        path = item[:name]
        unless path[0..0] == "/" or path =~ /^[A-Z]:\//
          path = Redcar.home_dir + "/" + path
        end
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
