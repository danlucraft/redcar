
require 'declarations/completion_source'
require 'declarations/file'
require 'declarations/parser'
require 'declarations/select_tag_dialog'
require 'tempfile'

module Redcar
  class Declarations
    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          item "Go to declaration", :command => Declarations::GoToTagCommand, :priority => 30
        end
      end
    end

    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+G", Declarations::GoToTagCommand
      end

      osx = Keymap.build("main", :osx) do
        link "Cmd+G", Declarations::GoToTagCommand
      end

      [linwin, osx]
    end

    def self.autocompletion_source_types
      [] #[Declarations::CompletionSource]
    end

    def self.file_path(project)
      ::File.join(project.config_dir, 'tags')
    end
    
    class ProjectRefresh < Task
      def initialize(project)
        @file_list   = project.file_list
        @project     = project
      end
      
      def description
        "#{@project.path}: reparse files for declarations"
      end
      
      def execute
        file = Declarations::File.new(Declarations.file_path(@project))
        file.update_files(@file_list)
        file.dump
        Declarations.clear_tags_for_path(file.path)
      end
    end
    
    def self.project_refresh_task_type
      ProjectRefresh
    end

    def self.tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path[path] ||= begin
        tags = {}
        ::File.read(path).each_line do |line|
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
      DocumentSearch::FindNextRegex.new(regexp, true).run
    end

    class GoToTagCommand < EditTabCommand

      def execute
        if doc.selection?
          handle_tag(doc.selected_text)
        else
          range = doc.current_word_range
          handle_tag(doc.get_slice(range.first, range.last))
        end
      end

      def handle_tag(token = '')
        tags_path = Declarations.file_path(Project::Manager.focussed_project)
        unless ::File.exist?(tags_path)
          Application::Dialog.message_box("The declarations file 'tags' has not been generated yet.")
          return
        end
        matches = find_tag(tags_path, token)
        case matches.size
        when 0
          Application::Dialog.message_box("There is no declaration for '#{token}' in the 'tags' file.")
        when 1
          Redcar::Declarations.go_to_definition(matches.first)
        else
          open_select_tag_dialog(matches)
        end
      end

      def find_tag(tags_path, tag)
        Declarations.tags_for_path(tags_path)[tag] || []
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
