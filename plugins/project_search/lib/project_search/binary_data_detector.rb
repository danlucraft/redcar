
class ProjectSearch
  # This class discriminates between binary and textual data. 
  class BinaryDataDetector
    # Is the data binary?
    #
    # @param [String] data 
    def self.binary?(data)
      not textual?(data)
    end
    
    # Is the data plain text?
    #
    # @param [String] data 
    def self.textual?(data)
      found_good_byte = false
      data.each_byte do |b|
        return false if bad_byte?(b)
        found_good_byte = found_good_byte || good_byte?(b)
      end
      found_good_byte
    end
    
    INDIVIDUAL_GOOD_BYTES = [9, 10, 13]
    
    # At least one of these good bytes must be found for the text to be 
    # discriminated as plain text.
    #
    # @param [Fixnum] byte
    def self.good_byte?(byte)
      (byte >= 32 and byte <= 255) or INDIVIDUAL_GOOD_BYTES.include?(byte)
    end
    
    INDIVIDUAL_BAD_BYTES = [0, 6, 14]
    
    # If any of these bytes are found then we immediately discriminate the data 
    # as binary.
    #
    # @param [Fixnum] byte
    def self.bad_byte?(byte)
      (byte >= 14 and byte <= 31) or INDIVIDUAL_BAD_BYTES.include?(byte)
    end
  end
end


