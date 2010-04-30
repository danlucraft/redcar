module Redcar
  class Project
  
    class FindFileDialog < FilterListDialog
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('find_file_dialog')
          storage.set_default('ignore_files_that_match_these_regexes', [])
          storage.set_default('ignore_files_that_match_these_regexes_example_for_reference', [/.*\.class/i])
          storage
        end
      end
      
      attr_reader :project
      
      def initialize(project)
        super()
        @project = project
      end

      def close
        super
      end
      
      def update_list(filter)
        if filter.length < 2
          paths = recent_files
        else
          paths = find_files_from_list(filter, recent_files) + 
                  find_files(filter, project.path)
          paths.uniq! # in case there's some dupe's between the two lists
        end
                
        @last_list = paths        
        full_paths = paths
        display_paths = full_paths.map { |path| display_path(path) }
        if display_paths.uniq.length < full_paths.length
          # search out and expand duplicates
          duplicates = duplicates_as_hash(display_paths)
          display_paths.each_with_index do |dp, i|
            if duplicates[dp]
              display_paths[i] = display_path(full_paths[i], project.path.split('/')[0..-2].join('/'))
            end
          end
        end
        display_paths
      end
      
      def selected(text, ix, closing=false)
        if @last_list
          close
          FileOpenCommand.new(@last_list[ix]).run
        end
      end
      
      private
          
      def recent_files
        files = project.recent_files
        ((files[0..-2]||[]).reverse + [files[-1]]).compact
      end
    
      def duplicates_as_hash(enum)
        enum.inject(Hash.new(0)) {|h,v| h[v] += 1; h }.reject {|k,v| v == 1 }
      end

      def display_path(path, first_remove_this_prefix = nil)
        n = -3
        if first_remove_this_prefix and path.index(first_remove_this_prefix) == 0
          path = path[first_remove_this_prefix.length..-1]
          # show the full subdirs in the case of collisions
          n = -100
        end
        
        if path.count('/') > 0
          count_back = [-path.count('/'), n].max
          path.split("/").last +
            " (" +
            path.split("/")[count_back..-2].join("/") +
            ")"
        else
          path
        end
      end
      
      def ignore_regexes
        self.class.storage['ignore_files_that_match_these_regexes']
      end
      
      def ignore_file?(filename)
        ignore_regexes.any? {|re| re =~ filename }
      end
      
      def find_files_from_list(text, file_list)
        re = make_regex(text)
        file_list.select { |fn| 
          fn.split('/').last =~ re
        }.compact
      end
      
      def find_files(text, directories)
        filter_and_rank_by(project.all_files, text) do |fn|
          fn.split("/").last
        end
      end
    end
  end
end
