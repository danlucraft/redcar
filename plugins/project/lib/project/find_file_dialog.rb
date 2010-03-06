module Redcar
  class Project
  
    class FindFileDialog < FilterListDialog
      def self.clear
        if storage['clear_cache_on_refocus']
          @cached_dir_lists.clear 
        end
      end
      
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('find_file_dialog')
          storage.set_default('clear_cache_on_refocus', true)
          storage
        end
      end    
      
      @cached_dir_lists = {}
      
      class << self
        attr_reader :cached_dir_lists
      end
      
      def self.open_dialogs
        @open_dialogs ||= []
      end
      
      def initialize(win)
        super()
        FindFileDialog.open_dialogs << [win, self]
      end
      
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('find_file_dialog')
          storage.set_default('clear_cache_on_refocus', true)
          storage.set_default('ignore_files_that_match_these_regexes', [])
          storage.set_default('ignore_files_that_match_these_regexes_example_for_reference', [/.*\.class/i])
          storage
        end
      end    

      def close
        super
        # remove after so that we ignore the window focus event from the dialog itself closing
        FindFileDialog.open_dialogs.reject! {|a| a.last == self }
      end
      
      def update_list(filter)
        if filter.length < 2
          paths = Project.recent_files_for(Project.focussed_project_path)
        else
          paths = find_files_from_list(filter, Project.recent_files_for(Project.focussed_project_path)) + 
                  find_files(filter, Project.focussed_project_path)             
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
              display_paths[i] = display_path(full_paths[i], Project.focussed_project_path.split('/')[0..-2].join('/'))
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
      
      def files(directories)
        FindFileDialog.cached_dir_lists[directories] ||= begin
          files = []
          s = Time.now
          directories.each do |dir|
            files += Dir[File.expand_path(dir + "/**/*")]
          end
          took = Time.now - s
          puts "find files (#{directories.length} dirs) took #{took}s"
          files.reject do |f|
            begin
              File.directory?(f)
            rescue Errno::ENOENT
              # File.directory? can throw no such file or directory even if File.exist?
              # has returned true. For example this happens on some awful textmate filenames
              # unicode in them.
              true
            end
          end
        end
      end
      
      def not_on_ignore_list(filename)
        self.class.storage['ignore_files_that_match_these_regexes'].each do |re|
          if re =~ filename
            return false
          end
        end
        true
      end
      
      def find_files_from_list(text, file_list)
        re = make_regex(text)
        file_list.select { |fn| 
          fn.split('/').last =~ re
        }.compact
      end
      
      def find_files(text, directories)
        filter_and_rank_by(files(directories), text) do |fn|
          fn.split("/").last
        end
      end
    end
  end
end
