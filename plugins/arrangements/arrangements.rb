
# redcar/scripts/arrangements
# Allows users to save and load window arrangements of panes and tabs.
# D.B. Lucraft, Copyright 17/Mar/07
#
# (1) Remembers the layouts of panes in a window.
# (2) Remembers the positions of tabs based on their type, and places
#     them correctly when asked or on the creation of a tab.

require 'pp'

module Redcar
  module Plugins
    module Arrangements
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        Redcar.current_window.apply_arrangement Redcar.arrangements["default"]
        plugin.transition(FreeBASE::RUNNING)
      end
    end
  end
end

module Redcar
  DEFAULT_ARRANGEMENT = { "types" => ["Redcar::TextTab"],
                          "tab_angle" => "horizontal",
                          "tab_position" => "top" }
  
  class << self
    attr_accessor :last_pane, :arrangments
    
    def arrangements(reload=false)
      if reload or !@arrangements
        begin
          yaml_str = IO.readlines(Redcar.CUSTOM_DIR + "/arrangements.yaml").join
          @arrangements = YAML.load(yaml_str)
        rescue Errno::ENOENT
          @arrangements = {"default" => DEFAULT_ARRANGEMENT}
          File.open(Redcar.CUSTOM_DIR + "/arrangements.yaml", "w") do |f|
            f.puts @arrangements.to_yaml
          end
          @arrangements
        end
      else
        @arrangements
      end
      @arrangements
    end
    
    def save_arrangements
      File.open(Redcar.CUSTOM_DIR + "/arrangements.yaml", "w") do |f|
        f.puts @arrangements.to_yaml
      end
    end
    
    def save_arrangement(name)
      @arrangements[name] = Redcar.current_window.saveable_object
    end
    
    def new_tab(type=TextTab, *args)
      nt = Redcar.current_pane.new_tab(type, *args)
      Redcar.current_window.place_tab(nt)
      nt
    end
  end
  
  module Arrangements
    def self.get_type(tab)
      tab.class.to_s
    end
      
    module PanesInstanceMethods
      def saveable_object
        @build_pane_types = []
        obj = saveable_object1(panes_struct[0])
        types = @build_pane_types.flatten.uniq
        types.each do |type|
          sorted = @build_pane_types.sort do |a, b|
            num1 = a.select{|el| el == type}
            num2 = b.select{|el| el == type}
            num1 <=> num2
          end
          if sorted.length > 2
            sorted[0..(sorted.length-2)].each do |arr|
              arr.delete type
            end
          elsif sorted.length == 2
            sorted.first.delete type
          end
        end
        @build_pane_types.each {|el| el.uniq!}
        obj
      end
      
      def saveable_object1(el)
        if el.is_a? Pane
          types = el.tabs.collect do |tab|
            Arrangements.get_type(tab)
          end
          @build_pane_types << types
          return {
            "types" => types, 
            "tab_position" => el.tab_position.to_s,
            "tab_angle" => el.tab_angle.to_s
          }
        elsif el.is_a? Hash
          obj = el.clone
          paned = obj["paned"]
          case obj["split"]
          when "horizontal"
            pc = paned.position.to_f/paned.allocation.width.to_f
            obj["position"] = pc
            obj["left"] = saveable_object1(el["left"])
            obj["right"] = saveable_object1(el["right"])
          when "vertical"
            pc = paned.position.to_f/paned.allocation.height.to_f
            obj["position"] = pc
            obj["top"] = saveable_object1(el["top"])
            obj["bottom"] = saveable_object1(el["bottom"])
          end
          obj.delete "paned"
          return obj
        end
      end

      def get_arrangement
        saveable_object
      end
      
      def arrangement
        @current_arrangement
      end
      
      def update_current_arrangement
        @current_arrangement = Redcar.arrangements["current"] = saveable_object
        @pane_types = {}
        update_pane_types(arrangement, panes_struct[0])
      end
      
      def type_to_pane(type)
        update_current_arrangement unless @pane_types
        @pane_types.each do |pane, types|
          if types.include? type
            return pane
          end
        end
        panes.first
      end
      
      def apply_arrangement(arrangement=Redcar.DEFAULT_ARRANGEMENT)
        Redcar.arrangements["current"] = arrangement
        @pane_types = {}
        while size > 1
          panes[0].unify
        end
        apply_arrangement1(arrangement, panes_struct[0])
        update_pane_types(arrangement, panes_struct[0])
        distribute_tabs_by_type
      end
      
      def update_pane_types(arrangement, pane)
        if arrangement.keys.include? "types" # is a pane
          @pane_types[pane] ||= []
          @pane_types[pane] += arrangement["types"]
        elsif arrangement.keys.include? "split"
          case arrangement["split"]
          when "horizontal"
            update_pane_types(arrangement["left"], pane["left"])
            update_pane_types(arrangement["right"], pane["right"])
          when "vertical"
            update_pane_types(arrangement["top"], pane["top"])
            update_pane_types(arrangement["bottom"], pane["bottom"])
          end
        end
      end
      
      def apply_arrangement1(arrangement, pane)
        if arrangement.keys.include? "types"
          pane.tab_angle    = (arrangement["tab_angle"].intern || :horizontal)
          pane.tab_position = (arrangement["tab_position"].intern || :top)
        elsif arrangement.keys.include? "split"
          pc = arrangement["position"] || 0.25
          case arrangement["split"]
          when "horizontal"
            paned, pane1, pane2 = pane.split_horizontal
            paned.position = Redcar.current_window.allocation.width*pc
            apply_arrangement1(arrangement["left"], pane1)
            apply_arrangement1(arrangement["right"], pane2)
          when "vertical"
            paned, pane1, pane2 = pane.split_vertical
            paned.position = Redcar.current_window.allocation.height*pc
            apply_arrangement1(arrangement["top"], pane1)
            apply_arrangement1(arrangement["bottom"], pane2)
          end
        end
      end
      
      def distribute_tabs_by_type
        each_pane do |source_pane|
          source_pane.each_tab do |tab|
            if dest_pane = type_to_pane(Arrangements.get_type(tab))
              source_pane.migrate_tab(tab, dest_pane)
            end
          end
        end
      end
      
      # Places a tab wherever we are currently placing tabs of its type
      def place_tab(tab)
        source_pane = nil
        each_pane do |pane|
          if pane.tabs.include? tab
            source_pane = pane
          end
        end
        if dest_pane = type_to_pane(Arrangements.get_type(tab))
          source_pane.migrate_tab(tab, dest_pane)
        end
      end
    end
  end
  
  class RedcarWindow
    include Arrangements::PanesInstanceMethods
  end
end
