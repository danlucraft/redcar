
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
        
        attr_reader :repo
        
        def initialize(file, repo, icon=:file, children=[])
          @file = file
          @repo = repo
          @icon = icon
          @children = children
        end
        
        def path
          @file.path          
        end
        
        def status
          # Subprojects should be commitable, but we can't update the
          # current index while they are dirty.
          if icon == :directory && children.length > 0
            [:commitable]
          else
            STATUS_MAP[@file.type_raw]
          end
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
