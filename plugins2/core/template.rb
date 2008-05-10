
module Redcar
  module Template
    # This module implements the template system for bundles
    extend FreeBASE::StandardPlugin
    class << self
      attr_accessor :templates
    end
    
    def self.load(plugin) #:nodoc:
      @templates = {}
      Bundle.each do |bundle|
        @templates[bundle.name] = {}
        @templates[bundle.name] = bundle.templates
      end
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.execute_template(template, doc)
      doc.insert_at_cursor(template)
    end
  end
end
