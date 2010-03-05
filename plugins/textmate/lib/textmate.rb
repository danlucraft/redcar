
require 'textmate/bundle'
require 'textmate/environment'
require 'textmate/plist'
require 'textmate/preference'
require 'textmate/snippet'

module Redcar
  module Textmate
    def self.all_bundle_paths
      Dir[File.join(Redcar.root, "textmate", "Bundles", "*")]
    end
    
    def self.all_bundles
      @all_bundles ||= all_bundle_paths.map {|path| Bundle.new(path) }
    end
    
    def self.all_snippets
      @all_snippets ||= begin
        cache = PersistentCache.new("textmate_snippets")
        cache.cache do
          all_bundles.map {|b| b.snippets }.flatten
        end
      end
    end
  end
end





