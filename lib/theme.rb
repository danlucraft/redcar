

module Redcar
  class Theme
    def self.load_themes
      @themes ||= {}
      if @themes.keys.empty?
        Dir.glob("textmate/Themes/Twi*").each do |file|
          xml = IO.readlines(file).join
          plist = Redcar::Plist.plist_from_xml(xml)
          @themes[plist[0]['name']] = Redcar::Theme.new(plist[0])
        end
      end
    end
    
    def self.theme(name)
      @themes[name]
    end
  end
end

Redcar.hook :startup do
  Redcar::Theme.load_themes
end
    
module Redcar
  class Theme
    attr_accessor :name, :uuid, :global_settings
  
    def initialize(hash)
      @name = hash['name']
      @uuid = hash['uuid']
      @global_settings = hash["settings"].find {|h| h.keys == ["settings"]}["settings"]
      @settings = hash["settings"].reject{|h| h.keys == ["settings"]}
    end
    
    # For a given scope finds all the settings in the theme which apply to it.
    def settings_for_scope(scope)
      applicables = []
      @settings.each do |setting|
        if setting['scope']
          if spec = applicable?(setting['scope'], scope)
            applicables << [spec, setting]
          end
        end
      end
      applicables.sort_by {|a| -a[0]}.map {|a| a[1]}
    end
    
    # Given a scope selector, returns its specificity. E.g keyword.if == 2 and string constant == 2
    def specificity(selector)
      selector.split(/\.|\s/).length
    end
    
    # Returns false if the selector is not applicable to the scope, and returns the specificity of the
    # selector if it is applicable.
    def applicable?(selector, scope)
      # split by commas (which are ORs)
      selector.split(',').each do |subselector|
        subselector = subselector.strip
        return specificity(subselector) if subselector == scope
        
        # split on spaces (which are ANDs)
        selector_components = subselector.split(' ')
        has_all = selector_components.inject(1) do |memo, comp|
          if scope.include? comp
            memo *= 1
          else
            memo *= 0
          end
        end
        spec = selector_components.inject(0) {|m, c| m += specificity(c) }
        return spec if has_all == 1
      end
      false
    end
    
    def self.parse_colour(str_colour)
      return nil unless str_colour
      if str_colour.length == 7
        Gdk::Color.parse(str_colour)
      elsif str_colour.length == 9
        # FIXME: what are the extra two hex values for? 
        # (possibly they are an opacity)
        Gdk::Color.parse(str_colour[0..6])
      end
    end
    
    def self.textmate_settings_to_pango_options(settings)
      options = { :foreground => settings["foreground"],
                  :background => settings["background"] }
      options = options.delete_if{|k, v| !v}
      settings["fontStyle"] ||= ""
      if settings["fontStyle"].include? "italic"
        options[:style] = Pango::STYLE_ITALIC
      end
      if settings["fontStyle"].include? "underline"
        options[:underline] = Pango::UNDERLINE_LOW
      end
      options
    end
  end
end
