

module Redcar
  class DatabusTab < Tab
    
    def initialize(pane)
      @ts = Gtk::TreeStore.new(String, String)
      @tv = Gtk::TreeView.new(@ts)
      renderer = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new("Address", renderer, :text => 0)
      col2 = Gtk::TreeViewColumn.new("Value", renderer, :text => 1)
      @tv.append_column(col1)
      @tv.append_column(col2)
      @tv.show
      super(pane, @tv, :scrolled => true)
      build_tree
    end
    
    def build_tree
      iter = @ts.insert_after(nil, nil)
      build_tree1($BUS['/'], iter)
    end
    
    def build_tree1(node, iter)
      set_iter_values(node, iter)
      subiter = nil
      node.each_slot do |subnode|
        subiter = @ts.insert_after(iter, subiter)
        build_tree1(subnode, subiter)
      end
    end
    
    def set_iter_values(node, iter)
      @ts.set_value(iter, 0, node.name)
      if node.is_data_slot?
        @ts.set_value(iter, 1, node.data.to_s)
      elsif node.is_queue_slot?
        @ts.set_value(iter, 1, "<queue>")
      elsif node.is_stack_slot?
        @ts.set_value(iter, 1, "<stack>")
      end
    end
  end
end
