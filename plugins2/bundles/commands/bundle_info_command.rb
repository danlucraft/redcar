
module Redcar
  class BundleInfoCommand < Redcar::Command
    norecord
    
    def initialize(bundle)
      @bundle = bundle
    end
    
    def execute
      puts @bundle.name
      puts @bundle.info["contactName"]
      puts @bundle.info["contactEmailRot13"].tr!("A-Za-z", "N-ZA-Mn-za-m")
      puts @bundle.info["description"]
      puts
    end
  end
end
