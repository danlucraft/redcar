require 'ctags/select_tag_dialog'

module Redcar

  # = CTags plugin
  #
  # Generates tag file from code of current project
  # using [ctags-exuberant](http://ctags.sourceforge.net/)
  # Knows how search selected text in "tags" file.
  #
  class CTags

    # This method is run as Redcar is booting up.
    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          sub_menu "Tags" do
            item "Go To Difinition", CTags::GoToTagCommand
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

    def self.file_path
      File.join(Redcar::Project.focussed_project_path, 'tags')
    end
    
    def self.tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path[path] ||= begin
        tags = {}
        File.read(path).each_line do |line|
          key, file, regexp = line.split("\t")
          tags[key] ||= []
          tags[key] << { :file => file, :regexp => regexp[2..-5] }
        end
        tags
      end
    end
    
    def self.clear_tags_for_path(path)
      @tags_for_path ||= {}
      @tags_for_path.delete(path)
    end

    # Generate ./ctags file
    #
    class GenerateCtagsCommand < Redcar::Command
      def execute
        if ctags_binary
          puts "=> Building ctags for project with #{ctags_binary}"
          puts "=> Output is: #{CTags.file_path}"
          file_path = CTags.file_path
          command = "#{ctags_binary} -o #{file_path} -R #{Redcar::Project.focussed_project_path}"
          Redcar.logger.debug command
          Thread.new do
            system(command) 
            CTags.clear_tags_for_path(file_path)
          end.join
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

        @ctags_dir ||= ENV['PATH'].split(':').detect do |path|
          File.exist?(File.join(path, bin_name))
        end

        @ctags_dir ? File.join(@ctags_dir, bin_name) : false
      end
    end # GenerateCtagsCommand

    class GoToTagCommand < EditTabCommand

      def execute
        if doc.selection?
          handle_tag(doc.selected_text)
        else
          # TODO try automagically figure out pattern for search
          # Document
          # autodetect_token(doc.get_line(doc.cursor_line), )
          log("Current line: #{doc.get_line(doc.cursor_line)}")
          log("Cursor offset: #{doc.cursor_offset}")
        end

      end

      def handle_tag(token = '')
        matches = find_tag(token)
        case matches.size
        when 0
          Application::Dialog.message_box(win, "There is no definition for '#{token}' in tags file...")
        when 1
          log(matches.to_yaml)
          go_definition(matches.first)
        else
          open_select_tag_dialog(matches)
        end
      end

      def find_tag(tag)
        CTags.tags_for_path(CTags.file_path)[tag] || []
      end

      def go_definition(match)
        path   = match[:file]
        if tab = Redcar::Project.open_file_tab(path)
          tab.focus
        else
          Redcar::Project.open_file(path)
        end
        regstr = "^#{Regexp.escape(match[:regexp])}$"
        regexp = Regexp.new(regstr)
        log(regexp)
        Redcar::Top::FindNextRegex.new(regexp, true).run
      end

      def open_select_tag_dialog(matches)
        # show 10 files for now...
        # TODO make dialog like in project find file
        CTags::SelectTagDialog.new(matches).open
        # Application::Dialog.message_box(win, matches[0..10].collect { |m| m[:file] }.join("\n"))
      end

      def log(message)
        puts("==> Ctags: #{message}")
      end
    end # GoToTagCommand
  end # CTags
end # Redcar