
module Redcar
  module Textmate
    class BundleEditor
      def self.write_bundle bundle
        File.open(File.expand_path(File.join(bundle.path,'info.plist')), 'w') do |f|
          f.puts(Plist.plist_to_xml(bundle.plist))
        end
      end

      def self.refresh_trees bundle_names=nil
        Redcar.app.windows.map {|w|
          w.treebook.trees
        }.flatten.select {|t|
          t.tree_mirror.is_a?(Redcar::Textmate::TreeMirror)
        }.each {|t|
          t.tree_mirror.refresh(bundle_names) if bundle_names
          t.refresh
        }
      end

      def self.reload_cache
        Redcar::Textmate.cache.clear
        Redcar::Textmate.cache.cache do
          Textmate.all_bundles
        end
      end

      def self.generate_id
        Java::JavaUtil::UUID.randomUUID.to_s.upcase
      end

      def self.rot13 email
        email.tr("A-Za-z", "N-ZA-Mn-za-m")
      end

      def self.resource file
        File.join(File.expand_path(File.join(File.dirname(__FILE__),'..','..','views',file)))
      end
    end
  end
end