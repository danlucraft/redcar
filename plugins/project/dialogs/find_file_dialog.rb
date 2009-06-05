
module Redcar
  class FindFileDialog < Gtk::Dialog
    MAX_ENTRIES = 30
    attr_accessor :entry, :treeview, :list

    def initialize
      super("Find File in Project", Redcar.win,
            Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT)
      set_size_request(500, 300)
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
    
    # All signal connection should be put here
    def connect_signals
      # row-activated is the signal for dbl clicks
      @treeview.signal_connect("row-activated") do 
        treeview_activated
      end
      
      @entry.signal_connect("key-press-event") do |_, gdk_eventkey|
        entry_key_press(gdk_eventkey)
      end
      
      @entry.signal_connect("changed") do 
        @entry_changed_time = Time.now
        unless @entry_changed
          @entry_changed = true
          Gtk.idle_add_priority(GLib::PRIORITY_LOW) do
            if @entry.destroyed?
              false
            else
              if Time.now > @entry_changed_time + 0.2
                @entry_changed = false
                entry_changed
                false
              else
                true
              end
            end
          end
        end
        false
      end
    end
    
    def entry_key_press(gdk_eventkey)
      kv = gdk_eventkey.keyval
      
      key = Gdk::Keyval.to_name(kv)
      
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
      if @entry.text.length > 2
        fs = FindFileDialog.find_files(@entry.text, ProjectTab.instance.directories)
        i = 0
        fs.each do |fn|
          bits = fn.split("/")
          name = bits.last
          updir = bits[-4..-2].join("/")
          if i < MAX_ENTRIES
            iter = @list.append
            iter[0] = name + "     (#{updir})"
            iter[1] = fn
          end
          i += 1
        end
      end
      if iter = @treeview.model.iter_first
        @treeview.selection.select_iter(@treeview.model.iter_first)
      end
      # if the user hit enter before this, open the top file
      if @activated_by_user
        treeview_activated
        @activated_by_user = false
      end
    end

    def treeview_select_down
      if sel = @treeview.selection.selected
        ni = sel.path
        if ni.next! and iter = @treeview.model.get_iter(ni)
          @treeview.selection.select_iter(iter)
          @treeview.scroll_to_cell(ni, nil, false, 0.0, 0.0)
        end
      end
      focus = @entry
    end
    
    def treeview_select_up
      if sel = @treeview.selection.selected
        pi = sel.path
        if pi.prev! and iter = @treeview.model.get_iter(pi)
          @treeview.selection.select_iter(iter)
          @treeview.scroll_to_cell(pi, nil, false, 0.0, 0.0)
        end
      end
      focus = @entry
    end
    
    # opens the selected file
    def treeview_activated
      if si = @treeview.selection.selected
        OpenTabCommand.new(si[1]).do
        destroy
      else
        # the user hit return before the list was populated
        @activated_by_user = true
      end
    end

    def self.find_files(text, directories)
      files = []
      directories.each do |dir|
        files += Dir[File.expand_path(dir + "/**/*")]
      end
      
      re = make_regex(text)

      score_match_pairs = []
      cutoff = 10000000

      results = files.each do |fn| 
        unless File.directory?(fn)
          bit = fn.split("/")
          if m = bit.last.match(re)
		        cs = []
		        diffs = 0
		        m.captures.each_with_index do |_, i|
	  	        cs << m.begin(i + 1)
		          if i > 0
		            diffs += cs[i] - cs[i-1]
		          end
		        end
						# lower score is better
            score = (cs[0] + diffs)*100 + bit.last.length
            if score < cutoff
              score_match_pairs << [score, fn]
              score_match_pairs.sort!
              if score_match_pairs.length == MAX_ENTRIES
                cutoff = score_match_pairs.last.first
                score_match_pairs.pop
              end
            end
      		end
				end
			end
      score_match_pairs.map {|a| a.last }
    end

    def self.make_regex(text)
      re_src = "(" + text.split(//).map{|l| Regexp.escape(l) }.join(").*?(") + ")"
      Regexp.new(re_src)
    end
  end
end
