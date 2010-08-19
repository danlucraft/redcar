def test_bundle
  File.expand_path(File.dirname(__FILE__) + "/test_bundle.tmbundle")
end

def test_bundle2
  File.expand_path(File.dirname(__FILE__) + "/test_bundle2.tmbundle")
end

def test_groups_bundle
  File.expand_path(File.dirname(__FILE__) + "/test_groups_bundle.tmbundle")
end

def bundle_path
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles")
end

def tmp_bundle_path_1
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles/test_bundle.tmbundle")
end

def tmp_bundle_path_2
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles/test_bundle2.tmbundle")
end
def tmp_test_groups_bundle
  File.expand_path(File.dirname(__FILE__) + "/../../vendor/redcar-bundles/Bundles/test_groups_bundle.tmbundle")
end

def reset_tmp_bundles
  FileUtils.rm_rf tmp_bundle_path_1
  FileUtils.rm_rf tmp_bundle_path_2
  FileUtils.rm_rf tmp_test_groups_bundle

  FileUtils.mkdir tmp_bundle_path_2
  FileUtils.cp_r(test_bundle2, bundle_path)

  FileUtils.mkdir tmp_test_groups_bundle
  FileUtils.cp_r(test_groups_bundle, bundle_path)
end

Before do
  reset_tmp_bundles
end

After do
  FileUtils.rm_rf tmp_bundle_path_1
  FileUtils.rm_rf tmp_bundle_path_2
  FileUtils.rm_rf tmp_test_groups_bundle
end