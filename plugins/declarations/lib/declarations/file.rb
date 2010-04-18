
module Redcar
  class Declarations
    class File
      attr_reader :tags, :path
      
      def initialize(path)
        @path = path
        @tags = []
        load
      end
      
      def add_tags(tags)
        @tags += tags
      end
      
      def load
        @tags = []
        return unless ::File.exist?(path)
        ::File.read(path).each_line do |line|
          key, path, *match = line.split("\t")
          if [key, path, match].all? { |el| !el.nil? && !el.empty? }
            @tags << [key, path, match.join("\t").chomp]
          end
        end
        @tags
      end
      
      def add_tags_for_paths(add_paths)
        parser = Declarations::Parser.new
        parser.parse(add_paths)
        add_tags(parser.tags)
      end
      
      def remove_tags_for_paths(remove_paths)
        @tags = @tags.reject do |_, path, _|
          remove_paths.include?(path)
        end
      end
      
      def dump
        @tags.sort!
        tempfile = Tempfile.new('tags')
        tempfile.close # we need just temp path here
        ::File.open(tempfile.path, "w") do |tags_file|
          @tags.each do |id, path, declaration|
            tags_file.puts "#{id}\t#{path}\t#{declaration}"
          end
        end
        FileUtils.mv(tempfile.path, path)
      end
    end
  end
end
