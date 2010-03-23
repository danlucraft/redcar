module Redcar
  # This class is your plugin. Try adding new commands in here
  # and putting them in the menus.
  class CTags

    # This method is run as Redcar is booting up.
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
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

    # Generate ./ctags file
    #
    class GenerateCtagsCommand < Redcar::Command
      def execute
        if ctags_binary
          puts "=> Building ctags for project with #{ctags_binary}"
          puts "=> Output is: #{Dir.pwd}"
          ctags_output_path = File.join(Redcar::Project.focussed_project_path, 'tags')
          command = "#{ctags_binary} -o #{ctags_output_path} -R #{Redcar::Project.focussed_project_path}"
          Redcar.logger.debug command
          Thread.new { system(command) }.join
        else
          Application::Dialog.message_box(win, "No ctags executable found in your $PATH.
                                                Please intall it before use this command.")
        end
      end

      def ctags_binary
        bin_name = 'ctags'
        bin_name += '.exe' if Redcar.platform == :windows

        @ctags_dir ||= ENV['PATH'].split(':').detect do |path|
          File.exist?(File.join(path, bin_name))
        end

        @ctags_dir ? File.join(@ctags_dir, bin_name) : false
      end
    end

    class GoToTagCommand < EditTabCommand
      
      def log(message)
        puts("==> Ctags: #{message}")
      end
      
      def execute
        puts('Trying to match tag')
        matches = false
            
        if doc.selection?
          log("Searching for selected text: #{doc.selected_text}")
          matches = find_tag(doc.selected_text)
        else
          # TODO try to figure out pattern for search
          log("Current line: #{doc.get_line(doc.cursor_line)}")
        end
        
        if matches
          log("Mathes: " + matches.to_yaml)
          
          if matches.size == 1 # just open file
            path  = matches.first[:file]
            regex = Regex.compile(matches.first[:regex])
            log("Opening file: #{path}")

            if tab = Redcar::Project.open_file_tab(path)
              tab.focus
              # TODO find line by regex!!
            else
              Redcar::Project.open_file(path)
            end
          elsif matches.size > 1
            # show 10 files for now...
            # TODO make dialog like in project find file
            Application::Dialog.message_box(win, matches[0..10].collect { |m| m[:file] }.join("\n"))
          else
            log('matches size is 0? wtf?')
          end
        else
          log("nothing matched")
        end
      end
      
      def find_tag(tag)
        tags_hash[tag]
      end
      
      def tags_hash
        return @tags unless @tags.nil?
        @tags = {}
        data = File.read(File.join(Dir.pwd, 'tags'))
        data.each_line do |line|
          key, file, regex = line.split("\t")
          Redcar.logger.debug(key)
          @tags[key] ||= []
          @tags[key] << { :file => file, :regex => regex[0..-3] }
        end
        @tags
      end
    end
  end
end