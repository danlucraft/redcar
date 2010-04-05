
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window, :shell_listener
      
      class ShellListener
        def initialize(controller)
          @win = controller.window
        end
        
        def shell_closed(e)
          unless Redcar.app.events.ignore?(:window_close, @win)
            e.doit = false
            Redcar.app.events.create(:window_close, @win)
          end
        end

        def shell_activated(e)
          unless Redcar.app.events.ignore?(:window_focus, @win)
            e.doit = false
            Redcar.app.events.create(:window_focus, @win)
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
        create_sashes(window)
        new_notebook(window.notebooks.first)
        add_listeners
        create_treebook_controller
        reset_sash_widths
        @treebook_unopened = true
        set_icon File.join(Redcar.root, %w(plugins application icons redcar_icon_beta.png))
      end

      def add_listeners
        @window.add_listener(:show,          &method(:show))
        @window.add_listener(:refresh_menu,  &method(:refresh_menu))
        @window.add_listener(:popup_menu,    &method(:popup_menu))
        @window.add_listener(:popup_menu_with_numbers, &method(:popup_menu_with_numbers))
        @window.add_listener(:title_changed, &method(:title_changed))
        @window.add_listener(:new_notebook,  &method(:new_notebook))
        @window.add_listener(:notebook_removed,  &method(:notebook_removed))
        @window.add_listener(:closed,        &method(:closed))
        method = method(:notebook_orientation_changed)
        @window.add_listener(:notebook_orientation_changed, &method)
        @window.add_listener(:focussed,      &method(:focussed))
        @window.add_listener(:speedbar_opened, &method(:speedbar_opened))
        @window.add_listener(:speedbar_closed, &method(:speedbar_closed))
        
        @window.treebook.add_listener(:tree_added) do
          if @treebook_unopened
            reset_sash_widths
            @treebook_unopened = false
          end
        end
        
        @window.treebook.add_listener(:tree_removed) do
          reset_sash_widths
        end
        @shell.add_key_listener(KeyListener.new(self))
      end
          
      class KeyListener
        def initialize(edit_view_swt)
          @edit_view_swt = edit_view_swt
        end
        
        def key_pressed(key_event)
        p key_event
          if key_event.character == Swt::SWT::TAB
          p :tab_pressedwin
          elsif key_event.character == Swt::SWT::ESC
          p :esc_pressedwin
          end
        end
        
        def verify_key(key_event)
        p :verkey
          if key_event.character == Swt::SWT::TAB
          p :tab_pressed
          key_event.doit = false
          end
        end
        
        def key_released(key_event)
        end
      end
      
      def create_treebook_controller
        treebook = @window.treebook
        controller = ApplicationSWT::Treebook.new(
          @tree_composite, 
          @tree_layout, 
          treebook)
        treebook.controller = controller
      end
      
      def show
        @shell.open
        @shell.text = window.title
      end
      
      def refresh_menu
        @menu_controller = ApplicationSWT::Menu.new(self, @window.menu, @window.keymap, Swt::SWT::BAR)
        shell.menu_bar = @menu_controller.menu_bar
      end
      
      def set_icon(path)
         icon = Swt::Graphics::Image.new(ApplicationSWT.display, path)
         shell.image = icon
       end

      def bring_to_front
        @shell.set_minimized(false) # unminimize, just in case
        @shell.redraw
        if Redcar.platform == :windows
          require File.dirname(__FILE__) + '/bring_to_front'
          BringToFront.bring_window_to_front self.shell.handle          
        end
        @shell.force_active # doesn't do anything, really
        @shell.set_active
      end        
      
      def popup_menu(menu)
        menu.controller = ApplicationSWT::Menu.new(self, menu, nil, Swt::SWT::POP_UP)
        menu.controller.show
      end
      
      def popup_menu_with_numbers(menu)
        menu.controller = ApplicationSWT::Menu.new(self, menu, nil, Swt::SWT::POP_UP, :numbers => true)
        menu.controller.show
      end
      
      def speedbar_opened(speedbar)
        speedbar.controller = ApplicationSWT::Speedbar.new(@window, right_composite, speedbar)
      end
      
      def speedbar_closed(speedbar)
        speedbar.controller.close
      end
      
      def title_changed(new_title)
        @shell.text = new_title
      end
      
      def new_notebook(notebook_model)
        notebook_controller = ApplicationSWT::Notebook.new(notebook_model, @notebook_sash)
        reset_notebook_sash_widths
      end
      
      def notebook_removed(notebook_model)
        notebook_controller = notebook_model.controller
        @notebook_handlers[notebook_model].each do |h|
          notebook_controller.remove_listener(h)
        end
        notebook_controller.dispose
        reset_notebook_sash_widths
      end
      
      def notebook_orientation_changed(new_orientation)
        orientation = horizontal_vertical(new_orientation)
        @notebook_sash.setOrientation(orientation)
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
        
      private
      
      SASH_WIDTH = 5
      TREEBOOK_WIDTH = 20
      
      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::GridLayout.new(1, false)
      	@shell_listener = ShellListener.new(self)
        @shell.add_shell_listener(@shell_listener)
        ApplicationSWT.register_shell(@shell)
      end
      
      def create_sashes(window_model)
        orientation = horizontal_vertical(window_model.notebook_orientation)
        @sash     = Swt::Custom::SashForm.new(@shell, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
      	@sash.setLayoutData(grid_data)
      	@sash.setSashWidth(0)
      	
      	@tree_composite = Swt::Widgets::Composite.new(@sash, Swt::SWT::NONE)
      	@tree_layout = Swt::Custom::StackLayout.new
      	@tree_composite.setLayout(@tree_layout)
      	button = Swt::Widgets::Button.new(@tree_composite, Swt::SWT::PUSH)
      	button.setText("Button in pane2")
      	@tree_layout.topControl = button
      	
      	@right_composite = Swt::Widgets::Composite.new(@sash, Swt::SWT::NONE)
      	@grid_layout = Swt::Layout::GridLayout.new(1, false)
        @grid_layout.verticalSpacing = 0
        @grid_layout.marginHeight = 0
        @grid_layout.horizontalSpacing = 0
        @grid_layout.marginWidth = 0
      	@right_composite.setLayout(@grid_layout)
      	
        @notebook_sash     = Swt::Custom::SashForm.new(@right_composite, orientation)
        #grid_data = Swt::Layout::GridData.new
        #grid_data.grabExcessHorizontalSpace = true
        #grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
        #grid_data.grabExcessVerticalSpace = true
        #grid_data.verticalAlignment = Swt::Layout::GridData::FILL
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
      	@notebook_sash.setLayoutData(grid_data)
      	@notebook_sash.setSashWidth(SASH_WIDTH)
      end

      attr_reader :right_composite      
      
      def horizontal_vertical(symbol)
        case symbol
        when :horizontal
          Swt::SWT::HORIZONTAL
        when :vertical
          Swt::SWT::VERTICAL
        end
      end
      
      def reset_sash_widths
        if @window.treebook.trees.any?
          @sash.setWeights([TREEBOOK_WIDTH, 100 - TREEBOOK_WIDTH].to_java(:int))
          @sash.setSashWidth(SASH_WIDTH)
        else
          @sash.setWeights([0,100].to_java(:int))
          @sash.setSashWidth(0)
          @treebook_unopened = true
        end
      end
      
      def reset_notebook_sash_widths
        width = (100/@window.notebooks.length).to_i
        widths = [width]*@window.notebooks.length
      	@notebook_sash.setWeights(widths.to_java(:int))
      end
    end
  end
end