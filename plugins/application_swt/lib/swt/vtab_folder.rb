module Swt
  module Widgets
    class VTabFolder < Swt::Widgets::Composite
      attr_accessor :tab_area, :content_area
      attr_reader :selection_color_options, :font, :items

      SelectionEvent  = Struct.new("Event", :item, :doit)
      CTabFolderEvent = SelectionEvent

      def initialize(parent, style)
        super(parent, style | Swt::SWT::BORDER)
        self.layout = Swt::Layout::GridLayout.new(2, false).tap do |l|
          l.horizontalSpacing = -1
          l.verticalSpacing = -1
          l.marginHeight = -1
          l.marginWidth = -1
        end

        @items = []
        @selection_listeners = []
        @ctab_folder2_listeners = []
        @font = Swt::Widgets::Display.current.system_font

        @tab_area = Swt::Widgets::Composite.new(self, Swt::SWT::NONE).tap do |t|
          t.layout_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_VERTICAL | Swt::Layout::GridData::GRAB_VERTICAL)
          t.layout = Swt::Layout::RowLayout.new.tap do |l|
            l.type         = Swt::SWT::VERTICAL
            l.spacing      = -1
            l.wrap         = false
            l.marginLeft   = 0
            l.marginRight  = 0
            l.marginTop    = 0
            l.marginBottom = 0
          end
        end
      end

      def set_selection_background(colors, percents, vertical = true)
        @selection_color_options = { :colors => colors,
          :percents => percents.collect { |i| i / 100.0 },
          :vertical => vertical }
      end

      def add_item(tab)
        @items << tab
        tab.draw_label(@tab_area)
        tab.font = @font
        tab.active = true if @items.size == 1
        layout
      end

      def remove_item(tab)
        @items.delete(tab)
        tab.dispose
        selection = @items.first if tab.active?
        layout
      end

      def get_item(selector)
        return @items[selector] if selector.respond_to? :to_int
        return @items.detect { |i| i.text == selector } if selector.respond_to? :to_str
        raise NotImplementedError, "Getting via Point not implemented"
      end

      def item_count
        @items.size
      end

      def selection
        @items.detect { |x| x.active? }
      end

      def selection=(tab)
        return if tab.nil?
        evt = SelectionEvent.new.tap do |e|
          e.item = tab
          e.doit = true
        end
        @selection_listeners.each do |l|
          if l.respond_to? :call
            l[evt]
          else
            l.widgetSelected(evt)
          end
        end
        if evt.doit
          silent_selection(tab)
        end
      end

      def silent_selection(tab)
        return if tab.nil?
        selection.active = false if selection
        if tab.respond_to? :to_int
          @items[tab].active = true
        else
          tab.active = true
        end
        layout
        @tab_area.layout
      end

      def selection_index
        index_of(selection)
      end

      def index_of(tab)
        @items.index(tab)
      end

      def show_item(tab)
        selection = tab
      end

      def add_selection_listener(listener = nil)
        return @selection_listeners << listener if listener
        raise ArgumentError, "Expected a listener or a block" unless block_given?
        @selection_listeners << Proc.new
      end

      def font= swt_font
        @font = swt_font
        @items.each { |tab| tab.font = swt_font }
      end
    end
  end
end
