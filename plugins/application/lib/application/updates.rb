module Redcar
  class Application
    class Updates

      UPDATE_CHECK_INTERVAL = 24*60*60
  
      def self.check_for_new_version
        return unless check_for_updates?
        
        previous_check = Application.storage["last_checked_for_new_version"]
        if !previous_check or previous_check < Time.now - UPDATE_CHECK_INTERVAL
          Redcar.log.info("latest version is: #{latest_version}")
          if newer_version?
            Redcar.log.info("newer version available")
            @update_available = true
          end
          Application.storage["last_checked_for_new_version"] = Time.now
        end
      end
      
      def self.check_for_updates?
        Application.storage["should_check_for_updates"]
      end
      
      def self.toggle_checking_for_updates
        Application.storage["should_check_for_updates"] = !check_for_updates?
      end
      
      def self.update_available?
        @update_available
      end
      
      def self.latest_version
        @latest_version ||= Net::HTTP.get(URI.parse(latest_version_url)).strip
      end
      
      def self.latest_version_url
        "http://s3.amazonaws.com/redcar2/current_version.txt?instance_id=#{Application.instance_id}&version=#{Redcar::VERSION}"
      end
      
      def self.newer_version?
        latest_version_bits = latest_version.chomp.split(".").map(&:to_i)
        newer_than?(latest_version_bits, [Redcar::VERSION_MAJOR, Redcar::VERSION_MINOR, Redcar::VERSION_RELEASE])
      end
      
      def self.newer_than?(new_bits, old_bits)
        # if they are not the same length, pad with 0's to make comparison
        # valid. E.g. 0.10.0 == 0.10
        if new_bits.length > old_bits.length
          old_bits += [0]*(new_bits.length - old_bits.length)
        elsif old_bits.length > new_bits.length
          new_bits += [0]*(old_bits.length - new_bits.length)
        end
        
        return false if new_bits == old_bits
        [new_bits, old_bits].sort.last == new_bits
      end
      
    end
  end
end