
require 'auto_indenter/analyzer'
require 'auto_indenter/document_controller'
require 'auto_indenter/rules'

module Redcar
  class AutoIndenter
    
    def self.document_controller_types
      [AutoIndenter::DocumentController]
    end
    
    class << self
      attr_accessor :test_rules
    end

    def self.cache
      @cache ||= {}
    end
    
    def self.best_match(hash, current_scope)
      matches = hash.map do |scope_name, value|
        if match = JavaMateView::ScopeMatcher.get_match(scope_name, current_scope)
          [scope_name, match, value]
        end
      end.compact
      
      ranked_matches = matches.sort do |a, b|
        JavaMateView::ScopeMatcher.compare_match(current_scope, a[1], b[1])
      end
      
      if best_match = ranked_matches.last
        best_match[2]
      end
    end
    
    def self.rules_for_scope(current_scope)
      return unless current_scope
      if rules = AutoIndenter.test_rules
        return rules
      end
      cache[current_scope] ||= begin
        if inc_best_match = best_match(indentation_rules[:increase], current_scope)
          inc_best_match = Regexp.new(inc_best_match)
        end
        if dec_best_match = best_match(indentation_rules[:decrease], current_scope)
          dec_best_match = Regexp.new(dec_best_match)
        end
        Rules.new(inc_best_match, dec_best_match)
      end
    end
    
    def self.indentation_rules
      @indentation_rules ||= begin
        increase_rules = Hash.new {|h, k| h[k] = {}}
        decrease_rules = Hash.new {|h, k| h[k] = {}}
        increase_settings = Textmate.settings(Textmate::IncreaseIndentPatternSetting)
        decrease_settings = Textmate.settings(Textmate::DecreaseIndentPatternSetting)
        increase_settings.each do |setting|
          if setting.scope
            increase_rules[setting.scope] = setting.pattern
          else
            raise "indent setting without scope! #{setting}"
          end
        end
        decrease_settings.each do |setting|
          if setting.scope
            decrease_rules[setting.scope] = setting.pattern
          else
            raise "indent setting without scope! #{setting}"
          end
        end
        increase_rules.default = nil
        decrease_rules.default = nil
        {:increase => increase_rules, :decrease => decrease_rules}
      end
    end
  end
end
