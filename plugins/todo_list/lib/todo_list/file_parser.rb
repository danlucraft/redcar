module Redcar
  class TodoList
    class FileParser

      def initialize
        @tag_list = {}
      end

      def parse_files(path)
        #IMPROVE: is there a better/more efficient way to find all tags?
        find_dirs(path)
        @tag_list
      end

      def find_dirs(path)
        unless TodoList.storage['excluded_dirs'].to_a.include?(path.to_s)
          Dir["#{path.to_s}/*/"].map do |a|
            find_dirs(a)
          end
          find_files(path)
        end
      end

      def find_files(path)
        TodoList.storage['included_suffixes'].each do |suffix|
          files = File.join(path.to_s, "*#{suffix}")
          Dir.glob(files).each do |file_path|
            unless TodoList.storage['excluded_files'].to_a.include?(File.basename(file_path))
              find_tags(file_path)
            end
          end
        end
      end

      def find_tags(file_path)
        TodoList.storage['tags'].each do |tag|
          if TodoList.storage['require_colon']
            tag += ":"
          end
          file = File.new(file_path,"r")
          i = 1
          while(line = file.gets)
            if(line.include?(tag))
              action = line[line.index(tag.to_s)+tag.length,line.length]
              @tag_list[tag+file_path.to_s+":#{i}"] = action
            end
            i +=1
          end
          file.close
        end
      end
    end
  end
end