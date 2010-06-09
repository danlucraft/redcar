
module Redcar
  class Project
    class DirController
      def activated(tree, node)
        if node.leaf?
          FileOpenCommand.new(node.path).run
        end
      end
      
      def right_click(tree, node)
        enclosing_dir = node ? node.directory : tree.tree_mirror.path
        
        menu = Menu::Builder.build do
          item("New File") do
            new_file_path = File.join(enclosing_dir, "New File")
            FileUtils.touch(new_file_path)
            tree.refresh
            tree.expand(node)
            new_file_node = DirMirror::Node.create_from_path(new_file_path)
            tree.edit(new_file_node)
          end
          
          item("New Directory") do 
            new_dir_path = File.join(enclosing_dir, "New Directory")
            FileUtils.mkdir(new_dir_path)
            tree.refresh
            tree.expand(node)
            new_dir_node = DirMirror::Node.create_from_path(new_dir_path)
            tree.edit(new_dir_node)
          end
          
          separator
          
          item("Rename") do
            if node.text =~ /^(.*)\.[^\.]+$/
              tree.edit(node, 0, $1.length)
            else
              tree.edit(node)
            end
          end
          
          item("Delete") do 
            FileUtils.rm(node.path)
            tree.refresh
          end
        end
        
        Application::Dialog.popup_menu(menu, :pointer)
      end
      
      def edited(tree, node, text)
        FileUtils.mv(node.path, File.join(File.dirname(node.path), text))
        tree.refresh
      end
    end
  end
end

    
