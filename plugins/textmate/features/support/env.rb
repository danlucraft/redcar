def test_bundle
  File.expand_path(File.dirname(__FILE__) + "/test_bundle.tmbundle")
end

def tmp_bundle_path
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles/test_bundle.tmbundle")  
end

def reset_tmp_bundle
  FileUtils.rm_rf tmp_bundle_path
  FileUtils.mkdir tmp_bundle_path
  #FileUtils.cp_r(test_bundle, tmp_bundle_path)
end

Before do
  reset_tmp_bundle
end

After do
  FileUtils.rm_rf tmp_bundle_path
end