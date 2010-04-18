
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
          item "Go to declaration", Declarations::GoToTagCommand
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

    def self.file_path(project)
      ::File.join(project.path, 'tags')
    end
    
    class ProjectRefresh < Task
      def initialize(project, a, m, d)
        @added_files, @modified_files, @deleted_files = a, m, d
        @project = project
        @should_not_update = ((num_changes == 0) or (
          @added_files.length + @deleted_files.length == 0 and 
          @modified_files.length == 1 and 
          @modified_files.first =~ /tags$/
        ))
      end
      
      def description
        if @should_not_update
          "#{@project.path}: reparse 0 files for declarations"
        else
          "#{@project.path}: reparse #{num_changes} files for declarations"
        end
      end
      
      def execute
        return if @should_not_update
        file = Declarations::File.new(Declarations.file_path(@project))
        file.add_tags_for_paths(@added_files)        
        file.remove_tags_for_paths(@modified_files + @deleted_files)
        file.add_tags_for_paths(@modified_files)
        file.dump
        Declarations.clear_tags_for_path(file.path)
      end
      
      private
      
      def num_changes
        @added_files.length + @modified_files.length + @deleted_files.length
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
      Redcar::Top::FindNextRegex.new(regexp, true).run
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
        Declarations.tags_for_path(Declarations.file_path(Project::Manager.focussed_project))[tag] || []
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
