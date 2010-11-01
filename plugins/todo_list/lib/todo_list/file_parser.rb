module Redcar
  class TodoList
    class FileParser
      TodoItem = Struct.new("TodoItem", :path, :line, :action)

      def initialize
        @tag_list = Hash.new {|h,k| h[k] = [] }
        @optional_colon = ":" if TodoList.storage['require_colon']
      end

      def parse_files(path)
        #IMPROVE: is there a better/more efficient way to find all tags?
        find_dirs(path)
        @tag_list
      end

      def find_dirs(path)
        return unless File.directory? path
        unless TodoList.storage['excluded_dirs'].include? File.basename(path)
          Dir["#{path}/*"].each {|subdir| find_dirs(subdir) }
          find_files(path)
        end
      end

      def find_files(path)
        TodoList.storage['included_suffixes'].each do |suffix|
          files = File.join(path, "*#{suffix}")
          Dir.glob(files).each do |file_path|
            unless TodoList.storage['excluded_files'].include?(File.basename(file_path))
              find_tags(file_path)
            end
          end
        end
      end

      def find_tags(file_path)
        tags = TodoList.storage['tags']
        File.open(file_path) do |file|
          file.readlines.each_with_index do |line, idx|
            included_tags = tags.select {|tag| line.include? "#{tag}#{@optional_colon}" }
            create_tag_items(included_tags, file_path, line, idx)
          end
        end
      end

      def create_tag_items(included_tags, file, line, idx)
        included_tags.each do |tag|
          action = line[(line.index(tag) + tag.length)..-1]
          @tag_list[tag] << TodoItem.new.tap do |t|
            t.path   = file
            t.line   = idx
            t.action = (action.chars.first == ":" ? action[1..-1] : action).strip
          end
        end
      end
    end
  end
end