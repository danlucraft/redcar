

class Redcar::EditView
  class Theme
    class << self
      attr_reader :themes
    end
    
    def self.load_themes
      # print "loading themes ["
      if File.exist?(Redcar::EditView.cache_dir + "themes.dump")
        str = File.read(Redcar::EditView.cache_dir + "themes.dump")
        @themes = Marshal.load(str)
        #puts " ... from cache]"
      else
        @themes = {}        
        Dir[Redcar::EditView.themes_dir + "*"].each do |file|
          print "."
          xml = IO.readlines(file).join
          plist = Redcar::Plist.plist_from_xml(xml)
          @themes[plist[0]['name']] = Redcar::EditView::Theme.new(plist[0])
        end
        #puts "]"
        str = Marshal.dump(@themes)
        File.open(Redcar::EditView.cache_dir + "themes.dump", "w") do |f|
          f.puts str
        end
      end
    end
    
    def self.default_theme
      theme("Twilight")#Mac Classic")
    end
    
    def self.theme(name)
      case name
      when String
        th = @themes[name]
        unless th
          puts "no such theme: #{name}\nthemes: #{@themes.keys.join(', ')}"
          th = @themes[@themes.keys.first]
        end
        th
      when Theme
        name
      end
    end
    
    def self.theme_names
      @themes.keys
    end
    
#    include DebugPrinter
    attr_accessor :name, :uuid, :global_settings
  
    def initialize(hash)
      @name = hash['name']
      @uuid = hash['uuid']
      @global_settings = hash["settings"].find {|h| h.keys == ["settings"]}["settings"]
      @settings = hash["settings"].reject{|h| h.keys == ["settings"]}
    end
    
    # For a given scopename finds all the settings in the theme which apply to it.
    def settings_for_scope(scope, inner)
      scopes = scope.hierarchy_names(inner)
      scope_join = scopes.join(" ")
      @settings_for_scope ||= {}
      r = @settings_for_scope[scope_join]
      return r if r
      applicables = []
      @settings.each do |setting|
        if setting['scope']
          if rating = applicable?(setting['scope'], scopes)
            applicables << [rating, setting]
          end
        end
      end
      # need to rank them
      applicables = applicables.sort do |a, b|
        if a[0][0] > b[0][0]
          -1
        elsif a[0][0] < b[0][0]
          1
        elsif a[0][0] == b[0][0]
          k = nil
          n = [a[0][1].length, b[0][1].length].max
          0.upto(n-1) do |i|
            ae = a[0][1][i]
            be = b[0][1][i]
            if !k
              if ae and !be
                k = -1
              elsif be and !ae
                k = 1
              elsif ae > be
                k = -1
              elsif ae < be
                k = 1
              end
            end
          end
          k||0
        end
      end.map {|a| a[1]}
      @settings_for_scope[scope_join] = applicables
    end
    
    # Given a scope selector, returns its specificity. E.g keyword.if == 2 and string constant == 2
    def specificity(selector)
      selector.split(/\.|\s/).length
    end
    
    # Returns false if the selector is not applicable to the scope, 
    # and returns the specificity of the selector if it is applicable.
    def applicable?(selector, scopes)
      selector.split(',').each do |subselector|
        subselector = subselector.strip
        
        positive_subselector, negative_subselector = 
          *subselector.split(" - ")
        positive_subselector_components = 
          positive_subselector.split(' ')
        if negative_subselector
          negative_subselector_components = 
            negative_subselector.split(' ')
        else
          negative_subselector_components = nil
        end
        
        (scopes.length-1).downto(0) do |i|
          j = i
          last_num_elements = Array.new(scopes.length, 0)
          pos_match = positive_subselector_components.all? do |comp|
            k = j-1
            match = scopes[j..-1].any? do |scope|
              k += 1
              scope.include? comp
            end
            if match
              last_num_elements[k] = comp.split(".").length
            end
            j += 1
            match
          end
          if pos_match
            if negative_subselector_components
              j -= 2
              neg_match = negative_subselector_components.all? do |comp|
                j += 1
                scopes[j..-1].any? do |scope|
                  scope.include? comp
                end
              end
            else
              neg_match = false
            end
          end
          if pos_match and not neg_match
            spec = positive_subselector_components.
              inject(0) {|m, c| m += specificity(c) }
            last_matching_index = 0
            last_num_elements.each_with_index {|e, i| last_matching_index = i if e > 0}
            return [last_matching_index, last_num_elements.reverse]
          end
        end
       end
      false
    end
    
    def self.parse_colour(str_colour)
      Gdk::Color.parse(clean_colour(str_colour))
    end
    
    def self.clean_colour(str_colour)
      return nil unless str_colour
      if str_colour.length == 7
        str_colour
      elsif str_colour.length == 9
        # FIXME: what are the extra two hex values for? 
        # (possibly they are an opacity)
        # #12345678
        #'#'+str_colour[3..-1]
        r = str_colour[1..2].hex
        g = str_colour[3..4].hex
        b = str_colour[5..6].hex
        t = str_colour[7..8].hex
        r = (r*t)/255
        g = (g*t)/255
        b = (b*t)/255
        '#'+("%02x"%r)+("%02x"%g)+("%02x"%b)
#        str_colour[0..6]
      end
    end
    
    def textmate_settings_to_pango_options(settings)
      v = settings["pango"]
      return v if v
      options = { :foreground => Theme.clean_colour(settings["foreground"]),
                  :background => Theme.clean_colour(settings["background"]) }
      options = options.delete_if{|k, v| !v}
      settings["fontStyle"] ||= ""
      if settings["fontStyle"].include? "italic"
        options["style"] = Pango::STYLE_ITALIC
      end
      if settings["fontStyle"].include? "underline"
        options["underline"] = Pango::UNDERLINE_LOW
      end
      if settings["fontStyle"].include? "bold"
        options["weight"] = Pango::WEIGHT_BOLD
      end
      settings["pango"] = options
    end
  end
end
