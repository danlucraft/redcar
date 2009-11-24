
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
      	@notebook_handlers = Hash.new {|h,k| h[k] = []}
        create_shell
        create_sash(window)
        new_notebook(window.notebooks.first)
        add_listeners
      end
      
      def add_listeners
        @window.add_listener(:show,          &method(:show))
        @window.add_listener(:menu_changed,  &method(:menu_changed))
        @window.add_listener(:title_changed, &method(:title_changed))
        @window.add_listener(:new_notebook,  &method(:new_notebook))
        @window.add_listener(:notebook_removed,  &method(:notebook_removed))
        @window.add_listener(:notebook_orientation_changed, &method(:notebook_orientation_changed))
      end
        
      def show
        @shell.open
        @shell.text = window.title
      end
      
      def menu_changed(menu)
        @menu_controller = ApplicationSWT::Menu.new(self, menu)
        shell.menu_bar = @menu_controller.menu_bar
      end
      
      def title_changed(new_title)
        @shell.text = new_title
      end
      
      def new_notebook(notebook_model)
        notebook_controller = ApplicationSWT::Notebook.new(notebook_model, @sash)
        width = (100/@window.notebooks.length).to_i
        widths = [width]*@window.notebooks.length
      	@sash.setWeights(widths.to_java(:int))
      	h = notebook_controller.add_listener(:swt_focus_gained) do |notebook|
          @window.focussed_notebook = notebook
        end
        @notebook_handlers[notebook_model] << h
      end
      
      def notebook_removed(notebook_model)
        notebook_controller = notebook_model.controller
        @notebook_handlers[notebook_model].each do |h|
          notebook_controller.remove_listener(h)
        end
        notebook_controller.dispose
        width = (100/@window.notebooks.length).to_i
        widths = [width]*@window.notebooks.length
      	@sash.setWeights(widths.to_java(:int))
      end
      
      def notebook_orientation_changed(new_orientation)
        orientation = horizontal_vertical(new_orientation)
        @sash.setOrientation(orientation)
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
        
      private
      
      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::GridLayout.new(1, false)
      	@shell_listener = ShellListener.new(self)
        @shell.add_shell_listener(@shell_listener)  
      end
      
      def create_sash(window_model)
        orientation = horizontal_vertical(window_model.notebook_orientation)
        @sash     = Swt::Custom::SashForm.new(@shell, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
      	@sash.setLayoutData(grid_data)
      	@sash.setSashWidth(10)
      end
      
      def horizontal_vertical(symbol)
        case symbol
        when :horizontal
          Swt::SWT::HORIZONTAL
        when :vertical
          Swt::SWT::VERTICAL
        end
      end
    end
  end
end
