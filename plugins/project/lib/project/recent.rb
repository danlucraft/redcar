module Redcar
  class Project
    # Purpose of this class is to have a menu that shows the 10 most recent opened files and directories
    # This way users can quickly go to files and directories they have recently opened, or use frequently
    class Recent
      
      # Create menus for recent files and directories
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('recent')
          storage.set_default('list', [])
          storage.set_default('max_list_length', 100)
          storage.set_default('max_recent_menu_length', 10)
          storage
        end
      end
      
      def self.generate_menu(builder)
        recent = storage['list']
        count = 0
        recent.each do |path|
          if count >= storage['max_recent_menu_length']
            break
          end
          count = count.next
          
          if File.exist?(File.expand_path(path))
            if File.directory?(path)
              builder.item(File.basename(path) + "/") do
                Project::Manager.open_project_for_path(path)
              end
            elsif File.file?(File.expand_path(path))
              builder.item(File.basename(path)) do
                Project::Manager.open_file(path)
              end
            else
              remove_path(path)
            end
          end
        end
      end
            
      
      # Stores the given path to the text file, to appear in the recents menu.
      #
      # @param [String] path  the path of a file or directory to be saved
      def self.store_path(path)
        path = File.expand_path(path)
        storage["list"].delete(path)
        storage["list"].unshift(path)
        if storage["list"].length == storage['max_list_length'] + 1
          storage["list"].pop
        end
        storage.save
      end
      
      def self.remove_path(path)
        path = File.expand_path(path)
        storage["list"].delete(path)
        storage.save
      end
    end
  end
end