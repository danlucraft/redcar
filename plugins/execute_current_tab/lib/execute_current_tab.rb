module Redcar
  class ExecuteCurrentTab

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Execute", :priority => 59 do
            item "Execute Current Tab as Ruby File", ExecuteCurrentTab::Execute
            item "Execute Current Tab as Ruby File w/ Args", ExecuteCurrentTab::ExecuteWithArgs
            item "Eval Current Tab (within Redcar itself)", ExecuteCurrentTab::EmbeddedExecute
          end
        end
      end
    end

    class Execute < EditTabCommand

      TITLE = "Output"

      def execute
        path = doc.path
        current_dir = get_current_working_dir
        
        if path
          work_dir = get_path_working_dir(path)
          Dir.chdir(work_dir)
          execute_file(path)
        else
          path = File.join(Redcar.tmp_dir, "execute_file.rb")
          File.open(path, "w") { |file| file.puts doc.to_s }
          work_dir = get_path_working_dir(path)
          Dir.chdir(work_dir)
          execute_file(path)
          FileUtils.rm(path)
        end
        Dir.chdir(current_dir)
      end
      
      def get_path_working_dir(path)
        path.slice(0, path.rindex("/"))
      end
      
      def get_current_working_dir
        Dir.pwd
      end
      
      def output_tab
        tabs = win.notebooks.map {|nb| nb.tabs }.flatten
        tabs.detect {|t| t.title == TITLE} || Top::OpenNewEditTabCommand.new.run
      end

      def execute_file(path)
        command = "ruby \"#{path}\""
        output = `#{command} 2>&1`
        tab = output_tab
        title = "[#{DateTime.now}]$ #{command}"
        tab.document.text = "#{tab.document.to_s}" +
          "#{"="*title.length}\n#{title}\n#{"="*title.length}\n\n#{output}"
        tab.title = TITLE
        tab.focus
      end
    end
    
    class ExecuteWithArgs < Execute
      #override execute file method to pop up a dialog and take args
      def execute_file(path)
        user_args =Application::Dialog.input("Command Line Arguments", "Please enter args", "") 
        args = user_args[:value] == nil ? "" : user_args[:value]
        command = "ruby \"#{path}\" #{args}"
          output = `#{command} 2>&1`
          tab = output_tab
          title = "[#{DateTime.now}]$ #{command}"
          tab.document.text = "#{tab.document.to_s}" +
            "#{"="*title.length}\n#{title}\n#{"="*title.length}\n\n#{output}"
          tab.title = TITLE
          tab.focus
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
