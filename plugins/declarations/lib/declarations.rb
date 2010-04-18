
require 'declarations/completion_source'
require 'declarations/parser'
require 'declarations/select_tag_dialog'
require 'tempfile'

module Redcar
  class Declarations
    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          sub_menu "Declarations" do
            item "Go to declaration", Declarations::GoToTagCommand
            item "Regenerate declarations", Declarations::GenerateDeclarationsCommand
          end
        end
      end
    end

    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+T", Declarations::GoToTagCommand
      end

      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+T", Declarations::GoToTagCommand
      end

      [linwin, osx]
    end

    def self.autocompletion_source_types
      [Declarations::CompletionSource]
    end

    def self.file_path(project_path=Project::Manager.focussed_project.path)
      File.join(project_path, 'tags')
    end
    
    class ProjectRefresh < Task
      def initialize(*args)
        p args.map{|a| a.length}
      end
      
      def execute
        GenerateDeclarationsCommand.new.run
      end
    end
    
    def self.project_refresh_task_type
      ProjectRefresh
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

    class GenerateDeclarationsCommand < Redcar::Command

      def execute
        s = Time.now
        tempfile = Tempfile.new('tags')
        tempfile.close # we need just temp path here
        parser = Declarations::Parser.new(tempfile.path)
        file_path = Project::Manager.focussed_project.path
        parser.parse(Dir[file_path + "/**/*.rb"])
        parser.parse(Dir[file_path + "/**/*.java"])
        parser.dump
        FileUtils.mv(tempfile.path, Declarations.file_path)
        Declarations.clear_tags_for_path(File.join(file_path, "tags"))
        puts "generated tags file in #{Time.now - s}s"
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
          Redcar::Declarations.go_to_definition(matches.first)
        else
          open_select_tag_dialog(matches)
        end
      end

      def find_tag(tag)
        Declarations.tags_for_path(Declarations.file_path)[tag] || []
      end

      def open_select_tag_dialog(matches)
        Declarations::SelectTagDialog.new(matches).open
      end

      def log(message)
        puts("==> Ctags: #{message}")
      end
    end
  end
end
