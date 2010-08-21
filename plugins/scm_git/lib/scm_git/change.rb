
module Redcar
  module Scm
    module Git
      class Change
        include Redcar::Scm::ScmChangesMirror::Change
        
        STATUS_MAP_INDEXED = {
          'M ' => [:indexed],
          'A ' => [:indexed],
          'D ' => [:deleted],
          'R ' => [:moved],
          'C ' => [:moved],
          'AM' => [:indexed],
          'MM' => [:indexed],
          'RM' => [:moved],
          'CM' => [:moved],
          'AD' => [:indexed],
          'MD' => [:indexed],
          'RD' => [:moved],
          'CD' => [:moved],
        }
        
        STATUS_MAP_UNINDEXED = {
          '??' => [:new],
          'UU' => [:unmerged],
          'AM' => [:changed],
          'MM' => [:changed],
          'RM' => [:changed],
          'CM' => [:changed],
          'AD' => [:missing],
          'MD' => [:missing],
          'RD' => [:missing],
          'CD' => [:missing],
          ' M' => [:changed],
          ' D' => [:missing],
        }
        
        attr_reader :repo, :type
        
        def initialize(file, repo, type=:file, indexed=false, children=[])
          @file = file
          @repo = repo
          @type = type
          @indexed = indexed
          @children = children
        end
        
        def path
          if @file.type_raw[0,1] == "R" or @file.type_raw[0,1] == "C"
            paths = @file.path.split(' -> ')
            paths[1]
          else
            @file.path
          end
        end
        
        def git_status
          @file.type_raw
        end
        
        def status
          # Subprojects should be commitable, but we can't update the
          # current index while they are dirty.
          if @type == :sub_project and @indexed and children.length > 0
            [:commitable]
          elsif @type == :sub_project and @repo.cache['submodules'][path].uncommited_changes.length > 0
            []
          elsif @indexed
            STATUS_MAP_INDEXED[@file.type_raw] || []
          else
            STATUS_MAP_UNINDEXED[@file.type_raw] || []
          end
        end
        
        def text
          "#{File.basename(@file.path)} (#{File.dirname(@file.path)})"
        end
        
        def icon
          case
          when ((@file.type_raw == "??") or (@file.type_raw[0,1] == "A" and @indexed))
            File.join(Scm::ICONS_DIR, (@type == :file ? "notebook" : "folder") + "--plus.png")
          when ((@file.type_raw[0,1] == "M" and @indexed) or (@file.type_raw[1,1] == "M" and (not @indexed)))
            File.join(Scm::ICONS_DIR, (@type == :file ? "notebook" : "folder") + "--pencil.png")
          when (['C', 'R'].include?(@file.type_raw[0,1]) and @indexed)
            File.join(Scm::ICONS_DIR, (@type == :file ? "notebook" : "folder") + "--arrow.png")
          when ((@file.type_raw[0,1] == "D" and @indexed) or (@file.type_raw[1,1] == "D" and (not @indexed)))
            File.join(Scm::ICONS_DIR, (@type == :file ? "notebook" : "folder") + "--minus.png")
          when (@file.type_raw[0,1] == "U" and (not @indexed))
            File.join(Scm::ICONS_DIR, (@type == :file ? "notebook" : "folder") + "--exclamation.png")
          else
            @type == :file ? :file : :directory
          end
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
