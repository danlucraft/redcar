
module Redcar
  # An Apple Plist parser.
  class Plist
    class PlistException < StandardError
    end

    # Convert an xml representation of a plist (in the proper form)
    # into a Ruby representation formed by Arrays, Hashes and Strings.
    def self.xml_to_plist(xml)
      self.plist_from_xml(xml)
    end

    def self.plist_from_xml(xml_string) # :nodoc:
      require 'rexml/document'
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

    def self.plist_to_xml1(element, xml_el)
      case element.class.to_s
      when "Hash"
        child = xml_el.add_element "dict"
        element.keys.sort.each do |key|
          e1 = child.add_element "key"
          e1.text = key
          plist_to_xml1(element[key], child)
        end
      when "Array"
        child = xml_el.add_element "array"
        element.each do |arr_el|
          plist_to_xml1(arr_el, child)
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
      plist.each do |el|
        plist_to_xml1(el, xml_el)
      end
      str = ""
      doc.write(str, 0)
      dt=<<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
END
      (dt+str).gsub("\'", "\"")
    end
  end
end