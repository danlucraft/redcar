
module Redcar
  module Scm
    module Git
      class Change
        include Redcar::Scm::ScmChangesMirror::Change
        
        STATUS_MAP_INDEXED = {
          'M ' => [:indexed],
          'A ' => [:indexed],
          'D ' => [:deleted],
          #'R ' => [:moved],
          #'C ' => [:moved],
          'AM' => [:indexed],
          'MM' => [:indexed],
          #'RM' => [:moved],
          #'CM' => [:moved],
          'AD' => [:indexed],
          'MD' => [:indexed],
          #'RD' => [:moved],
          #'CD' => [:moved],
        }
        
        STATUS_MAP_UNINDEXED = {
          '??' => [:new],
          'UU' => [:unmerged],
          'AM' => [:changed],
          'MM' => [:changed],
          #'RM' => [:changed],
          #'CM' => [:changed],
          'AD' => [:missing],
          'MD' => [:missing],
          #'RD' => [:missing],
          #'CD' => [:missing],
          ' M' => [:changed],
          ' D' => [:missing],
        }
        
        attr_reader :repo
        
        def initialize(file, repo, type=:file, indexed=false, children=[])
          @file = file
          @repo = repo
          @type = type
          @indexed = indexed
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
          elsif @indexed
            STATUS_MAP_INDEXED[@file.type_raw] || []
          else
            STATUS_MAP_UNINDEXED[@file.type_raw] || []
          end
        end
        
        def text
          @file.type_raw.sub(' ', '_') + ": #{File.basename(@file.path)} (#{File.dirname(@file.path)})"
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
        
        def to_data
          raise "#to_data not implemented"
        end
      end
    end
  end
end
