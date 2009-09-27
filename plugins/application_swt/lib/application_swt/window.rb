
module Redcar
  class ApplicationSWT
    class Window
      include Redcar::Controller
      
      attr_reader :shell
      
      def initialize
        create_shell
        create_tab_folder
      end

        
      def show
        @shell.open
        @shell.text = @model.title
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
        @tabFolder = Swt::Custom::CTabFolder.new(@shell, folder_style)
    		@tabFolder.set_layout_data(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
    		@tabFolder.pack
      end

    end
  end
end
