module Redcar
  class ExecuteCurrentTab

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Execute" do
            item "Execute Current Tab as Ruby", ExecuteCurrentTab::Execute
            item "Execute Current Tab (within Redcar interpreter)", ExecuteCurrentTab::EmbeddedExecute
          end
        end
      end
    end

    def self.keymaps
      [Keymap.build("main", :osx) { link "Ctrl+R", ExecuteCurrentTab::Execute }]
    end

    class Execute < Command

      def execute
        doc = win.focussed_notebook_tab_document
        path = doc.path if doc
        if path
          command = "ruby #{path} 2>&1"
          out = `#{command}`
          new_tab = Top::NewCommand.new.run
          new_tab.document.text = "***** generated output from #{command} ***\n" + out
        else
          puts 'unable to execute'
        end
      end

    end

    class EmbeddedExecute < Command

      def execute
        doc = win.focussed_notebook_tab_document
        out = doc.get_all_text if doc
        if out
          eval out, TOPLEVEL_BINDING, doc.path || doc.title || ''
        else
          puts 'unable to execute embedded'
        end
      end

    end

  end

end
