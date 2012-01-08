
require 'declarations/commands'
require 'declarations/completion_source'
require 'declarations/file'
require 'declarations/parser'
require 'declarations/select_tag_dialog'
require 'tempfile'

module Redcar
  class Declarations
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          group :priority => 30 do
            item "Find declaration", :command => Declarations::OpenOutlineViewCommand
          end
        end
        
        sub_menu "Project" do
          group :priority => 60 do
            item "Go to declaration", :command => Declarations::GoToTagCommand, :priority => 30
            item "Find declaration", :command => Declarations::OpenProjectOutlineViewCommand, :priority => :first
          end
          sub_menu "Refresh", :priority => 31 do
            item "Declarations file", :command => Declarations::RebuildTagsCommand
          end
        end
      end
    end

    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Alt+G", Declarations::GoToTagCommand
        link "Ctrl+I", Declarations::OpenOutlineViewCommand
        link "Ctrl+Shift+I", Declarations::OpenProjectOutlineViewCommand
      end

      osx = Keymap.build("main", :osx) do
        link "Ctrl+Alt+G", Declarations::GoToTagCommand
        link "Cmd+I", Declarations::OpenOutlineViewCommand
        link "Cmd+Ctrl+I", Declarations::OpenProjectOutlineViewCommand
      end

      [linwin, osx]
    end

    def self.autocompletion_source_types
      [] #[Declarations::CompletionSource]
    end

    def self.file_path(project)
      ::File.join(project.config_dir, 'tags')
    end

    def self.icon_for_kind(kind)
      h = {
        :method     => :node_insert,
        :class      => :open_source_flipped,
        :attribute  => :status,
        :alias      => :arrow_branch,
        :assignment => :arrow,
        :interface  => :information,
        :closure    => :node_magnifier,
        :none       => nil
      }
      h[kind.to_sym]
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
        return if @project.remote?
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

    def self.match_kind(path, regex)
      Declarations::Parser.new.match_kind(path, regex)
    end

    def self.clear_tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path.delete(path)
    end

    def self.go_to_definition(match)      
      path = match[:file]
      Project::Manager.open_file(path)
      regexp = Regexp.new(Regexp.escape(match[:match]))
      DocumentSearch::FindNextRegex.new(regexp, true).run_in_focussed_tab_edit_view
    end
  end
end
