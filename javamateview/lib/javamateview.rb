
require 'javamateview/joni'
require 'javamateview/jcodings'
require 'javamateview/jdom'

require 'javamateview/jar/java-mateview'

module JavaMateView
  import com.redcareditor.mate.Bundle
  import com.redcareditor.mate.Grammar
  import com.redcareditor.mate.MateText
  import com.redcareditor.mate.Parser
  import com.redcareditor.mate.ParserScheduler
  import com.redcareditor.mate.Pattern
  import com.redcareditor.mate.Scope
  import com.redcareditor.mate.ScopeMatcher
  import com.redcareditor.theme.Theme
  import com.redcareditor.theme.ThemeManager
  
  class MateText
    def set_root_scope_by_content_name(grammar_name, name)
      scope = JavaMateView::Scope.new(self, "re")
      bs = JavaMateView::Bundle.bundles
      ruby = bs.detect {|b| b.name == grammar_name}
      ps = ruby.grammars.first.patterns
      dps = ps.select {|pt| pt.is_a?(Java::ComRedcareditorMate::DoublePattern) }  
      rps = dps.detect {|pt| pt.contentName == name }
      scope.pattern = rps
      scope.isOpen = true
      self.parser.root = scope
    end
    
    def delay_parsing
      parser.parserScheduler.deactivate
      yield
      parser.parserScheduler.reactivate
    end
  end
end

 