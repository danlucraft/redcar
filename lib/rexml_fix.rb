
# Ubuntu ruby package 1.8.6.111-2ubuntu1.2 contains a REXML bug. This tests for the 
# bug and fixes REXML if it is found.

require 'rexml/document'
require 'rexml/entity'

file_path = File.expand_path(File.dirname(__FILE__))

begin
  REXML::Document.new(File.read("#{file_path}/rexml_fix_test_data.xml")).root.each_element_with_text{ |e| e.name }
rescue NoMethodError => e
  if e.message.include? "record_entity_expansion"
    module REXML
      class Entity < Child
        def unnormalized
          document.record_entity_expansion! if document
          v = value()
          return nil if v.nil?
          @unnormalized = Text::unnormalize(v, parent)
          @unnormalized
        end
      end

      class Document < Element
        @@entity_expansion_limit = 10_000
        def self.entity_expansion_limit= val
          @@entity_expansion_limit = val
        end
        
        def record_entity_expansion!
          @number_of_expansions ||= 0
          @number_of_expansions += 1
          if @number_of_expansions > @@entity_expansion_limit
            raise "Number of entity expansions exceeded, processing aborted."
          end
        end
      end
    end
  end
end

