module Redcar
  class ClipboardViewer
    class ClipboardBar < Redcar::Speedbar
      include Redcar::Observable

      def initialize
        @size = ClipboardViewer.storage['chars_to_display'].to_i
        @line_limit = ClipboardViewer.storage['lines_to_display'].to_i
        load_list
        @listener = Redcar.app.clipboard.add_listener(:added) {|t|load_list}
      end

      def close
        Redcar.app.clipboard.remove_listener(@listener)
      end

      def load_list
        @list = Redcar.app.clipboard || []
        values = display_values(@list)
        if values.length > 0
          clip_list.items = values
          clip_list.value = values.first
        else
          clip_list.items = [" "*(@size+5)]
          clip_list.value = clip_list.items.first
        end
      end

      combo :clip_list
      button :paste_selected, "Paste!", "Return" do
        tab = Redcar.app.focussed_window.focussed_notebook_tab
        content = @list.to_a.reverse.detect do |r|
          l = r.to_s
          val = clip_list.value.to_s
          val = val[0,val.length-3] if val =~ /\.\.\.$/
          l.length >= val.length and l[0,val.length].to_s == val.to_s
        end
        tab.edit_view.document.insert_at_cursor(content.to_s) if tab.is_a?(EditTab) and content
        load_list
      end

      button :browse, "Browse", nil do
        OpenClipboardBrowser.new(@list).run
      end

      def display_values(list)
        display = list.to_a.reverse.map do |l|
          value = ""
          r=0
          l.to_s.each_line do |line|
            value << line  if r <= @line_limit - 1
            value << "..." if r == @line_limit
            r+=1
            break if r > @line_limit - 1
          end
          value = value[0,value.length-1] if value =~ /\n$/
          if value.length > @size
            value[0,@size]+"..."
          else
            value
          end
        end
        display || []
      end
    end
  end
end