
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window
      
      def initialize(window)
        @window = window
        create_shell
        create_tab_folder
        ApplicationSWT::Notebook.new(window.notebook, @tab_folder)
      end
        
      def show
        @shell.open
        @shell.text = window.title
      end

      def close
        @shell.close
      end
      
      def menu_changed(menu)
        @menu_controller = ApplicationSWT::Menu.new(self, menu)
        shell.menu_bar = @menu_controller.menu_bar
      end
        
      private
      
      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::GridLayout.new(1, false)
      end
        
      def create_tab_folder
        folder_style = Swt::SWT::BORDER + Swt::SWT::CLOSE
        @tab_folder = Swt::Custom::CTabFolder.new(@shell, folder_style)
    		@tab_folder.set_layout_data(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
    		@tab_folder.pack
      end

    end
  end
end
