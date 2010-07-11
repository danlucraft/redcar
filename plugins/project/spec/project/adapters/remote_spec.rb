require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class Redcar::Project
  describe Adapters::Remote do
    subject do
      Adapters::Remote.new('myserver.com', 'user', 'secret')
    end
    
    its(:host)     { should == 'myserver.com' }
    its(:user)     { should == 'user' }
    its(:password) { should == 'secret' }
    
    describe "Class methods" do
      subject { Adapters::Remote }
      
      describe '#init_connection' do
        it "starts a new SSH connection" do
          Net::SSH.should_receive(:start).with('myserver.com', 'user', hash_including(:password => 'secret'))
          subject.init_connection('myserver.com', 'user', 'secret')
        end
      end
      
      describe "#connect" do
        context "when first invoked for same host+user" do
          it "invokes init_connection" do
            subject.should_receive(:init_connection).with('a', 'b', 'c')
            subject.connect('a', 'b', 'c')
          end
        end
        
        context "when connection was already stabilished" do
          it "reuses the connection" do
            connection = double('connection')
            subject.stub!(:connections).and_return({"a-b" => connection})
            
            subject.should_receive(:init_connection).never
            subject.connect('a', 'b', 'c')
          end
        end
      end
    end
    
    describe '#connection' do
      it "delegates the connection to Remote.connect" do
        Adapters::Remote.should_receive(:connect).with('myserver.com', 'user', 'secret')
        subject.connection
      end
    end
    
    describe '#dir_listing' do
      it "retrieves all files and dirs on a given remote folder" do
        conn = stub('connection')
        subject.stub!(:connection).and_return(conn)
        conn.should_receive(:exec!).with(%Q(
            test -d "/home/fcoury" && echo y
          )).and_return("y\n")
        conn.should_receive(:exec!).with(%Q(
            for file in /home/fcoury/*; do 
              test -f "$file" && echo "file|$file"
              test -d "$file" && echo "dir|$file"
            done
          ))
        subject.dir_listing('/home/fcoury')
      end
      
      it "raises an exception when the folder doesn't exist" do
        conn = stub('connection')
        subject.stub!(:connection).and_return(conn)
        conn.should_receive(:exec!).with(%Q(
            test -d "/home/fcoury" && echo y
          )).and_return("n\n")
        lambda { subject.dir_listing('/home/fcoury') }.should raise_error(Adapters::Remote::PathDoesNotExist)
      end
    end
    
    describe "#retrieve_dir_contents" do
      it "returns dir contents in a hash with file names and types" do
        subject.should_receive(:dir_listing).with('/home/fcoury').and_return([
          'file|/home/fcoury/.bashrc',
          'dir|/home/fcoury/.vimrc',
          'file|/home/fcoury/hello_world.rb',
          'dir|/home/fcoury/snippets'
        ])

        result = subject.retrieve_dir_contents('/home/fcoury')
        result[0][:fullname].should == '/home/fcoury/.bashrc'
        result[0][:name].should == '.bashrc'
        result[0][:type].should == 'file'
        
        result[1][:fullname].should == '/home/fcoury/.vimrc'
        result[1][:name].should == '.vimrc'
        result[1][:type].should == 'dir'

        result[2][:fullname].should == '/home/fcoury/hello_world.rb'
        result[2][:name].should == 'hello_world.rb'
        result[2][:type].should == 'file'

        result[3][:fullname].should == '/home/fcoury/snippets'
        result[3][:name].should == 'snippets'
        result[3][:type].should == 'dir'
      end
    end
    
    describe '#fetch_contents' do
      it "return the name for all files retrieved" do
        subject.stub!(:fetch).with("/home/fcoury").and_return([
          { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => 'file' },
          { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => 'dir' }
        ])
        subject.fetch_contents("/home/fcoury").should == ['/home/fcoury/hello_world.rb', '/home/fcoury/snippets']
      end
    end
    
    describe '#file?' do
      it "fetches the folder for the file" do
        subject.stub!(:fetch).with("/home/fcoury").and_return([
          { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => 'file' },
          { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => 'dir' }
        ])
        subject.file?("/home/fcoury/hello_world.rb").should be_true
        subject.file?("/home/fcoury/snippets").should be_false
      end
    end
    
    describe '#check_folder' do
      it "returns true if it's a folder" do
        conn = stub('connection')
        subject.stub!(:connection).and_return(conn)
        conn.should_receive(:exec!).with(%Q(
            test -d "/home/fcoury" && echo y
          )).and_return("y\n")
        subject.check_folder('/home/fcoury').should be_true
      end
    end
    
    describe '#directory?' do
      it "fetches the folder if it's not the base folder" do
        subject.stub!(:fetch).with("/home/fcoury").and_return([
          { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => 'file' },
          { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => 'dir' }
        ])
        subject.directory?("/home/fcoury/hello_world.rb").should be_false
        subject.directory?("/home/fcoury/snippets").should be_true
      end

      it "checks for directory flag on the file if it's the base folder" do
        subject.path = '/home/fcoury'
        subject.stub!(:check_folder).with('/home/fcoury').and_return(true)
        subject.directory?("/home/fcoury").should be_true
      end
    end
    
    describe '#exist?' do
      it "returns true if fetch throws exception (path does not exist)" do
        subject.path = '/home/fcoury'
        subject.should_receive(:fetch).with("/home/fcoury").and_raise(Adapters::Remote::PathDoesNotExist)
        subject.exist?.should be_false
      end
      
      it "returns true if fetch runs" do
        subject.path = '/home/fcoury'
        subject.should_receive(:fetch).with("/home/fcoury").and_return([
          'file|.bashrc',
          'dir|.vimrc',
          'file|hello_world.rb',
          'dir|snippets'
        ])
        subject.exist?.should be_true
      end
    end
  end
end