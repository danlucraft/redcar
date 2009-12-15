
Dir[File.dirname(__FILE__) + "/*.jar"].each {|fn| require fn }

module JavaMateView
  import com.redcareditor.mate.MateText
  import com.redcareditor.mate.Grammar
  import com.redcareditor.mate.Bundle
  import com.redcareditor.mate.Parser
  import com.redcareditor.theme.Theme
  import com.redcareditor.theme.ThemeManager
end

