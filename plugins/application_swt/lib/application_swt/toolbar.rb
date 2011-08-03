
module Redcar
  class ApplicationSWT
    class ToolBar

      DEFAULT_ICON = File.join(Redcar.root, %w(share icons document.png))

      def self.icons
        @icons = {
          :new       => File.join(Redcar.icons_directory, "document-text.png"),
          :open      => File.join(Redcar.icons_directory, "folder-open-document.png"),
          :open_dir  => File.join(Redcar.icons_directory, "blue-folder-horizontal-open.png"),
          :save      => File.join(Redcar.icons_directory, "disk.png"),
          :save_as   => File.join(Redcar.icons_directory, "disk--plus.png"),
          :undo      => File.join(Redcar.icons_directory, "arrow-circle-225-left.png"),
          :redo      => File.join(Redcar.icons_directory, "arrow-circle-315.png"),
          :search    => File.join(Redcar.icons_directory, "binocular.png")
        }
      end

      def self.items
        @items ||= Hash.new {|h,k| h[k] = []}
      end

      def self.disable_items(key_string)
        items[key_string].each {|i| p i.text; i.enabled = false}
      end

      attr_reader :coolbar, :toolbar, :coolitem, :toolbars, :coolitems

      def initialize(window, toolbar_model, options={})
        return unless toolbar_model
        
        @entries = Hash.new {|h,k| h[k] = [] }
        @toolbar = main_toolbar(window)
        toolbar_model.each do |entry|
          name = entry.barname || :new
          @entries[name] << entry
        end
        add_entries_to_toolbar(@toolbar, @entries[:core])
        @entries.each do |name, es|
          next if name == :core
          add_entries_to_toolbar(@toolbar, es)
          sep = Swt::Widgets::ToolItem.new(@toolbar, Swt::SWT::DEFAULT)
        end
        @toolbar.pack unless Redcar.platform == :osx
      end

      def main_toolbar(window)
        if Redcar.platform == :osx
          window.shell.getToolBar
        else
          Swt::Widgets::ToolBar.new(window.shell, Swt::SWT::FLAT | Swt::SWT::HORIZONTAL)
        end
      end
      
      def show
        @toolbar.set_visible(true)
      end

      def hide
        unless @toolbar.disposed?
          @toolbar.set_visible(false)
          @toolbar.getItems.each {|i| i.dispose }
          # @toolbar.dispose unless Redcar.platform == :osx
        end
      end

      def close
        hide
        @result
      end

      def height
        return 0 if Redcar.platform == :osx
        point = @toolbar.computeSize(Swt::SWT::DEFAULT, Swt::SWT::DEFAULT, true)
        return point.y
      end

      private

      def add_entries_to_toolbar(toolbar, toolbar_model)
        toolbar_model.each do |entry|
          if entry.is_a?(Redcar::ToolBar::LazyToolBar)
            toolbar_header = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::CASCADE)
            toolbar_header.text = entry.text
            new_toolbar = Swt::Widgets::ToolBar.new(toolbar)
            toolbar_header.toolbar = new_toolbar
            toolbar_header.add_arm_listener do
              new_toolbar.get_items.each {|i| i.dispose }
              add_entries_to_toolbar(new_toolbar, entry)
            end
          elsif entry.is_a?(Redcar::ToolBar)
            new_toolbar = Swt::Widgets::ToolBar.new(toolbar)
            add_entries_to_toolbar(new_toolbar, entry)
          elsif entry.is_a?(Redcar::ToolBar::Item::Separator)
            item = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::SEPARATOR)
          elsif entry.is_a?(Redcar::ToolBar::Item)
            item = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::PUSH)
            item.setEnabled(true)
            item.setImage(Swt::Graphics::Image.new(ApplicationSWT.display, ToolBar.icons[entry.icon] || entry.icon || DEFAULT_ICON ))
            connect_command_to_item(item, entry)
          else
            raise "unknown object of type #{entry.class} in toolbar"
          end
        end
        toolbar.pack
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
        item.setToolTipText(entry.text)
        item.add_selection_listener(SelectionListener.new(entry))
        h = entry.command.add_listener(:active_changed) do |value|
          unless item.disposed
            item.enabled = value
          end
        end
        if not entry.command.active?
          item.enabled = false
        end
      end
    end
  end
end
