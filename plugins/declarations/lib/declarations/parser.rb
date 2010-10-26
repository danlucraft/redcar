
module Redcar
  JAVA_YAML=<<-YAML
  - regex:    "class\\s+(\\w+)"
    capture:  1
    type:     id
    kind:     class
  - regex:    "interface\\s+(\\w+)"
    capture:  1
    type:     id
    kind:     interface
  - regex:    "(public|private).*\\s+(\\w+)\s*\\("
    capture:  2
    type:     id
    kind:     method
  YAML
  
  RUBY_YAML=<<-YAML
  - regex:    "^[^#]*(class|module)\\s+(?:\\w*::)*(\\w+)(?:$|\\s|<)"
    capture:  2
    type:     id
    kind:     class
  - regex:    "^[^#]*def ((self\\.)?(\\w+[?!=]?)(\(.*\))?)"
    capture:  1
    type:     id
    kind:     method
  - regex:    "^[^#]*attr(_reader|_accessor|_writer)(.*)$"
    capture:  2
    type:     id-list
    kind:     attribute
  - regex:    "^[^#]*alias\\s+:(\\w+)"
    capture:  1
    type:     id
    kind:     alias
  - regex:    "^[^#]*alias_method\\s+:(\\w+[?!]?)"
    capture:  1
    type:     id
    kind:     alias
  - regex:    "^\\s*([A-Z]\\w*)\\s*="
    capture:  1
    type:     id
    kind:     assignment
  YAML

  PHP_YAML=<<-YAML
  - regex:    "class\\s+(\\w+)"
    capture:  1
    type:     id
    kind:     class
  - regex:    "interface\\s+(\\w+)"
    capture:  1
    type:     id
    kind:     interface
  - regex:    "function\\s+(\\w+)\s*\\("
    capture:  1
    type:     id
    kind:     method
  YAML
  
  class Declarations
    class Parser
      DEFINITIONS = {
        /\.rb$/   => YAML.load(RUBY_YAML),
        /\.java$/ => YAML.load(JAVA_YAML),
        /\.php$/ => YAML.load(PHP_YAML)
      }
      
      attr_reader :tags
      
      def initialize
        @tags = []
      end
      
      def parse(files)
        files.each do |path|
          @tags += match_in_file(path)
        end
      end
      
      def decls_for_file(path)
        DEFINITIONS.each do |fn_re, decls|
          if path =~ fn_re
            return decls
          end
        end
        nil
      end
      
      def match_kind(path, match)
        if decls = decls_for_file(path)
          decls.each do |decl|
            if match.match(Regexp.new(decl["regex"]))
              return decl["kind"]
            end
          end
        end
      end
      
      private
      
      def match_in_file(path)
        tags = []
        begin
          process_file(path) do |line, decl|
            if md = line.match(Regexp.new(decl["regex"]))
              capture = md[decl["capture"]]
              case decl["type"]
              when "id"
                tags << [capture, path, md[0]]
              when "id-list"
                tags += capture.scan(/\w+/).map {|id| [id, path, md[0]] }
              end
            end
          end
          tags
        rescue
          []
        end
      end
      
      def process_file(path, &block)
        if decls = decls_for_file(path)
          decls.each do |decl|
            file(path).each_line do |line|
              block.call(line, decl)
            end
          end
        end
      end
      
      def file(path)
        ::File.read(path)
      end
      
    end
  end
end

