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
      [Keymap.build("main", [:osx, :linux, :windows]) { link "Ctrl+R", ExecuteCurrentTab::Execute }]
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
          new_tab.title= 'exec output'
        else
          puts 'unable to execute--maybe you need to save it first, so it has a filename?'
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
          puts 'unable to eval embedded'
        end
      end

    end

  end

end
