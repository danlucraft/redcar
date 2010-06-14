
module Redcar
  class Project
    class DirController
      def activated(tree, node)
        if node.leaf?
          FileOpenCommand.new(node.path).run
        end
      end
      
      def right_click(tree, node)
        controller = self
        
        menu = Menu::Builder.build do
          item("New File")      { controller.new_file(tree, node) }
          item("New Directory") { controller.new_dir(tree, node)  }
          separator
          item("Rename")        { controller.rename(tree, node)   }
          item("Delete")        { controller.delete(tree, node)   }
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
      
      def new_file(tree, node)
        enclosing_dir = node ? node.directory : tree.tree_mirror.path
        new_file_name = uniq_name(enclosing_dir, "New File")
        new_file_path = File.join(enclosing_dir, new_file_name)
        FileUtils.touch(new_file_path)
        tree.refresh
        tree.expand(node)
        new_file_node = DirMirror::Node.create_from_path(new_file_path)
        tree.edit(new_file_node)
      end
      
      def new_dir(tree, node)
        enclosing_dir = node ? node.directory : tree.tree_mirror.path
        new_dir_name = uniq_name(enclosing_dir, "New Directory")
        new_dir_path = File.join(enclosing_dir, new_dir_name)
        FileUtils.mkdir(new_dir_path)
        tree.refresh
        tree.expand(node)
        new_dir_node = DirMirror::Node.create_from_path(new_dir_path)
        tree.edit(new_dir_node)
      end
      
      def rename(tree, node)
        if node.text =~ /^(.*)\.[^\.]+$/
          tree.edit(node, 0, $1.length)
        else
          tree.edit(node)
        end
      end
      
      def delete(tree, _)
        nodes = tree.selection
        basenames = nodes.map {|node| File.basename(node.path) }
        msg = "Really delete #{basenames.join(", ")}?"
        result = Application::Dialog.message_box(msg, :type => :question, :buttons => :yes_no)
        if result == :yes
          nodes.each do |node|
            FileUtils.rm_rf(node.path)
          end
          tree.refresh
        end
      end
      
      def edited(tree, node, text)
        new_path = File.expand_path(File.join(File.dirname(node.path), text))
        return if node.path == new_path
        
        FileUtils.mv(node.path, new_path)
        tree.refresh
        new_node = DirMirror::Node.create_from_path(new_path)
        tree.select(new_node)
      end
      
      private
      
      def uniq_name(path, name)
        return name unless File.exist?(File.join(path, name))
        i = 1
        loop do
          new_name = name + " #{i}"
          return new_name unless File.exist?(File.join(path, new_name))
          i += 1
        end
      end
    end
  end
end

    
