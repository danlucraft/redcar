module Redcar
  class StripTrailingSpaces
    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('strip_trailing_spaces_plugin')
        storage.set_default('enabled', false)
        storage
      end
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Strip Trailing Spaces" do
            if (Redcar::StripTrailingSpaces.storage['enabled'])
              item "Disable", DisablePlugin
            else
              item "Enable", EnablePlugin
            end
          end
        end
      end
    end

    def self.before_save(doc)
      if (doc.mirror.is_a?(Redcar::Project::FileMirror) && storage['enabled'])
        # Read cursor position and adjust line offset
        cursor_line = doc.cursor_line
        top_line = doc.smallest_visible_line
        line_offset = doc.cursor_line_offset
        line = doc.get_line(cursor_line)
        line_offset = line.rstrip.size if line_offset > line.rstrip.size

        doc.text = doc.to_s.split("\n").each{|s| s.rstrip!}.join("\n") + "\n"

        # Adjust cursor offset and make visible
        doc.scroll_to_line_at_top(top_line)
        offset=doc.offset_at_line(cursor_line) + line_offset
        doc.cursor_offset=offset
        doc.ensure_visible(offset)
      end
    end

    class EnablePlugin < Redcar::Command
      def execute
        Redcar::StripTrailingSpaces.storage['enabled'] = true
        Redcar.app.refresh_menu!
      end
    end

    class DisablePlugin < Redcar::Command
      def execute
        Redcar::StripTrailingSpaces.storage['enabled'] = false
        Redcar.app.refresh_menu!
      end
    end
  end
end
