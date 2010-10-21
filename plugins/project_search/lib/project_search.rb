
$:.push(File.dirname(__FILE__) + "/../vendor/lucene/lib")
require 'lucene'

require 'project_search/controller'

class ProjectSearch
  
  Lucene::Config.use do |config| 
    config[:store_on_file] = true 
    config[:storage_path]  = ""
    config[:id_field]      = :id
  end
  
  class LuceneRefresh < Redcar::Task
    def initialize(project)
      @file_list   = project.file_list
      @project     = project
    end
    
    def description
      "#{@project.path}: refresh index"
    end
    
    def execute
      return if @project.remote?
      files = @file_list.all_files
      files.delete(::File.join(@project.config_dir, 'tags'))
      Lucene::Transaction.run do 
        index = 
          (ProjectSearch.indexes[@project.path] ||= 
            Lucene::Index.new(File.join(@project.config_dir, "lucene")) )
        index.field_infos[:contents][:store] = true 
        index.field_infos[:contents][:tokenized] = true        files.each do |fn|
          if fn =~ /rb$/
            index << { :id => fn, :contents => File.read(fn) }
          end
        end
      end
    end
  end
  
  def self.project_refresh_task_type
    LuceneRefresh
  end
  
  class SearchCommand < Redcar::Command
    def find_open_instance
      all_tabs = Redcar.app.focussed_window.notebooks.map { |nb| nb.tabs }.flatten
      all_tabs.find do |t|
        t.is_a?(Redcar::HtmlTab) && t.title == ProjectSearch::Controller.new.title
      end
    end
      
    def execute
      if Redcar::Project::Manager.focussed_project
        if (tab = find_open_instance)
          tab.html_view.controller = tab.html_view.controller # refresh
        else
          tab = win.new_tab(Redcar::HtmlTab)
          tab.html_view.controller = ProjectSearch::Controller.new
        end
        tab.focus
      else
        # warning
        Application::Dialog.message_box("You need an open project to be able to use Find In Project!", :type => :error)
      end
      return
    end
  end

  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Project" do
        item "Search", :command => ProjectSearch::SearchCommand
      end
    end
  end

  def self.indexes
    @indexes ||= {}
  end
end


