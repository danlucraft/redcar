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
      
      def set_background(colors, percents, vertical = true)
        @background_color_options = { :colors => colors,
          :percents => percents.collect { |i| i / 100.0 },
          :vertical => vertical }
        @tab_area.background = colors[colors.size - 1]
      end

      def add_item(tab)
        @items << tab
        tab.draw_label(@tab_area)
        tab.font = @font
        selection = tab if @items.size == 1
        layout
      end

      def remove_item(tab)
        return unless tab = ensure_tab(tab)

        evt = create_ctab_folder_event(tab)
        call_listeners(@ctab_folder2_listeners, evt, :method => :close, :run_blocks => true)
        do_remove_item(tab) if evt.doit
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
        tab = ensure_tab(tab)
        return if tab.nil? or tab.active?

        evt = create_selection_event(tab)
        call_listeners(@selection_listeners, evt, :method => :widgetSelected, :run_blocks => true)
        do_selection(tab) if evt.doit
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

      # Mirrors the selection-listener behaviour of CTabFolder.
      # Additionally accepts a block as listener. If a block is passed,
      # only widgetSelected events will be passed, not widgetDefaultSelected.
      def add_selection_listener(listener = nil)
        return @selection_listeners << listener if listener
        raise ArgumentError, "Expected a listener or a block" unless block_given?
        @selection_listeners << Proc.new
      end

      # Mirrors the CTabFolder2Listener behaviour of CTabFolder.
      # You can also pass a a block as listener. Note that when you pass a
      # block, only close events will be passed to it, not the minimize, maximize,
      # restore or showList events.
      def add_ctab_folder2_listener(listener = nil)
        return @ctab_folder2_listeners << listener if listener
        raise ArgumentError, "Expected a listener or a block" unless block_given?
        @ctab_folder2_listeners << Proc.new
      end

      def font= swt_font
        @font = swt_font
        @items.each { |tab| tab.font = swt_font }
      end

      private

      def ensure_tab(tab)
        tab = @items[tab] if tab.respond_to? :to_int
        tab
      end

      def do_selection(tab)
        selection.active = false if selection
        tab.active = true
        relayout!
      end

      def do_remove_item(tab)
        @items.delete(tab)
        tab.dispose
        selection = @items.first if tab.active?
        relayout!
      end

      def relayout!
        layout
        @tab_area.layout
      end

      def create_selection_event(tab)
        create_event(tab, SelectionEvent)
      end

      def create_ctab_folder_event(tab)
        create_event(tab, CTabFolderEvent)
      end

      def create_event(tab, clazz)
        clazz.new.tap do |e|
          e.item = tab
          e.doit = true
        end
      end

      def call_listeners(list, evt, hash)
        list.each do |l|
          if hash[:run_blocks] and l.respond_to? :call
            l[evt]
          else
            l.send(hash[:method], evt)
          end
        end
      end
    end
  end
end
