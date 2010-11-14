require 'find_in_project/controllers'
require 'find_in_project/commands'

module Redcar
  class FindInProject
    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Edit" do
          sub_menu "Search" do
            item "Find In Project!", Redcar::FindInProject::OpenSearch
          end
        end
      end
    end
    
  def self.toolbars
    ToolBar::Builder.build do
      item "Find in Project", :command => OpenSearch, :icon => File.join(Redcar::ICONS_DIRECTORY, "application-search-result.png"), :barname => :project
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
  end
end
