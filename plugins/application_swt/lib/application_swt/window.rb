
module Redcar
  class ApplicationSWT
    class Window
      attr_reader :shell, :window

      SASH_WIDTH             = 5
      TREEBOOK_WIDTH         = 200
      MINIMUM_TREEBOOK_WIDTH = 0
      VISIBLE_TREEBOOK_WIDTH = 25
      TOOLBAR_HEIGHT         = 25
      @toolbar_height        = 30

      class ShellListener
        include org.eclipse.swt.events.ShellListener

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
        set_icon
      end

      def add_listeners
        @window.add_listener(:show,          &method(:show))
        @window.add_listener(:refresh_menu,  &method(:refresh_menu))
        @window.add_listener(:refresh_toolbar,  &method(:refresh_toolbar))
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
        @window.add_listener(:enlarge_notebook, &method(:enlarge_notebook))
        @window.add_listener(:reset_notebook_widths, &method(:reset_notebook_sash_widths))
        @window.add_listener(:increase_treebook_width, &method(:increase_treebook_width))
        @window.add_listener(:decrease_treebook_width, &method(:decrease_treebook_width))

        @window.add_listener(:toggle_trees_visible, &method(:toggle_sash_widths))
        @window.treebook.add_listener(:tree_added) do
          if @treebook_unopened or not @window.trees_visible?
            reset_sash_widths
            @treebook_unopened = false
          end
        end
        @window.treebook.add_listener(:tree_focussed) do |tree|
          if @treebook_unopened or not @window.trees_visible?
            reset_sash_widths
            @treebook_unopened = false
          end
        end

        @window.treebook.add_listener(:tree_removed) do
          reset_sash_widths
        end
        @shell.add_key_listener(KeyListener.new(self))
      end

      def treebook_hidden?
        treebook_width <= VISIBLE_TREEBOOK_WIDTH
      end

      def treebook_width
        @sash.layout_data.left.offset
      end

      def default_treebook_width
        TREEBOOK_WIDTH + SASH_WIDTH
      end

      def fullscreen
        @shell.fullScreen()
      end

      def fullscreen=(value)
        @shell.setFullScreen(value)
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
        self,
        treebook)
        treebook.controller = controller
      end

      def show
        @shell.open
        @shell.text = window.title
      end

      def refresh_menu
        old_menu_bar = shell.menu_bar
        @menu_controller = ApplicationSWT::Menu.new(self, Redcar.app.main_menu(@window), Redcar.app.main_keymap, Swt::SWT::BAR)
        shell.menu_bar = @menu_controller.menu_bar
        old_menu_bar.dispose if old_menu_bar
      end

      def refresh_toolbar
        if Redcar.app.show_toolbar?
          @toolbar_controller = ApplicationSWT::ToolBar.new(self, Redcar.app.main_toolbar, Swt::SWT::HORIZONTAL | Swt::SWT::BORDER)
          @toolbar_controller.show
          @toolbar_height = @toolbar_controller.height.to_i
        else
          @toolbar_controller.hide() if @toolbar_controller
          @toolbar_height = 0
        end
        reset_sash_height
      end

      def set_icon
        shell.image = Icon.swt_image(icon_file)
      end

      def icon_file
        if Redcar::VERSION =~ /dev$/
          :redcar_icon_beta_dev
        else
          :redcar_icon_beta
        end
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
        @toolbar_controller.close if @toolbar_controller
      end

      def dispose
        @shell.dispose
        @menu_controller.close
        @toolbar_controller.close
      end

      attr_reader :right_composite, :left_composite, :tree_composite, :tree_layout, :tree_sash

      private

      def create_shell
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.layout = Swt::Layout::FormLayout.new
        @shell.add_shell_listener(ShellListener.new(self))
        @shell.add_listener Swt::SWT::Resize do |e|
          client_area = @shell.client_area
          if client_area.width < @sash.bounds.x
            @sash.layout_data.left = Swt::Layout::FormAttachment.new(0, client_area.width - SASH_WIDTH)
          end
        end
        activate_osx_fullscreen_option
        ApplicationSWT.register_shell(@shell)
      end
      
      FULL_SCREEN_SHELL_ICON = 1 << 7
      
      def activate_osx_fullscreen_option
        if Redcar.platform == :osx
          @shell.view.window.set_collection_behavior(FULL_SCREEN_SHELL_ICON)
        end
      end
      
      def create_sashes(window_model)
        orientation = horizontal_vertical(window_model.notebook_orientation)

        @left_composite = Swt::Widgets::Composite.new(@shell, Swt::SWT::NONE)
        @left_composite.layout = Swt::Layout::GridLayout.new(1, false).tap do |l|
          l.verticalSpacing = 0
          l.marginHeight = 0
          l.horizontalSpacing = 0
          l.marginWidth = 0
        end

        @sash = Swt::Widgets::Sash.new(@shell, Swt::SWT::VERTICAL)

        @right_composite = Swt::Widgets::Composite.new(@shell, Swt::SWT::NONE)
        @right_composite.layout = Swt::Layout::GridLayout.new(1, false).tap do |l|
          l.verticalSpacing = 0
          l.marginHeight = 0
          l.horizontalSpacing = 0
          l.marginWidth = 0
        end

        @sash.layout_data = Swt::Layout::FormData.new.tap do |d|
          d.left = Swt::Layout::FormAttachment.new(0, 0)
          d.top =  Swt::Layout::FormAttachment.new(0, 5 + TOOLBAR_HEIGHT)
          d.bottom = Swt::Layout::FormAttachment.new(100, 0)
        end

        @sash.add_selection_listener do |e|
          sash_rect = @sash.bounds
          shell_rect = @shell.client_area
          right = shell_rect.width - sash_rect.width - SASH_WIDTH
          e.x = [[e.x, right].min, SASH_WIDTH].max
          if (e.x != sash_rect.x)
            if @window.treebook.trees.any?
              @sash.layout_data.left = Swt::Layout::FormAttachment.new(0, e.x)
            else
              @sash.layout_data.left = Swt::Layout::FormAttachment.new(0, 0)
            end
            @shell.layout
          end
        end

        @left_composite.layout_data = Swt::Layout::FormData.new.tap do |l|
          l.left = Swt::Layout::FormAttachment.new(0, 5)
          l.right = Swt::Layout::FormAttachment.new(@sash, 0)
          l.top = Swt::Layout::FormAttachment.new(0, 5 + TOOLBAR_HEIGHT)
          l.bottom = Swt::Layout::FormAttachment.new(100, -5)
        end

        @right_composite.layout_data = Swt::Layout::FormData.new.tap do |d|
          d.left = Swt::Layout::FormAttachment.new(@sash, 0)
          d.right = Swt::Layout::FormAttachment.new(100, -5)
          d.top = Swt::Layout::FormAttachment.new(0, 5 + TOOLBAR_HEIGHT)
          d.bottom = Swt::Layout::FormAttachment.new(100, -5)
        end

        @tree_sash = Swt::Custom::SashForm.new(@left_composite, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
        @tree_sash.layout_data = grid_data

        @notebook_sash = Swt::Custom::SashForm.new(@right_composite, orientation)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
        @notebook_sash.layout_data = grid_data
        @notebook_sash.sash_width = SASH_WIDTH
      end

      def horizontal_vertical(symbol)
        case symbol
        when :horizontal
          Swt::SWT::HORIZONTAL
        when :vertical
          Swt::SWT::VERTICAL
        end
      end

      def reset_sash_widths
        @treebook_unopened = !@window.treebook.trees.any?
        width = 0
        if @window.treebook.trees.any?
          if @treebook_open_width
            width = @treebook_open_width
          else
            width = default_treebook_width
          end
        end
        set_sash_widths(width)
      end

      def toggle_sash_widths
        if treebook_hidden?
          reset_sash_widths
        else
          @treebook_open_width = treebook_width
          set_sash_widths(MINIMUM_TREEBOOK_WIDTH)
        end
      end

      def decrease_treebook_width
        width = treebook_width
        unless width < MINIMUM_TREEBOOK_WIDTH + SASH_WIDTH
          set_sash_widths(width-SASH_WIDTH)
        end
      end

      def increase_treebook_width
        set_sash_widths(treebook_width+SASH_WIDTH)
      end

      def set_sash_widths(offset)
        @sash.layout_data.left = Swt::Layout::FormAttachment.new(0, offset)
        @shell.layout
      end

      def reset_notebook_sash_widths
        width = (100/@window.notebooks.length).to_i
        widths = [width]*@window.notebooks.length
        @notebook_sash.setWeights(widths.to_java(:int))
      end

      def enlarge_notebook(index=0)
        if @window.notebooks.length > 1
          widths = @notebook_sash.getWeights
          small = index == 0 ? 1 : 0
          total = widths[index] + widths[small]
          unless widths[index]/total > 0.95
            widths[small] = widths[small].to_i - SASH_WIDTH
            widths[index] = widths[index].to_i + SASH_WIDTH
            @notebook_sash.setWeights(widths.to_a.to_java(:int))
          end
        end
      end

      def reset_sash_height
        @sash.layout_data.top =  Swt::Layout::FormAttachment.new(0, @toolbar_height.to_i)
        @left_composite.layout_data.top = Swt::Layout::FormAttachment.new(0, 5 + @toolbar_height.to_i)
        @right_composite.layout_data.top = Swt::Layout::FormAttachment.new(0, 5 + @toolbar_height.to_i)
        @shell.layout
        @shell.redraw
      end

    end
  end
end
