module Redcar
  class ExecuteCurrentTab

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Execute" do
            item "Execute Current Tab as Ruby File", ExecuteCurrentTab::Execute
            item "Eval Current Tab (within Redcar itself)", ExecuteCurrentTab::EmbeddedExecute
          end
        end
      end
    end

    def self.keymaps
      [Keymap.build("main", [:osx, :linux, :windows]) { 
        link "Ctrl+R", ExecuteCurrentTab::Execute 
        link "Ctrl+Shift+R", ExecuteCurrentTab::EmbeddedExecute 
      }]
    end

    class Execute < EditTabCommand

      def execute
        path = doc.path
        if path
          execute_file(path)
        else
          path = File.join(Redcar.tmp_dir, "execute_file.rb")
          File.open(path, "w") { |file| file.puts doc.to_s }
          execute_file(path)
          FileUtils.rm(path)
        end
      end

      def execute_file(path)
        command = "ruby \"#{path}\" 2>&1"
        output = `#{command}`
        new_tab = Top::NewCommand.new.run          
        title = "Output from #{command}"
        new_tab.document.text = title + "\n" + "="*title.length + "\n\n" + output
        new_tab.title = 'Output'
      end
    end

    class EmbeddedExecute < EditTabCommand

      def execute
        out = doc.get_all_text
        if out
          begin
            eval(out, TOPLEVEL_BINDING, doc.path || doc.title || '')
          rescue Object => e
            Application::Dialog.message_box(
							"#{e.class}\n#{e.message}",
							:type => :error )
              
          end
        end
      end

    end

  end

end
