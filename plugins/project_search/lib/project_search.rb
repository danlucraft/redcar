
$:.push(File.dirname(__FILE__) + "/../vendor/lucene/lib")
require 'lucene'

require 'project_search/word_search_controller'
require 'project_search/lucene_index'
require 'project_search/lucene_refresh'
require 'project_search/binary_data_detector'
require 'project_search/commands'
require 'project_search/hit'
require 'project_search/word_search'

class ProjectSearch
  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Project" do
        group :priority => 1 do
          item "Search",  :command => ProjectSearch::WordSearchCommand
        end
      end
    end
  end
  
  def self.keymaps
    osx = Redcar::Keymap.build("main", :osx) do
      link "Cmd+Shift+F",     ProjectSearch::WordSearchCommand
    end
    linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
      link "Ctrl+Shift+F",     ProjectSearch::WordSearchCommand
    end
    [osx, linwin]
  end

  def self.toolbars
    Redcar::ToolBar::Builder.build do
      item "Search", :command => WordSearchCommand, 
        :icon => File.join(Redcar::ICONS_DIRECTORY, "application-search-result.png"), 
        :barname => :project
    end
  end

  def self.storage
    @storage ||= begin
      storage = Redcar::Plugin::Storage.new('find_in_project')
      storage.set_default('recent_queries', [])
      storage.set_default('excluded_dirs', ['.git', '.svn', '.redcar'])
      storage.set_default('excluded_files', [])
      storage.set_default('excluded_patterns', [/tags$/, /\.log$/])
      storage.set_default('literal_match', false)
      storage.set_default('match_case', false)
      storage.set_default('with_context', false)
      storage.set_default('context_lines', 2)
      storage.save
    end
  end
  
  Lucene::Config.use do |config| 
    config[:store_on_file] = true 
    config[:storage_path]  = ""
    config[:id_field]      = :id
  end
  
  
  def self.project_refresh_task_type
    LuceneRefresh
  end
  
  def self.indexes
    @indexes ||= {}
  end
end


