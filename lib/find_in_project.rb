require 'erb'
require "cgi"

module Redcar
  class FindInProject 
    
    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+F", FindInProject::OpenCommand        
      end
      
      linwin = Keymap.build("main", [:linux, :windows]) do        
        link "Ctrl+Shift+F", FindInProject::OpenCommand        
      end
      
      [linwin, osx]
    end
    
    def self.menus      
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Find in project" do
            item "find!", FindInProject::OpenCommand
            item "Edit plugin", FindInProject::EditFindInProject
          end
        end
      end
    end    
    
    class OpenCommand < Redcar::Command

      def execute
        controller = Controller.new
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
      
    
      class Controller
        
        def title
          "Find in project"
        end
        
        def index
          @plugin_path = File.join(File.dirname(__FILE__), "..")
          @files ||= ".gitignore tags *.log"
          @dirs ||= ".git .svn"
          @includes ||= "*.*"
          @lines ||= 100
          rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
          rhtml.result(binding)
        end
        
        def find(query, files, dirs, includes, lines)
          @query = query
          @files = files
          @dirs = dirs
          @includes = includes
          @lines = lines.to_i
                  
          options = "-r -n -H -E --binary-files='without-match' "
          
          files.split(' ').each do |file|
            options << "--exclude=\"#{file}\" "
          end
          
          dirs.split(' ').each do |dir|
            options << "--exclude-dir=\"#{dir}\" "
          end          

          includes.split(' ').each do |inc|
            options << "--include=\"#{inc}\" "
          end      
          
          if @lines
            head = "| head -n#{lines.to_i}"
          else
            head = ''
          end
          
          path = Project::Manager.focussed_project.path                    
          @output = `cd #{path}; grep "#{query}" #{options} . #{head}`
          @outputs = @output.split("\n")            
          Redcar.app.focussed_window.focussed_notebook_tab.html_view.controller = self                      
          1
        end  
        
        def open_file(file, line)          
          tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
          mirror = Project::FileMirror.new(File.join(Project::Manager.focussed_project.path, file))
          tab.edit_view.document.mirror = mirror        
          tab.edit_view.reset_undo          
          tab.edit_view.document.scroll_to_line(line.to_i-2)
          tab.focus           
          1
        end
        
      end    
      
    end
    
    class EditFindInProject < Redcar::Command
      def execute             
        Project::Manager.open_project_for_path(File.join(Redcar.user_dir, "plugins", "find-in-project"))                
        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "plugins", "find-in-project", "lib", "find_in_project.rb"))
        tab.edit_view.document.mirror = mirror        
        tab.edit_view.reset_undo
        tab.focus
      end
    end
    
  end
end
