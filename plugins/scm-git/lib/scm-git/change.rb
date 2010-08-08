
module Redcar
  module Scm
    module Git
      class Change
        include Redcar::Scm::ScmMirror::Change
        
        STATUS_MAP = {
          '??' => [:new],
          'M ' => [:indexed],
          'A ' => [:indexed],
          'D ' => [:deleted],
          'AM' => [:indexed, :changed],
          'MM' => [:indexed, :changed],
          'MD' => [:indexed, :missing],
          ' M' => [:changed],
          ' D' => [:missing],
        }
        
        def initialize(file, icon, children=[])
          @file = file
          @icon = icon
          @children = children
        end
        
        def path
          @file.path          
        end
        
        def status
          STATUS_MAP[@file.type_raw]
        end
        
        def text
          @file.type_raw.sub(' ', '_') + ": " + @file.path
        end
        
        def icon
          @icon
        end
        
        def leaf?
          icon == :file
        end
        
        def children
          @children
        end
      end
    end
  end
end
