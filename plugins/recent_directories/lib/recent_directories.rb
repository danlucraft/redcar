module Redcar
  # Purpose of this class is to have a plugin that shows the 5 most recent opened directories
  # This way users can quickly go to directories they have recently opened, or use frequently
  #
  class RecentDirectories
    # Create menus for recent directories
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Recent Directories" do
            # create an array to load the directory paths from the text file
            directories = Array.new
            # if the file indeed exists, continue.
            if File.exists?(File.join(Redcar.root, "plugins", "recent_directories", "dirs.txt"))
              File.open(File.join(Redcar.root, "plugins", "recent_directories", "dirs.txt"), "r+") do |file|
                file.each_line do |line| 
                  unless line.empty?
                    directories << line.chomp
                  end
                end
              end
              directories.each do |dir|
                item(RecentDirectories.parse_directory(dir), OpenDirectory) { dir }
              end
            end
          end
        end
      end
    end
    
    # Stores the given path to the text file, for the plugin to use
    #
    # @param [String] path  the path of a directory to be saved
    def self.store_path(path)
      if File.exists?(File.join(Redcar.root, 'plugins', 'recent_directories', 'dirs.txt'))
        directories = Array.new
        File.open(File.join(Redcar.root, 'plugins', 'recent_directories', 'dirs.txt'), 'r+') do |file|
          file.each_line { |line| directories << line.chomp }          
        end
        if directories.size == 0
          File.open(File.join(Redcar.root, 'plugins', 'recent_directories', 'dirs.txt'), 'w+') do |file|
            file.write "#{path}"
          end
        else
          directories = directories[0..3]
          unless directories.include? path
            directories.insert 0, path
          end
          line = ""
          directories.each { |e| line += "#{e}\n" }
          line.chomp!
          File.open(File.join(Redcar.root, 'plugins', 'recent_directories', 'dirs.txt'), 'w+') do |file|
            file.write line
          end
        end
        Redcar.app.refresh_menu!
      else
        File.open(File.join(Redcar.root, 'plugins', 'recent_directories', 'dirs.txt'), 'w+') do |file|
          file.write "#{path}"
        end
      end
    end
    
    # Takes the full directory path, and cuts it down so it fits
    # nicely in the menu. It separates the start and middle by ...
    #
    # @param [String] dir  The directory path to resize
    def self.parse_directory(dir)
      if dir.size > 30
        start_of_path = dir[0, 14]
        end_of_path = dir[dir.size() - 15, dir.size()]
        dir = "#{start_of_path}...#{end_of_path}"
      end
      dir
    end
    class OpenDirectory < Redcar::Command
      
      def execute
        focussed_window = Redcar.app.focussed_window
        puts "@block class: #{@block.class}"
        unless !@block
          Project.close_tree focussed_window
          tree = Tree.new(Project::DirMirror.new(@block), Project::DirController.new)
                 
          # Open the tree in the new window
          Project.open_tree(focussed_window, tree)
        else
          puts "@dir was empty, bad times."
        end
      end
      
      def block(block)
        @block = block
        #self
      end
    end
  end
end