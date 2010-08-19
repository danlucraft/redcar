def test_bundle
  File.expand_path(File.dirname(__FILE__) + "/test_bundle.tmbundle")
end

def bundle_path
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles")
end

def tmp_bundle_path_1
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles/test_bundle.tmbundle")
end

Before do
  FileUtils.rm_rf tmp_bundle_path_1
end

After do
  FileUtils.rm_rf tmp_bundle_path_1
end
