
class ProjectSearch
  class BinaryDataDetector
    def self.binary?(data)
      found_good_byte = false
      data.each_byte do |b|
        return true if bad_byte?(b)
        found_good_byte = found_good_byte || good_byte?(b)
      end
      !found_good_byte
    end
    
    INDIVIDUAL_GOOD_BYTES = [9, 10, 13]
    
    def self.good_byte?(byte)
      (byte >= 32 and byte <= 255) or INDIVIDUAL_GOOD_BYTES.include?(byte)
    end
    
    INDIVIDUAL_BAD_BYTES = [0, 6, 14]
    
    def self.bad_byte?(byte)
      (byte >= 14 and byte <= 31) or INDIVIDUAL_BAD_BYTES.include?(byte)
    end
  end
end