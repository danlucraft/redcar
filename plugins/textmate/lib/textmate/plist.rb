
module Redcar
  # An Apple Plist parser.
  class Plist
    require 'rexml/document'
    require 'rexml/formatters/pretty'

    class PlistException < StandardError
    end

    # Convert an xml representation of a plist (in the proper form)
    # into a Ruby representation formed by Arrays, Hashes and Strings.
    def self.xml_to_plist(xml)
      self.plist_from_xml(xml)
    end

    def self.plist_from_xml(xml_string) # :nodoc:
      REXML::Text::VALID_CHAR << 0x3 if RUBY_VERSION >= '1.9.1'
      xml = REXML::Document.new(xml_string)
      plist_from_xml1(xml.root.elements.to_a.first)
    end

    def self.plist_from_xml1(element) # :nodoc:
      case element.name
      when "dict"
        dict = {}
        l = 0
        element.each_element {|e| l += 1}
        1.step(l-1, 2) do |i|
          key_el = element.elements[i]
          val_el = element.elements[i+1]
          dict[key_el.text] = plist_from_xml1(val_el)
        end
        dict
      when "string"
        element.text
      when "array"
        arr = []
        element.each_element {|el| arr << plist_from_xml1(el) }
        arr
      end
    end

    def self.write_xml_element(element, xml_el)
      case element.class.to_s
      when "Hash"
        child = xml_el.add_element "dict"
        element.keys.sort.each do |key|
          e1 = child.add_element "key"
          e1.text = key
          write_xml_element(element[key], child)
        end
      when "Array"
        child = xml_el.add_element "array"
        element.each do |arr_el|
          write_xml_element(arr_el, child)
        end
      when "String"
        el = xml_el.add_element "string"
        el.text = element
      else
        raise PlistException, "Unknown Plist Type, #{element.class.to_s}"
      end
    end

    # Converts from a Ruby plist to an XML plist.
    def self.plist_to_xml(plist)
      doc = REXML::Document.new
      xml_el = doc.add_element "plist", {"version" => "1.0"}
      write_xml_element(plist, xml_el)
      formatter = Formatter.new(4)
      str = ""
      formatter.write(doc,str)
      dt=<<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
END
      (dt+str).gsub("\'", "\"")
    end

    class Formatter < REXML::Formatters::Pretty
      def write_text(node, output)
        output << node.to_s
      end

      def write_element(node, output)
        output << ' '*@level
        output << "<#{node.expanded_name}"

        node.attributes.each_attribute do |attr|
          output << " "
          attr.write(output)
        end unless node.attributes.empty?

        if node.children.empty?
          output << "/"
        else
          output << ">"
          @level += @indentation
          node.children.each_with_index { |child,i|
            output << "\n" if i == 0 and not child.is_a?(REXML::Text)
            next if child.kind_of?(REXML::Text) and child.to_s.strip.length == 0
            write( child, output )
            output << "\n" unless child.is_a?(REXML::Text)
          }
          @level -= @indentation
          output << ' '*@level unless node.children.last.is_a?(REXML::Text)
          output << "</#{node.expanded_name}"
        end
        output << ">"
      end
    end
  end
end
