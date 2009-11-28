
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window, :shell_listener
      
      class ShellListener
        def initialize(controller)
          @controller = controller
        end
        
        def shell_closed(e)
          unless @in_close_operation
            @in_close_operation = true
            e.doit = false
            @controller.swt_event_closed
            @in_close_operation = false
          end
        end

        def shell_activated(e)
          unless @in_activate_operation
            @in_activate_operation = true
            e.doit = false
            @controller.swt_event_activated
            @in_activate_operation = false
          end
        end
        
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
        @window.add_listener(:closed,        &method(:closed))
        method = method(:notebook_orientation_changed)
        @window.add_listener(:notebook_orientation_changed, &method)
        @window.add_listener(:focussed,      &method(:focussed))
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
      
      def focussed(_)
        @shell.set_active
      end
      
      def closed(_)
        @shell.close
        @menu_controller.close
      end
      
      def dispose
        @shell.dispose
        @menu_controller.close
      end
        
      def swt_event_closed
        @window.close
      end
        
      def swt_event_activated
        @window.focus
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
