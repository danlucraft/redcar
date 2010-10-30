
$:.push(File.dirname(__FILE__) + "/../vendor/lucene/lib")
require 'lucene'

require 'project_search/controller'
require 'project_search/lucene_index'
require 'project_search/binary_data_detector'

class ProjectSearch
  
  Lucene::Config.use do |config| 
    config[:store_on_file] = true 
    config[:storage_path]  = ""
    config[:id_field]      = :id
  end
  
  class LuceneRefresh < Redcar::Task
    def initialize(project)
      @project     = project
    end
    
    def description
      "#{@project.path}: refresh index"
    end
    
    def execute
      return if @project.remote?
      unless index = ProjectSearch.indexes[@project.path]
        p :creating_index
        index = ProjectSearch::LuceneIndex.new(@project)
        ProjectSearch.indexes[@project.path] = index
      end
      index.update
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


