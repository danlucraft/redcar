module Redcar
  class Project
  
    class FindFileDialog < FilterListDialog
      def self.clear
        # unfortunately we receive a :focussed
        # message when the FindFileDialog
        # itself exits
        # so we only really clear when we receive an *unexpected* message
        if @expect_a_clear
           @expect_a_clear = false
        else
          if storage['clear_cache_on_refocus']
            @cached_dir_lists.clear 
          end
        end
    
      end
      
      @cached_dir_lists = {}
      @expect_a_clear = false
      
      class << self
       attr_reader :cached_dir_lists
       attr_accessor :expect_a_clear
      end
      
      def initialize(win)
        super()        
        # add a :focussed listener to the window if it hasn't
        # been set before
        win.add_listener_at_most_once(FindFileDialog, :focussed) do
          FindFileDialog.clear
        end
        FindFileDialog.expect_a_clear = true
      end
      
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('find_file_dialog')
          storage.set_default('clear_cache_on_refocus', true)
          storage
        end
      end    
      
      def update_list(filter)
        if filter.length < 2
          paths = Project.recent_files
        else
          paths = find_files_from_list(filter, Project.recent_files) + find_files(filter, Redcar.app.focussed_window.treebook.trees.last.tree_mirror.path)             
          paths.uniq! # in case there's some dupe's between the two lists
        end
                
        @last_list = paths        
        full_paths = paths
        display_paths = full_paths.map { |path| display_path(path) }
        if display_paths.uniq.length < full_paths.length
         # search out and expand duplicates
          duplicates = display_paths.duplicates_as_hash
          display_paths.each_with_index{|dp, i|
            if duplicates[dp]
              display_paths[i] = display_path(full_paths[i], Redcar.app.focussed_window.treebook.trees.last.tree_mirror.path.split('/')[0..-2].join('/'))
            end
          }
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
      
      def remove_from_list(path)
        self.class.recent_files.delete(path)
      end
      
      def display_path(path, first_remove_this_prefix = nil)
        n = -3
        if first_remove_this_prefix && path.index(first_remove_this_prefix) == 0
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
          files.reject!{|f|
            begin
              File.directory?(f)
            rescue Errno::ENOENT
              # File.directory? can throw no such file or directory even if File.exist?
              # has returned true. For example this happens on some awful textmate filenames
              # unicode in them.
              true
            end
          }
          files
        end
      end
      
      def find_files_from_list(text, file_list)
        re = make_regex(text)
        file_list.select{|fn| 
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

module Enumerable
  def duplicates_as_hash
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}
  end
end