
module Redcar
  module Textmate
    class MenuManager
      include Redcar::Observable
      
      def initialize
        add_listener(:refresh_menu) do
          @menus = nil
        end
      end
      
      def build_menu(builder)
        @menus = nil
        if Textmate.storage['load_bundles_menu']
          @menus = begin
            Menu::Builder.build do |a|
              Textmate.all_bundles.sort_by {|b| (b.name||"").downcase}.each do |bundle|
                name = (bundle.name||"").downcase
                unless Textmate.storage['select_bundles_for_menu'] and not Textmate.storage['loaded_bundles'].to_a.include?(name)
                  bundle.build_menu(a).each {|i|builder.append(i)}
                end
              end
            end
          end
        end
      end      
    end
  end
end
