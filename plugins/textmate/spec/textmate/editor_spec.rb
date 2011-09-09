
require File.join(File.dirname(__FILE__), "..", "spec_helper")

include Redcar::Textmate

describe BundleEditor do
  it "should generate valid IDs" do
    java_import "java.util.UUID"
    id = BundleEditor.generate_id
    begin
      UUID.fromString(id).is_a?(UUID).should be_true
    rescue Exception => e
      p e.message
      false.should be_true
    end
  end

  it "should obsfucate email addresses" do
    email = "joe@example.com"
    BundleEditor.rot13(BundleEditor.rot13(email)).should == email
  end

  describe "Updating Bundles" do
    before(:each) do
      create_fixtures
      @bundle = Bundle.new(fake_bundle)
      @app = mock
      Redcar.stub!(:app).and_return(@app)
      @app.stub!(:windows).and_return([])
    end

    after(:each) do
      delete_fixtures
      Redcar::Textmate.all_bundles.delete(@bundle)
    end

    it "should update a snippet with new values" do
      name    = 'Unicorn'
      content = 'I see a unicorn'
      trigger = 'uni'
      scope   = 'text.fake'
      snippet = Snippet.new(test_snippet,@bundle.name)
      BundleEditor.update_snippet snippet, name, content, trigger, scope
      snippet.name.should    == name
      snippet.content.should == content
      snippet.scope.should   == scope
      snippet.tab_trigger.should == trigger
    end

    it "should add a new snippet to a bundle" do
      plist = {
        'uuid' => BundleEditor.generate_id,
        'name' => 'Walrus',
        'content' => 'I am the WALRUS',
        'scope' => 'text.fake'
      }
      xml = Redcar::Plist.plist_to_xml(plist)
      file = write_file('snippet','.tmSnippet',xml)
      snippet = Snippet.new(file.path,@bundle.name)
      BundleEditor.add_snippet_to_bundle snippet, @bundle
      @bundle.snippets.include?(snippet).should be_true
    end

    it "should update an existing bundle" do
      name    = "Fancy Bundle"
      desc    = "A bundle of shiny things"
      contact = "Joe Shmoe"
      email   = "joe@shmoe.com"
      BundleEditor.update_bundle @bundle, name, desc, contact, email
      @bundle.name.should == name
      @bundle.description.should   == desc
      @bundle.contact_name.should  == contact
      @bundle.contact_email.should == email
    end

    it "should create a new bundle" do
      plist = { "uuid" => BundleEditor.generate_id }
      xml = Redcar::Plist.plist_to_xml(plist)
      temp_dir = write_temp_bundle('Fancy',xml)
      new_bundle = Bundle.new(temp_dir)
      new_bundle.path = File.join(textmate_fixtures, 'Fancy.tmbundle')
      name    = "Fancy"
      desc    = "A bundle of shiny things"
      contact = "Joe Shmoe"
      email   = "joe@shmoe.com"
      BundleEditor.update_bundle new_bundle, name, desc, contact, email
      File.exists?(new_bundle.path).should be_true
      new_bundle.name.should          == name
      new_bundle.description.should   == desc
      new_bundle.contact_name.should  == contact
      new_bundle.contact_email.should == email
      new_bundle.uuid.should == plist['uuid']
    end

    it "should delete snippets" do
      size = @bundle.snippets.size
      BundleEditor.delete_snippet(@bundle, @bundle.snippets.first)
      @bundle.snippets.size.should == size - 1
      @bundle.main_menu['items'].size.should == size - 1
    end

    it "should add submenus" do
      name = 'Submenu A'
      if @bundle.sub_menus
        @bundle.sub_menus.detect {|k,v| v['name'] == name }.should be_nil
      end
      BundleEditor.create_submenu(name,@bundle)
      sub = @bundle.sub_menus.detect {|k,v| v['name'] == name }
      sub.should_not be_nil
      name2 = 'Submenu B'
      @bundle.sub_menus.detect {|k,v| v['name'] == name2 }.should be_nil
      BundleEditor.create_submenu(name2,@bundle,sub.first)
      sub2 = @bundle.sub_menus.detect {|k,v| v['name'] == name2 }
      sub2.should_not be_nil
      sub[1]['items'].include?(sub2.first).should be_true
    end

    it "should rename submenus" do
      name = 'Submenu A'
      name2 = 'Submenu 3D'
      BundleEditor.create_submenu(name,@bundle)
      sub = @bundle.sub_menus.detect {|k,v| v['name'] == name }
      BundleEditor.rename_submenu(name2, @bundle, @bundle.sub_menus[sub.first])
      @bundle.sub_menus.detect {|k,v| v['name'] == name  }.should be_nil
      @bundle.sub_menus.detect {|k,v| v['name'] == name2 }.should_not be_nil
    end
  end
end