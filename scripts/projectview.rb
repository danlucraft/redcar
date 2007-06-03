
module Redcar
  class << self
    attr_accessor :project_treeview, :project_treestore, :project_sw
  end
  
  class Project
    def self.dir_tree_get(path, parent_iter, &block)
      # puts "path: " + path
      files = Dir.glob(path+"/*")
      # p files
      files.sort_by{|f| ((File.directory? f) ? "a" : "z")+f}.each do |file|
        if block
          include_bool = block.call(file)
        else
          include_bool = true unless file =~ /~/ or file =~ /^\./ or file =~ /\.svn/
        end
        if include_bool
          iter = Redcar.project_treestore.append(parent_iter)
          filename = file[(path.length+1)..(file.length-1)]
          iter[0] = (pix = Gdk::Pixbuf.new("/home/dan/pixbuf.png"))
          iter[1] = filename
          iter[2] = path+"/" + filename
          # puts "filename: " + filename
          if File.directory? file
            dir_tree_get(path+"/"+filename, iter)
          end
        end
      end
    end
    
    def self.add_directory(name, path, &block)
      iter = Redcar.project_treestore.append(nil)
      iter[1] = name
      self.dir_tree_get(path, iter, &block)
    end
  end
end
