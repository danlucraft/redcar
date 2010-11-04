
module Redcar
  class StripTrailingSpaces
    def self.enabled?
      Redcar::StripTrailingSpaces.storage['enabled']
    end

    def self.enabled=(bool)
      Redcar::StripTrailingSpaces.storage['enabled'] = bool
    end

    def self.strip_blank_lines?
      Redcar::StripTrailingSpaces.storage['strip_blank_lines']
    end

    def self.strip_blank_lines=(bool)
      Redcar::StripTrailingSpaces.storage['strip_blank_lines'] = bool
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('strip_trailing_spaces_plugin')
        storage.set_default('enabled', false)
        storage.set_default('strip_blank_lines', false)
        storage
      end
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Strip Trailing Spaces", :priority => 195 do
            item "Enabled", :command => ToggleStripTrailingSpaces, :type => :check, :active => StripTrailingSpaces.enabled?
            item "Strip Blank Lines", :command => ToggleStripBlankLines, :type => :check, :active => StripTrailingSpaces.strip_blank_lines?
          end
        end
      end
    end

    def self.before_save(doc)
      if (doc.mirror.is_a?(Redcar::Project::FileMirror) && StripTrailingSpaces.enabled?)
        regex         = /[\t ]*$/ if StripTrailingSpaces.strip_blank_lines?
        regex       ||= /([^\s]+)[\t ]+$/
        doc.text = doc.get_all_text.gsub(regex, "\\1")
      end
    end

    class ToggleStripTrailingSpaces < Redcar::Command
      def execute
        StripTrailingSpaces.enabled = !StripTrailingSpaces.enabled?
      end
    end

    class ToggleStripBlankLines < Redcar::Command
      def execute
        StripTrailingSpaces.strip_blank_lines = !StripTrailingSpaces.strip_blank_lines?
      end
    end
  end
end
