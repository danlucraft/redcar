require 'find_in_project/controllers'
require 'find_in_project/commands'
require 'find_in_project/engines/ack'
require 'find_in_project/engines/grep'

module Redcar
  class FindInProject
    def self.keymaps
      osx = Keymap.build('main', :osx) do
        link "Cmd+Shift+F", FindInProject::OpenSearch
      end

      linwin = Keymap.build('main', [:linux, :windows]) do
        link "Ctrl+Shift+F", FindInProject::OpenSearch
      end

      [linwin, osx]
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Find In Project" do
            item "Find In Project!", Redcar::FindInProject::OpenSearch
            item "Edit Preferences", Redcar::FindInProject::EditPreferences
          end
        end
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('find_in_project')
        unless storage['search_engine']
          engines = Array.new

          # TODO: Ack search engine is broken, don't auto detect it yet
          #ack = Redcar::FindInProject::Engines::Ack.detect
          #if ack
          #  storage.set_default('ack_path', ack)
          #  engines << 'ack'
          #end

          grep = Redcar::FindInProject::Engines::Grep.detect
          if grep
            storage.set_default('grep_path', grep)
            engines << 'grep'
          end

          storage.set_default('search_engine', engines.first)
        end
        storage.set_default('recent_queries', %w{})
        storage.set_default('recent_options', %w{})
        storage.save
      end
    end
  end
end
