module Redcar
  module Textmate
    class Environment

      def initialize
        @env = {}
        @env['TM_RUBY'] = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])
        
        current_scope = nil
        if document = Redcar::EditView.focussed_edit_view_document
          line = document.get_line(document.cursor_line)
          line = line[0..-2] if line[-1..-1] == "\n"
          @env['TM_CURRENT_LINE'] = line
          @env['TM_LINE_INDEX'] = document.cursor_line_offset.to_s
          @env['TM_LINE_NUMBER'] = (document.cursor_line + 1).to_s
          if document.selection?
            @env['TM_SELECTED_TEXT'] = document.selected_text
          end
          if mirror = Redcar::EditView.focussed_document_mirror
            @env['TM_DIRECTORY'] = File.dirname(mirror.path)
            @env['TM_FILEPATH'] = mirror.path
            @env['TM_FILENAME'] = File.basename(mirror.path)
          end
          if cursor_scope = document.cursor_scope
            @env['TM_SCOPE'] = current_scope
          end
        end
        if Redcar::EditView.focussed_tab_edit_view.soft_tabs?
          @env['TM_SOFT_TABS'] = "YES"
        else
          @env['TM_SOFT_TABS'] = "NO"
        end

        @env['TM_TAB_SIZE'] = Redcar::EditView.focussed_tab_edit_view.tab_width.to_s
  
        #preferences = {}
        #Bundle.bundles.each do |this_bundle|
        #  this_bundle.preferences.each do |name, prefs|
        #    scope = prefs["scope"]
        #    if scope
        #      next unless current_scope
        #      next unless match = Gtk::Mate::Matcher.get_match(scope, current_scope)
        #    end
        #    settings = prefs["settings"]
        #    if shell_variables = settings["shellVariables"]
        #      if preferences[name]
        #        prev_match, _ = preferences[name]
        #        if Gtk::Mate::Matcher.compare_match(current_scope, prev_match, match) < 0
        #          preferences[name] = [match, shell_variables, this_bundle.name]
        #        end
        #      else
        #        preferences[name] = [match, shell_variables, this_bundle.name]
        #      end
        #    end
        #  end
        #end
        #
        #preferences.each do |name, pair|
        #  shell_variables, bundle_name = *pair[1..-1]
        #  shell_variables.each do |variable_hash|
        #    name = variable_hash["name"]
        #    @env_variables << name unless @env_variables.include?(name)
        #    log.debug { "setting #{name.inspect} to #{variable_hash["value"].inspect} from #{bundle_name.inspect}" }
        #    ENV[name] = variable_hash["value"]
        #  end        
        #end
      end
    
      def [](key)
        @env[key]
      end
    end
  end
end