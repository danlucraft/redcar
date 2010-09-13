require 'find_in_project/controllers'
require 'find_in_project/commands'

module Redcar
  class FindInProject
    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Find In Project", :priority => 64 do
            item "Find In Project!", Redcar::FindInProject::OpenSearch
            item "Edit Preferences", Redcar::FindInProject::EditPreferences
          end
        end
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
