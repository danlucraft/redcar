
module Com::RedcarIDE
  class DatabusInspector < Redcar::Plugin
    class OpenDBI < Redcar::Command
      menu "Tools/Databus Inspector"
      icon :PREFERENCES
      
      def execute
        if t = win.tab["Databus Inspector"]
          t.focus
        else
          new_tab = win.new_tab(DatabusInspectorTab)
          new_tab.focus
          new_tab.label.text = "Databus Inspector"
        #Redcar.StatusBar.main = "Opened Databus Inspector"
        end
      end
    end
  end

  class DatabusInspectorTab < Redcar::Tab
    def initialize(pane)
      @ts = Gtk::TreeStore.new(String, String, String)
      @tv = Gtk::TreeView.new(@ts)
      renderer = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new("Slot Name", renderer, :text => 0)
      col2 = Gtk::TreeViewColumn.new("Value", renderer, :text => 1)
      col3 = Gtk::TreeViewColumn.new("Type", renderer, :text => 2)
      @tv.append_column(col1)
      @tv.append_column(col3)
      @tv.append_column(col2)
      @tv.show
      super(pane, @tv, :scrolled? => true)
      build_tree
      @ts.iter_first[0] = "/"
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
        @ts.set_value(iter, 2, "Data")
        @ts.set_value(iter, 1, node.data.inspect[0..50])
      elsif node.is_queue_slot?
        @ts.set_value(iter, 2, "Queue")
      elsif node.is_stack_slot?
        @ts.set_value(iter, 2, "Stack")
      elsif node.is_proc_slot?
        @ts.set_value(iter, 2, "Proc")
      end
    end
  end
end
