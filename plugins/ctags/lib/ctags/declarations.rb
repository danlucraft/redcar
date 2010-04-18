
module Redcar
  
  JAVA_YAML=<<-YAML
  - regex:    "class\\s+(\\w+)"
    capture:  1
    type:     id
  - regex:    "interface\\s+(\\w+)"
    capture:  1
    type:     id
  - regex:    "(public|private).*\\s+(\\w+)\s*\\("
    capture:  2
    type:     id
  YAML
  
  RUBY_YAML=<<-YAML
  - regex:    "^[^#]*(class|module)\\s+(\\w+)"
    capture:  2
    type:     id
  - regex:    "^[^#]*def (self\\.)?(\\w+)"
    capture:  2
    type:     id
  - regex:    "^[^#]*attr(_reader|_accessor|_writer)(.*)$"
    capture:  2
    type:     id-list
  - regex:    "^[^#]*alias\s+:(\\w+)"
    capture:  1
    type:     id
  - regex:    "^[^#]*alias_method\s+:(\\w+)"
    capture:  1
    type:     id
  YAML
  
  class Declarations
    DEFINITIONS = {
      /\.rb$/   => YAML.load(RUBY_YAML),
      /\.java$/ => YAML.load(JAVA_YAML)
    }
    
    def initialize(tags_file_path)
      @tags_file_path = tags_file_path
      @tags           = []
    end
    
    def parse(files)
      files.each do |path|
        @tags += match_in_file(path)
      end
    end
    
    def dump
      @tags.sort!
      File.open(@tags_file_path, "w") do |tags_file|
        @tags.each do |id, path, declaration|
          tags_file.puts "#{id}\t#{path}\t#{declaration}"
        end
      end
    end
    
    private
    
    def decls_for_file(path)
      DEFINITIONS.each do |fn_re, decls|
        if path =~ fn_re
          return decls
        end
      end
      nil
    end
    
    def match_in_file(path)
      tags = []
      begin
        file = File.read(path)
        if decls = decls_for_file(path)
          decls.each do |decl| 
            file.each_line do |line| 
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
          end
        end
        tags
      rescue
        []
      end
    end
    
  end
end