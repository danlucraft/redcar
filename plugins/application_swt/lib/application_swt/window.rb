
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window
      
      class ShellListener
        def initialize(controller)
          @controller = controller
        end
        
        def shell_closed(_)
          @controller.swt_event_closed!
        end

        def shell_activated(_); end
        def shell_deactivated(_); end
        def shell_deiconified(_); end
        def shell_iconified(_); end
      end
      
      def initialize(window)
        @window = window
        create_shell
        create_tab_folder
        add_listeners
      end
      
      def add_listeners
        @window.add_listener(:show,         &method(:show))
        @window.add_listener(:menu_changed, &method(:menu_changed))
        @window.add_listener(:title_changed, &method(:title_changed))
      end
        
      def show
        @shell.open
        @shell.text = window.title
      end
      
      def menu_changed(menu)
        @menu_controller = ApplicationSWT::Menu.new(self, menu)
        shell.menu_bar = @menu_controller.menu_bar
      end

      def close
        @shell.close
      end
        
      def swt_event_closed!
        # TODO: this should only close the app if it is the last window
        # on Linux or Windows (Windows 7?).
        unless Core.platform == :osx
          Redcar.gui.stop
        end
      end
      
      def title_changed(new_title)
        @shell.text = new_title
      end
        
      private
      
      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::GridLayout.new(1, false)
	@shell_listener = ShellListener.new(self)
        @shell.add_shell_listener(@shell_listener)  
      end
        
      def create_tab_folder
        @notebook = ApplicationSWT::Notebook.new(window.notebook, @shell)
      end
    end
  end
end
