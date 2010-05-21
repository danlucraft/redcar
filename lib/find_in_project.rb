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
            item "Find in project!", FindInProject::OpenCommand
            item "Edit plugin", FindInProject::EditFindInProject
            item "Edit preferences", FindInProject::EditPreferences
          end
        end
      end
    end    
    
    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('find_in_project')
        storage.set_default('exclude_dirs', '.git .svn')
        storage.set_default('exclude_files', '.gitignore tags *.log') 
        storage.set_default('include_files', '*.*')
        storage.set_default('number_of_results', '1000')
        storage.set_default('match_case', false)
        storage
      end
    end
    
    class OpenCommand < Redcar::Command

      def execute
        controller = Controller.new
        tab = find_open_instance        
        if tab.nil?
          tab =  win.new_tab(HtmlTab)
          tab.html_view.controller = controller
        end
        tab.focus
      end
      
    
      class Controller
        
        def title
          "Find in project"
        end
        
        def index
          @plugin_path = File.join(File.dirname(__FILE__), "..")
          @files ||= FindInProject.storage['exclude_files']
          @dirs ||= FindInProject.storage['exclude_dirs']
          @includes ||= FindInProject.storage['include_files']
          @lines ||= FindInProject.storage['number_of_results'].to_i
          @match_case = FindInProject.storage['match_case'] if @match_case.nil?
          rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
          rhtml.result(binding)
        end
        
        def find(query, files, dirs, includes, lines, match_case)
          @query = query
          @files = files
          @dirs = dirs
          @includes = includes
          @lines = lines.to_i
          @match_case = (match_case == "true" ? true : false)
                  
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
          
          if !@match_case
            options << "-i "
          end
          
          path = Project::Manager.focussed_project.path                    
          @output = `cd #{path}; grep "#{query}" #{options} . #{head}`
          @outputs = @output.split("\n")            
          Redcar.app.focussed_window.focussed_notebook_tab.html_view.controller = self                      
          1
        end  
        
        def open_file(file, line)                    
          Project::Manager.open_file(File.join(Project::Manager.focussed_project.path, file))
          doc = Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document          
          doc.scroll_to_line(line.to_i-10)          
          doc.cursor_offset = doc.offset_at_line(line.to_i - 1)
          doc.set_selection_range(doc.cursor_line_start_offset, doc.cursor_line_end_offset)
          1
        end        
        
      end       
      
      private
      
      def find_open_instance
        all_tabs = Redcar.app.focussed_window.notebooks.map{|nb| nb.tabs }.flatten
        all_tabs.find do |t| 
          t.is_a?(Redcar::HtmlTab) and
          t.title == 'Find in project'
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
    
    class EditPreferences < Redcar::Command
      def execute             
        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "storage", "find_in_project.yaml"))
        tab.edit_view.document.mirror = mirror        
        tab.edit_view.reset_undo
        tab.focus
      end
    end
    
  end
end
