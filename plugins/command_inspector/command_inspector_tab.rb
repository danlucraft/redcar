
module Redcar
  class CommandInspectorTab < Tab
    
    def initialize(pane)
      @ts = Gtk::TreeStore.new(String, String)
      @tv = Gtk::TreeView.new(@ts)
      @tv.headers_visible = false
      renderer = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new("Slot Name", renderer, :text => 0)
      @tv.append_column(col1)
      @tv.set_size_request(250, 100)
      @tv.show
      sw = Gtk::ScrolledWindow.new nil, nil
      sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
      sw.add @tv
      @hp = Gtk::HPaned.new
      @hp.add1 sw
      @hp.add2 Gtk::Label.new("fpo")
      @hp.show_all
      super(pane, @hp, :scrolled => false)
      build_tree
    end
    
    def build_tree
      build_tree1($BUS['/redcar/commands'], nil)
    end
    
    def build_tree1(node, iter)
      set_iter_values(node, iter) if iter
      subiter = nil
      node.each_slot do |subnode|
        subiter = @ts.insert_after(iter, subiter)
        build_tree1(subnode, subiter)
      end
    end
    
    def set_iter_values(node, iter)
      @ts.set_value(iter, 0, node.name)
      @ts.set_value(iter, 1, node.path)
    end
  end
end
