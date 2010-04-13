
require 'ctags/completion_source'
require 'ctags/declarations'
require 'ctags/select_tag_dialog'
require 'tempfile'

module Redcar
  # Integrates [ctags-exuberant](http://ctags.sourceforge.net/) into Redcar. ctags
  # builds an index of method and class definitions, which allows for jump to 
  # definition commands.
  class CTags
    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          sub_menu "Tags" do
            item "Go To Definition", CTags::GoToTagCommand
            item "Generate Tags (ctags)", CTags::GenerateCtagsCommand
          end
        end
      end
    end

    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+T", CTags::GoToTagCommand
      end

      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+T", CTags::GoToTagCommand
      end

      [linwin, osx]
    end

    def self.autocompletion_source_types
      [CTags::CompletionSource]
    end

    def self.file_path(project_path=Project::Manager.focussed_project.path)
      File.join(project_path, 'tags')
    end

    def self.tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path[path] ||= begin
        tags = {}
        File.read(path).each_line do |line|
          key, file, *match = line.split("\t")
          if [key, file, match].all? { |el| !el.nil? && !el.empty? }
            tags[key] ||= []
            tags[key] << { :file => file, :match => match.join("\t").chomp }
          end
        end
        tags
      rescue Errno::ENOENT
        {}
      end
    end
    
    def self.clear_tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path.delete(path)
    end

    def self.go_to_definition(match)
      path = match[:file]
      Project::Manager.open_file(path)
      regexp = Regexp.new(Regexp.escape(match[:match]))
      Redcar::Top::FindNextRegex.new(regexp, true).run
    end

    # Generate "tags" file for current project
    class GenerateCtagsCommand < Redcar::Command

      def execute
        Thread.new do
          s = Time.now
          tempfile = Tempfile.new('tags')
          tempfile.close # we need just temp path here
          decl = Declarations.new(tempfile.path)
          file_path = Project::Manager.focussed_project.path
          decl.parse(Dir[file_path + "/**/*.rb"])
          decl.parse(Dir[file_path + "/**/*.java"])
          decl.dump
          FileUtils.mv(tempfile.path, CTags.file_path)
          CTags.clear_tags_for_path(file_path)
          puts "generated tags file in #{Time.now - s}s"
        end
      end

    end

    class GoToTagCommand < EditTabCommand

      def execute
        if doc.selection?
          handle_tag(doc.selected_text)
        else
          log("TODO: autodetect word under cursor")
          log("Current line: #{doc.get_line(doc.cursor_line)}")
          log("Cursor offset: #{doc.cursor_offset}")
        end
      end

      def handle_tag(token = '')
        matches = find_tag(token)
        case matches.size
        when 0
          Application::Dialog.message_box("There is no definition for '#{token}' in the tags file.")
        when 1
          Redcar::CTags.go_to_definition(matches.first)
        else
          open_select_tag_dialog(matches)
        end
      end

      def find_tag(tag)
        CTags.tags_for_path(CTags.file_path)[tag] || []
      end

      def open_select_tag_dialog(matches)
        CTags::SelectTagDialog.new(matches).open
      end

      def log(message)
        puts("==> Ctags: #{message}")
      end
    end
  end
end
