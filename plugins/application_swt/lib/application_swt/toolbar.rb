module Redcar
  class ApplicationSWT
    class ToolBar

      def self.types
        @types = { :check => Swt::SWT::CHECK, :radio => Swt::SWT::RADIO }
      end

      def self.items
        @items ||= Hash.new {|h,k| h[k] = []}
      end

      def self.disable_items(key_string)
        items[key_string].each {|i| p i.text; i.enabled = false}
      end

      attr_reader :toolbar_bar



      def self.toolbar_types
        [Swt::SWT::FLAT]
      end

      def initialize(window, toolbar_model, options={})
        s = Time.now
        #unless ToolBar.toolbar_types.include?(self.class)
        #  raise "type should be in #{ToolBar.toolbar_types.inspect}"
        #end
        @window = window
        @toolbar_bar = Swt::Widgets::ToolBar.new(window.shell, Swt::SWT::FLAT)
        @toolbar_bar.set_visible(false)
        return unless toolbar_model
        @handlers = []
        @use_numbers = options[:numbers]
        @number = 1
        add_entries_to_toolbar(@toolbar_bar, toolbar_model)
        #puts "ApplicationSWT::ToolBar initialize took #{Time.now - s}s"
      end

      def show
        @toolbar_bar.set_visible(true)
      end

      def close
        @handlers.each {|obj, h| obj.remove_listener(h) }
        @toolbar_bar.dispose
        @result
      end

      def move(x, y)
        @toolbar_bar.setLocation(x, y)
      end

      private

      def use_numbers?
        @use_numbers
      end

      def add_entries_to_toolbar(toolbar, toolbar_model)

        toolbar_model.each do |entry|
          if entry.is_a?(Redcar::ToolBar::LazyToolBar)
            toolbar_header = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::CASCADE)
            toolbar_header.text = entry.text
            #new_toolbar = Swt::Widgets::ToolBar.new(@window.shell, Swt::SWT::DROP_DOWN)
            new_toolbar = Swt::Widgets::ToolBar.new(toolbar)
            toolbar_header.toolbar = new_toolbar
            toolbar_header.add_arm_listener do
              new_toolbar.get_items.each {|i| i.dispose }
              add_entries_to_toolbar(new_toolbar, entry)
            end
          elsif entry.is_a?(Redcar::ToolBar)
            toolbar_header = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::CASCADE)
            #toolbar_header.text = entry.text
            toolbar_header.text = "Toolbar!"
            #new_toolbar = Swt::Widgets::ToolBar.new(@window.shell, Swt::SWT::DROP_DOWN)
            new_toolbar = Swt::Widgets::ToolBar.new(toolbar)
            toolbar_header.toolbar = new_toolbar
            add_entries_to_toolbar(new_toolbar, entry)
          elsif entry.is_a?(Redcar::ToolBar::Item::Separator)
            item = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::SEPARATOR)
          elsif entry.is_a?(Redcar::ToolBar::Item)
            item = Swt::Widgets::ToolItem.new(toolbar, ToolBar.types[entry.type] || Swt::SWT::PUSH)
            item.setSelection(entry.active)
            if entry.command.is_a?(Proc)
              connect_proc_to_item(item, entry)
            end
          else
            raise "unknown object of type #{entry.class} in toolbar"
          end
        end
      end

      class ProcSelectionListener
        def initialize(entry)
          @entry = entry
        end

        def widget_selected(e)
          Redcar.safely("toolbar item '#{@entry.text}'") do
            @entry.command.call
          end
        end

        alias :widget_default_selected :widget_selected
      end

      def connect_proc_to_item(item, entry)
        if use_numbers? and Redcar.platform == :osx
          item.text = entry.text + "\t" + @number.to_s
          @number += 1
        else
          item.text = entry.text
        end
        item.addSelectionListener(ProcSelectionListener.new(entry))
      end

      class SelectionListener
        def initialize(entry)
          @entry = entry
        end

        def widget_selected(e)
          @entry.selected(e.stateMask != 0)
        end

        def widget_default_selected(e)
          @entry.selected(e.stateMask != 0)
        end
      end

      def connect_command_to_item(item, entry)
        if key_specifier = @keymap.command_to_key(entry.command)
          if key_string    = BindingTranslator.platform_key_string(key_specifier)
            item.text = entry.text + "\t" + key_string
            item.set_accelerator(BindingTranslator.key(key_string))
            ToolBar.items[key_string] << item
          else
            puts "you didn't specify a keybinding for this platform for #{entry.text}"
            item.text = entry.text
          end
        else
          item.text = entry.text
        end
        item.add_selection_listener(SelectionListener.new(entry))
        h = entry.command.add_listener(:active_changed) do |value|
          unless item.disposed
            item.enabled = value
          end
        end
        @handlers << [entry.command, h]
        if not entry.command.active?
          item.enabled = false
        end
      end
    end
  end
end
