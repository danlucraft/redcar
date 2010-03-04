module Redcar
  class AutoPairer
    module PairsForScope
      def self.autopair_rules
        @autopair_rules ||= begin
          rules = Hash.new {|h, k| h[k] = {}}
          @autopair_default = nil
          start = Time.now
          all_settings = Textmate.all_bundles.map {|b| b.preferences}.flatten.map {|p| p.settings }.flatten
          all_settings.each do |setting|
            if setting.is_a?(Textmate::SmartTypingPairsSetting)
              if setting.scope
                rules[setting.scope] = Hash[*setting.pairs.flatten]
              else
                @autopair_default = Hash[*setting.pairs.flatten]
              end
            end
          end
          if @autopair_default
            @autopair_default1 = @autopair_default.invert
          end
          puts "loaded autopair rules in #{Time.now - start}s"
          rules.default = nil
          rules
        end
      end
      
      def self.autopair_default
        @autopair_default ||= begin
          autopair_rules
          @autopair_default
        end
      end

      def self.cache
        @cache ||= {}
      end

      def self.pairs_for_scope(current_scope)
        cache[current_scope] ||= begin
          rules = nil
          if current_scope
            matches = autopair_rules.map do |scope_name, value|
              if match = JavaMateView::ScopeMatcher.get_match(scope_name, current_scope)
                [scope_name, match, value]
              end
            end.compact
            best_match = matches.sort do |a, b|
              JavaMateView::ScopeMatcher.compare_match(current_scope, a[1], b[1])
            end.last
            if best_match
              rules = best_match[2]
            end
          end
          rules = autopair_default unless rules
          rules
        end
      end
    end
  end
end