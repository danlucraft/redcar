
module Redcar
  class FindFileDialog < Gtk::Dialog
    attr_accessor :entry, :treeview, :list

    def initialize
      super("Find File in Project", Redcar.win,
            Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT)
      set_size_request(300, 200)
      @entry = Gtk::Entry.new
      @list = Gtk::ListStore.new(String, String)
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new("", renderer, :text => 0)
      column.visible = true
      @treeview = Gtk::TreeView.new(@list)
      @treeview.append_column(column)
      @treeview.show
      vbox.pack_start(@entry, false)
      vbox.pack_start(@treeview)
      signal_connect('response') { self.destroy }
      
      connect_signals
    end
    
    def connect_signals
      @entry.signal_connect("key-press-event") do |_, gdk_eventkey|
        entry_key_press(gdk_eventkey)
      end
      
      @entry.signal_connect("changed") do 
        @entry_changed ||= 0
        @entry_changed += 1
        Gtk.idle_add_priority(GLib::PRIORITY_LOW) do
          @entry_changed -= 1
          if @entry_changed == 0
            entry_changed
          end
          false
        end
      end
    end
    
    def entry_key_press(gdk_eventkey)
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      if key == "Down"
        treeview_select_down
        true
      elsif key == "Up"
        treeview_select_up
        true
      elsif key == "Return"
        treeview_activated
        true
      else
        false
      end
    end
    
    def entry_changed
      @list.clear
      if @entry.text.length > 0
        fs = FindFileDialog.find_files(@entry.text, ProjectTab.project_tab.directories)
        i = 0
        fs.each do |path, name, _|
          if i < 10
            iter = @list.append
            iter[0] = name
            iter[1] = path
          end
          i += 1
        end
      end
      if iter = @treeview.model.iter_first
        @treeview.selection.select_iter(@treeview.model.iter_first)
      end
    end

    def treeview_select_down
      ni = @treeview.selection.selected.path
      if ni.next! and iter = @treeview.model.get_iter(ni)
        @treeview.selection.select_iter(iter)
        @treeview.scroll_to_cell(ni, nil, false, 0.0, 0.0)
      end
    end
    
    def treeview_select_up
      pi = @treeview.selection.selected.path
      if pi.prev! and iter = @treeview.model.get_iter(pi)
        @treeview.selection.select_iter(iter)
        @treeview.scroll_to_cell(pi, nil, false, 0.0, 0.0)
      end
    end
    
    def treeview_activated
      OpenTab.new(@treeview.selection.selected[1]).do
      destroy
    end

    def self.find_files(text, directories)
      files = []
      p directories
      directories.each do |dir|
        files += Dir[File.expand_path(dir + "/**/*")]
      end
      p files.length
      re = make_regex(text)

      results = files.map do |fn| 
        unless File.directory?(fn)
          bit = fn.split("/")
          if m = bit.last.match(re)
            [fn, bit, m]
          end
        end
      end

      results = results.compact

      results = results.map do |fn, bit, m|
        cs = []
        diffs = 0
        m.captures.each_with_index do |_, i|
          cs << m.begin(i + 1)
          if i > 0
            diffs += cs[i] - cs[i-1]
          end
        end
        score = (cs[0] + diffs)*100 + bit.last.length
        [fn, bit.last, score]
      end
      results.sort_by{|_, _, s| s}
    end

    def self.make_regex(text)
      re_src = "(" + text.split(//).join(").*?(") + ")"
      p re_src
      Regexp.new(re_src)
    end
  end
end
