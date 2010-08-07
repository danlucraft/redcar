
module Redcar
  module Scm
    module Git
      class Change
        include Redcar::Scm::ScmMirror::Change
        
        STATUS_MAP = {
          "M" => :changed,
          "A" => :added,
          "D" => :deleted
        }
        
        def initialize(file, icon=:file)
          @file = file
          @icon = icon
        end
        
        def path
          @file.path          
        end
        
        def status
          if @file.untracked
            :new
          else
            STATUS_MAP[@file.type]
          end
        end
        
        def text
          @file.type_raw.sub(' ', '_') + ": " + @file.path
        end
        
        def icon
          @icon
        end
      end
    end
  end
end
