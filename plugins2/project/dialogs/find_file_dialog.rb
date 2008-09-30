
module Redcar
  class FindFileDialog < Gtk::Dialog
    attr_accessor :entry, :treeview, :list

    def initialize
      super("Find File in Project", Redcar.win,
            Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT)
      set_size_request(300, 200)
      @entry = Gtk::Entry.new
      @list = Gtk::ListStore.new(String)
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new("", renderer, :text => 0)
      column.visible = true
      @treeview = Gtk::TreeView.new(@list)
      @treeview.append_column(column)
      @treeview.show
      vbox.pack_start(@entry, false)
      vbox.pack_start(@treeview)
      signal_connect('response') { self.destroy }
      @entry.signal_connect(:changed) do
        @list.clear
        if @entry.text.length > 0
          fs = FindFileDialog.find_files(@entry.text, ProjectTab.project_tab.directories)
          i = 0
          fs.each do |path, name, _|
            if i < 10
              iter = @list.append
              iter[0] = name
            end
            i += 1
          end
        end
      end
    end

    def self.find_files(text, directories)
      files = []
      p directories
      directories.each do |dir|
        files += Dir[File.expand_path(dir + "/**/*")]
      end
      files
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
      Regexp.new(re_src)
    end
  end
end
