module Redcar
  class Project
  
    class FindFileDialog < FilterListDialog
      MAX_ENTRIES = 20
      
      def update_list(filter)
        if filter.length < 2
          paths = Project.recent_files
        else
          paths = find_files_from_list(filter, Project.recent_files) + find_files(filter, Redcar.app.focussed_window.treebook.trees.last.tree_mirror.path)             
          paths.uniq! # just in case there's some dupe's
        end
                
        @last_list = paths        
        full_paths = paths
        display_paths = full_paths.map { |path| display_path(path) }
        if display_paths.uniq.length < full_paths.length
         # search out and expand duplicates
          duplicates = display_paths.duplicates_as_hash
          display_paths.each_with_index{|dp, i|
            if duplicates[dp]
              display_paths[i] = display_path(full_paths[i], 
                  Redcar.app.focussed_window.treebook.trees.last.tree_mirror.path.split('/')[0..-2].join('/'))
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
        if File::ALT_SEPARATOR
          # substitute on doze
          path = path.gsub(File::ALT_SEPARATOR, '/')
        end
        
        n = -3
        if first_remove_this_prefix && path.index(first_remove_this_prefix) == 0
          path = path[first_remove_this_prefix.length..-1]
          # show the full subdirs in the case of collisions
          n = -100
          puts path
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
        @files ||= begin
          files = []
          s = Time.now
          directories.each do |dir|
            files += Dir[File.expand_path(dir + "/**/*")]
          end
          took = Time.now - s
          puts "find files #{directories.inspect} took #{took}s"
          files
        end
      end
      
      def find_files_from_list(text, file_list)
        re = make_regex(text)
        file_list.select{|fn| 
          if File::ALT_SEPARATOR
            # doze
            fn = fn.gsub(File::ALT_SEPARATOR, '/')
          end
          fn.split('/').last =~ re
        }.compact
      end
      
      def find_files(text, directories)
        re = make_regex(text)

        score_match_pairs = []
        cutoff = 10000000
        results = files(directories).each do |fn|
          begin
            unless File.directory?(fn)
              bit = fn.split("/")
              if m = bit.last.match(re)
                cs = []
                diffs = 0
                m.captures.each_with_index do |_, i|
                  cs << m.begin(i + 1)
                  if i > 0
                    diffs += cs[i] - cs[i-1]
                  end
                end
                # lower score is better
                score = (cs[0] + diffs)*100 + bit.last.length
                if score < cutoff
                  score_match_pairs << [score, fn]
                  score_match_pairs.sort!
                  if score_match_pairs.length == MAX_ENTRIES
                    cutoff = score_match_pairs.last.first
                    score_match_pairs.pop
                  end
                end
              end
            end
          rescue Errno::ENOENT
            # File.directory? can throw no such file or directory even if File.exist?
            # has returned true. For example this happens on some awful textmate filenames
            # unicode in them.
          end
        end
        score_match_pairs.map {|a| a.last }
      end

      def make_regex(text)
        re_src = "(" + text.split(//).map{|l| Regexp.escape(l) }.join(").*?(") + ")"
        Regexp.new(re_src, :options => Regexp::IGNORECASE)
      end
    end
  end
end

module Enumerable
  def duplicates_as_hash
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}
  end
end