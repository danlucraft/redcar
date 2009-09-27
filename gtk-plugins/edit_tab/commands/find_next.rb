module Redcar
  class Find < Redcar::EditTabCommand
    key  "Super+F"
    icon :FIND
    norecord

    class FindSpeedbar < Redcar::Speedbar
      label "Find:"
      textbox :query_string
      toggle :wrap, "Wrap?", "Ctrl+Space"
      button "Go", nil, "Return" do |sb|
        FindNextRegex.new(Regexp.new(sb.query_string), sb.wrap).do
      end
    end

    def execute
      sp = FindSpeedbar.new
      sp.show(tab)
    end
  end
end
