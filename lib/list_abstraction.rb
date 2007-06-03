

module Redcar
  module GUI
    class Table
      attr_reader :treeview
      include Enumerable
      STANDARD_COLUMNS = {
        :foreground_set => 0,
        :foreground     => 1,
        :background_set => 2,
        :background     => 3,
        :strikethrough  => 4
      }
      STANDARD_COLUMN_TYPES = {
        :foreground_set => TrueClass,
        :foreground =>     String,
        :background_set => TrueClass,
        :background =>     String,
        :strikethrough =>  TrueClass
      }
      FIRST_COL = 5
      
      def initialize(options={})
        options = process_params(options,
                                 { :columns => [{ :type => String }],
                                   :multiple_select => false})
        columntypes = options[:columns].map{|h| h[:type]}
        @options = options
        ordered_standard_types = STANDARD_COLUMNS.values.sort.map do |ind| 
          STANDARD_COLUMN_TYPES[STANDARD_COLUMNS.invert[ind]]
        end
        @liststore = Gtk::ListStore.new(*(ordered_standard_types+columntypes))
        @treeview = Gtk::TreeView.new(@liststore)
        if options[:multiple_select]
          @treeview.selection.mode = Gtk::SELECTION_MULTIPLE
        end
        any_headers = false
        STANDARD_COLUMNS.values.sort.each do |index|
          case STANDARD_COLUMN_TYPES[STANDARD_COLUMNS.invert[index]].to_s
          when "String", "Integer"
            renderer = Gtk::CellRendererText.new
          when "TrueClass"
            renderer = Gtk::CellRendererToggle.new
          end
          column = Gtk::TreeViewColumn.new(STANDARD_COLUMNS.invert[index].to_s, 
                                           renderer, 
                                           nil)
          column.visible = false
          @treeview.append_column(column)
        end
        i = FIRST_COL
        @options[:columns].each do |columnhash|
          columnhash = process_params(columnhash, 
                                      { :type => String,
                                        :heading => "",
                                        :sortable => true })
          case columnhash[:type].to_s
          when "String", "Integer"
            renderer = Gtk::CellRendererText.new
          when "TrueClass"
            renderer = Gtk::CellRendererToggle.new
          end
          any_headers = true if columnhash[:heading]
          column = Gtk::TreeViewColumn.new(columnhash[:heading]||"",
                                           renderer,
                                           'text' => i,
                                           'foreground-set' => STANDARD_COLUMNS[:foreground_set],
                                           'foreground'     => STANDARD_COLUMNS[:foreground],
                                           'background-set' => STANDARD_COLUMNS[:background_set],
                                           'background'     => STANDARD_COLUMNS[:background],
                                           'strikethrough'  => STANDARD_COLUMNS[:strikethrough]
                                           )
          column.set_sort_column_id(i) if columnhash[:sortable]
          @treeview.append_column(column)
          i += 1
        end
        @treeview.headers_visible = any_headers
      end
      
      def each
        @liststore.each do |model, path, iter|
          row = []
          FIRST_COL.upto(@liststore.n_columns-1) do |i|
            row << @liststore.get_value(iter, i)
          end
          yield row
        end
      end
      
      def [](int)
        get_row_from_path int.to_s
      end
      
      def rows
        self.to_a
      end
      
      def replace(list)
        @liststore.clear
        list.each do |item|
          iter = @liststore.append
          item.each_with_index do |val, i|
            set_standard_appearance(iter)
            iter[i+FIRST_COL] = val
          end
        end
      end
      
      def <<(row)
        iter = @liststore.append
        row.each_with_index do |val, i|
          set_standard_appearance(iter)
          iter[i+FIRST_COL] = val
        end
      end
      
      def set_standard_appearance(iter)
        iter[0] = false
        iter[1] = "black"
        iter[2] = false
        iter[3] = "white"
        iter[4] = false
      end
      
      # Unselects all currently selected, then selects the given list numbers.
      def select(*ints)
        @treeview.selection.unselect_all
        ints.each do |int|
          @treeview.selection.select_path(Gtk::TreePath.new(int.to_s))
        end
      end
      
      def selected
        sels = []
        @treeview.selection.selected_each do |model, path, iter|
          row = []
          FIRST_COL.upto(@liststore.n_columns-1) do |i|
            row << @liststore.get_value(iter, i)
          end
          sels << row
        end
        unless @options[:multiple_select]
          sels = sels[0]
        end
        sels
      end
      
      def on_double_click(&block)
        @on_double_click = block
        @treeview.signal_connect('row-activated') do |tv, path, col|
          @on_double_click.call(get_row_from_path(path).tap{|r| p r})
        end
      end
      
      def multiple_select?
        @options[:multiple_select]
      end
      
      def foreground_colour(row, colour)
        iter = @liststore.get_iter(row.to_s)
        iter[0] = true
        iter[1] = colour
      end
      
      def background_colour(row, colour)
        iter = @liststore.get_iter(row.to_s)
        iter[2] = true
        iter[3] = colour
      end
      
      def strikethrough(row)
        iter = @liststore.get_iter(row.to_s)
        iter[4] = true
      end
      
      def no_strikethrough(row)
        iter = @liststore.get_iter(row.to_s)
        iter[4] = false
      end
      
      private
      
      def get_row_from_path(path)
        iter = @liststore.get_iter(path)
        row = []
        FIRST_COL.upto(@liststore.n_columns-1) do |i|
          row << @liststore.get_value(iter, i)
        end
        row
      end          
    end
    
    class List < Table
      include Enumerable
      
      def initialize(options={})
        options = process_params(options,
                                 { :type => String,
                                   :heading => nil,
                                   :multiple_select => false})
        upoptions = {}
        upoptions[:columns] = [{ :type => options[:type], 
                                 :heading => options[:heading] }]
        upoptions[:multiple_select] = options[:multiple_select]
        super(upoptions)
      end
      
      def each
        super do |row|
          yield(row[0])
        end
      end
      
      def [](int)
        get_row_from_path int.to_s
      end
      
      def rows
        self.to_a
      end
      
      def replace(list)
        super(list.map{|el| [el]})
      end
      
      def <<(row)
        super([row])
      end
      
      def selected
        s = super
        if multiple_select?
          s.map{|a| a[0]}
        else
          s[0]
        end
      end
      
      # Unselects all currently selected, then selects the given list numbers.
      def select(*ints)
        super(*ints)
      end
      
      private
      
      def get_row_from_path(path)
        super[0]
      end
    end
  end
end
