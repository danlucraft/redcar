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
        @latest_version ||= Net::HTTP.get(URI.parse("http://s3.amazonaws.com/redcar2/current_version.txt?instance_id=#{Application.instance_id}")).strip
      end
      
      def self.newer_version?
        latest_version_bits = latest_version.split(".").map(&:to_i)
        [latest_version_bits, [Redcar::VERSION_MAJOR, Redcar::VERSION_MINOR, Redcar::VERSION_RELEASE]].sort.last == latest_version_bits
      end
      
    end
  end
end