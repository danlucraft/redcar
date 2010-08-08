require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Menu do
  class DummyCommand; end
  
  describe "with no entries and no text" do
    before do
      @menu = Redcar::Menu.new
    end

    it "should accept items" do
      @menu << Redcar::Menu::Item.new("File", DummyCommand)
    end

    it "reports length" do
      @menu.length.should == 0
    end
  end  
  
  describe "with entries in it and text" do
    before do
      @menu = Redcar::Menu.new("Edit") \
                  << Redcar::Menu::Item.new("Cut", DummyCommand) \
                  << Redcar::Menu::Item.new("Paste", DummyCommand) \
                  << Redcar::Menu.new("Convert")
    end

    it "reports length" do
      @menu.length.should == 3
    end
    
    it "has text" do
      @menu.text.should == "Edit"
    end
  end
  
  describe "building entries" do
    before do
      @menu = Redcar::Menu.new
    end
    
    it "should let you add items by building" do
      @menu.build do
        item "Cut", DummyCommand
      end
      @menu.length.should == 1
      @menu.entries.first.text.should == "Cut"
    end
  end
  
  def build(name=nil, &block)
    Redcar::Menu::Builder.build(name, &block)
  end
  
  describe "merging Menus" do
    it "adds items" do
      menu = build "Plugins" do
        item "Foo", 1
        item "Bar", 2
      end
      
      menu2 = build "Plugins" do
        item "Bar", 3
      end
      
      menu.merge(menu2)
      
      menu.should == build("Plugins") do
        item "Foo", 1
        item "Bar", 3
      end
    end

    it "adds Menus" do
      menu = build "Plugins" do
        sub_menu "REPL" do
        end
      end
      
      menu2 = build "Plugins" do
        sub_menu "My Plugin" do
        end
      end
      
      menu.merge(menu2)
      
      menu.should == build("Plugins") do
        sub_menu "REPL" do
        end
        sub_menu "My Plugin" do
        end
        
      end
    end
    
    it "replaces a menu with an item and vice versa" do
      menu = build "Plugins" do
        item "My Plugin", 201
        sub_menu "REPL" do
        end
      end
      
      menu2 = build "Plugins" do
        item "REPL", 101
        sub_menu "My Plugin" do
        end
      end
      
      menu.merge(menu2)
      
      menu.should == build("Plugins") do
        sub_menu "My Plugin" do
        end
        item "REPL", 101
      end
    end
    
    it "puts newer ones on the end" do
      menu = build "Plugins" do
        sub_menu "REPL" do
        end
        sub_menu "Encryption" do
        end
        sub_menu "My Plugin" do
        end
      end

      menu2 = build "Plugins" do
        sub_menu "My Plugin" do
          item "Open", 101
        end
      end
      
      menu.merge(menu2)
      
      menu.should == build("Plugins") do
        sub_menu "REPL" do
        end
        sub_menu "Encryption" do
        end
        sub_menu "My Plugin" do
          item "Open", 101
        end
      end

    end
    
    it "uses the priority of whichever menu has one" do
      menu  = build("Main"){ sub_menu("Project"){} }
      menu2 = build("Main"){ sub_menu("Project", :priority => 10){} }
      menu.merge(menu2)
      menu.entries.first.priority.should == 10

      menu  = build("Main"){ sub_menu("Project", :priority => 10){} }
      menu2 = build("Main"){ sub_menu("Project"){} }
      menu.merge(menu2)
      menu.entries.first.priority.should == 10
    end
    
    it "preserves own priority when merging" do
      menu  = build("Main"){ sub_menu("Project", :priority => 10){} }
      menu2 = build("Main"){ sub_menu("Project", :priority => 5){} }
      menu.merge(menu2)
      menu.entries.first.priority.should == 10      
    end
  end
end




