
module Redcar
  class Declarations
    class File
      attr_reader   :tags, :path
      attr_accessor :last_updated
      
      def initialize(path)
        @path = path
        @tags = []
        load unless path.nil?
      end
      
      def load
        @tags = []
        @last_updated = Time.at(0)
        if ::File.exist?(path)
          first_line = true
          ::File.read(path).each_line do |line|
            if first_line
              first_line = false
              @last_updated = Time.at(line.chomp.to_i)
            end
            key, path, *match = line.split("\t")
            if [key, path, match].all? { |el| !el.nil? && !el.empty? }
              @tags << [key, path, match.join("\t").chomp]
            end
          end
        end
      end

      def update_files(file_list)
        changed_files = file_list.changed_since(last_updated)
        changed_files.delete(@path)
        @tags = @tags.select do |_, path, _|
          file_list.contains?(path) and !changed_files[path]
        end
        add_tags_for_paths(changed_files.keys)
        @last_updated = Time.now
      end
      
      def add_tags_for_paths(add_paths)
        parser = Declarations::Parser.new
        parser.parse(add_paths)
        add_tags(parser.tags)
      end
      
      def add_tags(tags)
        @tags += tags
      end
      
      def dump
        @tags = @tags.select {|name, _, _| name}.sort_by {|name, _, _| name }
        tags_file_path = nil
        Tempfile.open('tags') do |tags_file|
          tags_file.puts(@last_updated.to_i.to_s)
          @tags.each do |id, path, declaration|
            tags_file.puts "#{id}\t#{path}\t#{declaration}"
          end
          tags_file.flush
          tags_file_path = tags_file.path
        end
        FileUtils.cp(tags_file_path, path)
        FileUtils.rm(tags_file_path)
      end
    end
  end
end
