module Redcar
  class ApplicationSWT
    class ToolBar

      
      FILE_DIR = File.join(Redcar.root, %w(share icons))
      DEFAULT_ICON = File.join(Redcar.root, %w(share icons document.png))

      def self.icons
        @icons = {
          :new => File.join(FILE_DIR, "document-text.png"),
          :open => File.join(FILE_DIR, "folder-open-document.png"),
          :save => File.join(FILE_DIR, "document-import.png"),
          #:save_as => File.join(FILE_DIR, "save_as.png"),
          #:save_all => File.join(FILE_DIR, "save_all.png"),
          :undo => File.join(FILE_DIR, "arrow-circle-225-left.png"),
          :redo => File.join(FILE_DIR, "arrow-circle-315.png"),
          :search => File.join(FILE_DIR, "binocular.png")
        }
      end


      def self.types
        @types = { :check => Swt::SWT::CHECK, :radio => Swt::SWT::RADIO }
      end

      def self.items
        @items ||= Hash.new {|h,k| h[k] = []}
      end

      def self.disable_items(key_string)
        items[key_string].each {|i| p i.text; i.enabled = false}
      end

      attr_reader :coolbar, :toolbar_bar

      def self.toolbar_types
        [Swt::SWT::FLAT, Swt::SWT::HORIZONTAL]
      end

      def initialize(window, toolbar_model, options={})
        s = Time.now
        @window = window
        @coolbar = Swt::Widgets::CoolBar.new(window.shell, Swt::SWT::NONE | Swt::SWT::HORIZONTAL)
	      @coolbar_item1 = Swt::Widgets::CoolItem.new(@coolbar, Swt::SWT::NONE)
        @coolbar_item2 = Swt::Widgets::CoolItem.new(@coolbar, Swt::SWT::NONE)
        @toolbar_bar1 = create_toolbar(@coolbar_item1)
        @toolbar_bar2 = create_toolbar(@coolbar_item2)
        return unless toolbar_model
        add_entries_to_toolbar(@toolbar_bar1, toolbar_model)
        item = Swt::Widgets::ToolItem.new(@toolbar_bar2, Swt::SWT::PUSH)
        item.setText("Test")
        item.setEnabled(true)
	
        #puts "ApplicationSWT::ToolBar initialize took #{Time.now - s}s"
        @toolbar_bar1.pack
        @toolbar_bar2.pack
	      @coolbar_item1.setControl(@toolbar_bar1)
        @coolbar_item2.setControl(@toolbar_bar2)
        
        # TESTING!!!!
        @ctrl = @coolbar_item1.getControl()
        @pt = @ctrl.computeSize(Swt::SWT::DEFAULT, Swt::SWT::DEFAULT)
        @coolbar_item1.setSize(@pt)
        @coolbar_item2.setSize(@pt)
        # END TESTING!!!!
      end

      def create_toolbar(composite)
        @toolbar = Swt::Widgets::ToolBar.new(@coolbar, Swt::SWT::FLAT | Swt::SWT::BORDER)
        @toolbar.set_visible(false)
	      @toolbar.setLayout(Swt::Layout::FormLayout.new)
	      @toolbar.setLayoutData(Swt::Layout::FormData.new)
        @toolbar
      end
      
      def show
        @toolbar_bar1.set_visible(true)
        @toolbar_bar2.set_visible(true)
        @coolbar.set_visible(true)
      end

      def hide
        #@toolbar_bar.set_visible(false)
	#@toolbar_bar.setRedraw(true)
	@toolbar_bar1.dispose()
	@toolbar_bar2.dispose()
  @coolbar.dispose()
      end

      def close
        #@handlers.each {|obj, h| obj.remove_listener(h) }
	@toolbar_bar1.dispose()
	@toolbar_bar2.dispose()
        @result
      end

      def move(x, y)
        @toolbar_bar.setLocation(x, y)
      end

      private

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
            new_toolbar = Swt::Widgets::ToolBar.new(toolbar)
            add_entries_to_toolbar(new_toolbar, entry)
          elsif entry.is_a?(Redcar::ToolBar::Item::Separator)
            item = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::SEPARATOR)
          elsif entry.is_a?(Redcar::ToolBar::Item)
            item = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::PUSH)
            item.setEnabled(true)
            item.setImage(Swt::Graphics::Image.new(ApplicationSWT.display, ToolBar.icons[entry.icon] || entry.icon || DEFAULT_ICON))
            connect_command_to_item(item, entry)
          else
            raise "unknown object of type #{entry.class} in toolbar"
          end
        end
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
        #@handlers << [entry.command, h]
        if not entry.command.active?
          item.enabled = false
        end
      end
    end
  end
end
