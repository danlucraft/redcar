
module Redcar
  module Scm
    module Git
      class Change
        include Redcar::Scm::ScmMirror::Change
        
        STATUS_MAP = {
          '??' => [:new],
          'UU' => [:unmerged],
          'M ' => [:indexed],
          'A ' => [:indexed],
          'D ' => [:deleted],
          'R ' => [:moved],
          'AM' => [:indexed, :changed],
          'MM' => [:indexed, :changed],
          'AD' => [:indexed, :missing],
          'MD' => [:indexed, :missing],          
          ' M' => [:changed],
          ' D' => [:missing],
        }
        
        attr_reader :repo
        
        def initialize(file, repo, type=:file, children=[])
          @file = file
          @repo = repo
          @type = type
          @children = children
        end
        
        def path
          @file.path          
        end
        
        def git_status
          @file.type_raw
        end
        
        def status
          # Subprojects should be commitable, but we can't update the
          # current index while they are dirty.
          if @type == :sub_project && children.length > 0
            [:commitable]
          else
            STATUS_MAP[@file.type_raw] || []
          end
        end
        
        def text
          @file.type_raw.sub(' ', '_') + ": " + @file.path
        end
        
        def icon
          @type == :file ? :file : :directory
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
