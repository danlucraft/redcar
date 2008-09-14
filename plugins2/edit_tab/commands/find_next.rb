module Redcar
  class Find < Redcar::EditTabCommand
    key  "Ctrl+F"
    icon :FIND
    norecord

    class FindSpeedbar < Redcar::Speedbar
      label "Find:"
      textbox :query_string
      button "Go", nil, "Return" do |sb|
        FindNextRegex.new(Regexp.new(sb.query_string)).do
      end
    end

    def execute
      sp = FindSpeedbar.instance
      sp.show(win)
    end
  end
end
