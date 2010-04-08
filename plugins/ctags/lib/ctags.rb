require 'ctags/completion_source'
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

    def self.file_path(project_path=Redcar::Project.focussed_project_path)
      File.join(project_path, 'tags')
    end

    def self.tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path[path] ||= begin
        tags = {}
        File.read(path).each_line do |line|
          key, file, regexp = line.split("\t")
          if [key, file, regexp].all? { |el| !el.nil? && !el.empty? }
            tags[key] ||= []
            tags[key] << { :file => file, :regexp => regexp[2..-5] }
          end
        end
        tags
      end
    end
    
    def self.clear_tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path.delete(path)
    end

    def self.go_to_definition(match)
      path = match[:file]
      if tab = Redcar::Project.open_file_tab(path)
        tab.focus
      else
        Redcar::Project.open_file(path)
      end
      regstr = "^#{Regexp.escape(match[:regexp])}$"
      regexp = Regexp.new(regstr)
      Redcar::Top::FindNextRegex.new(regexp, true).run
    end

    # Generate "tags" file for current project
    class GenerateCtagsCommand < Redcar::Command

      #autoload :Tempfile,  'tempfile'
      
      def execute
        if ctags_binary
          Thread.new do
            tempfile = Tempfile.new('tags')
            tempfile.close # we need just temp path here
            system("#{ctags_binary} -o #{tempfile.path} -R #{Redcar::Project.focussed_project_path}")
            FileUtils.mv(tempfile.path, CTags.file_path)
            CTags.clear_tags_for_path(file_path)
          end
        else
          Application::Dialog.message_box win, <<-MESSAGE
            No ctags executable found in your $PATH.
            Please intall it before use this command.
            http://ctags.sourceforge.net/
          MESSAGE
        end
      end

      # need ctags.exe in $PATH on win
      # http://prdownloads.sourceforge.net/ctags/ctags58.zip
      # FIXME make it really cross-platform
      def ctags_binary
        bin_name = 'ctags'
        bin_name += '.exe' if Redcar.platform == :windows
        path = File.expand_path(File.join(File.dirname(__FILE__), %w(.. vendor ctags58)))
        @ctags_path ||= File.join(path, bin_name) if File.exist?(File.join(path, bin_name))
        @ctags_path || false
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
          Application::Dialog.message_box(win, "There is no definition for '#{token}' in the tags file.")
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
