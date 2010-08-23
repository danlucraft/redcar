require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

require 'net/ssh'
require 'net/sftp'

class Redcar::Project
  describe Adapters::RemoteProtocols::SFTP do
    let(:conn) { double('connection').as_null_object }
    subject do
      Adapters::RemoteProtocols::SFTP.new('server', 'user', 'secret', [])
    end
    
    before(:each) do
      Net::SSH.stub!(:start).with('server', 'user', hash_including(:password => 'secret')).and_return(conn)
    end
    
    context "Public methods" do
      describe '#directory?' do
        it "fetches the folder if it's not the base folder" do
          subject.stub!(:fetch).with("/home/fcoury").and_return([
            { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => :file },
            { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => :dir }
          ])
          subject.directory?("/home/fcoury/hello_world.rb").should be_false
          subject.directory?("/home/fcoury/snippets").should be_true
        end
      end
    
      describe '#file?' do
        it "fetches the folder for the file" do
          subject.stub!(:fetch).with("/home/fcoury").and_return([
            { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => :file },
            { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => :dir }
          ])
          subject.file?("/home/fcoury/hello_world.rb").should be_true
          subject.file?("/home/fcoury/snippets").should be_false
        end
      end
    
      
      describe '#load' do
        let(:conn) { double('connection').as_null_object }
        let(:sftp) { double('sftp connection').as_null_object }
        
        subject do
          Adapters::RemoteProtocols::SFTP.new('server', 'user', 'secret', []).tap do |protocol|
            conn.stub!(:sftp).and_return(sftp)
            protocol.stub!(:connection).and_return(conn)
          end
        end
        
        before(:each) do
          File.stub!(:open)
          FileUtils.stub!(:mkdir_p)
        end
        
        it "creates the folder /tmp/hostname/file_path" do
          FileUtils.should_receive(:mkdir_p).with('/tmp/server/home/fcoury')
          subject.load('/home/fcoury/file.txt')
        end
        
        it "downloads the file to the local folder using SFTP" do
          sftp.should_receive(:download!).with('/home/fcoury/file.txt', '/tmp/server/home/fcoury/file.txt')
          subject.load('/home/fcoury/file.txt')
        end
        
        it "returns the downloaded file contents" do
          file = double('File')
          File.should_receive(:open).with('/tmp/server/home/fcoury/file.txt', 'rb').and_yield(file)
          file.should_receive(:read).and_return "contents"
          subject.load('/home/fcoury/file.txt').should == "contents"
        end
      end
      
      describe '#save' do
        let(:conn) { double('connection').as_null_object }
        let(:sftp) { double('sftp connection').as_null_object }
        
        subject do
          Adapters::RemoteProtocols::SFTP.new('server', 'user', 'secret', []).tap do |protocol|
            conn.stub!(:sftp).and_return(sftp)
            protocol.stub!(:connection).and_return(conn)
          end
        end
        
        before(:each) do
          File.stub!(:open)
          FileUtils.stub!(:mkdir_p)
        end
        
        it "write file contents" do
          file = double('File')
          File.should_receive(:open).with('/tmp/server/home/fcoury/file.txt', 'wb').and_yield(file)
          file.should_receive(:print).with("contents")
          
          subject.save('/home/fcoury/file.txt', 'contents')
        end

        it "uploads the local file to the remote path" do
          sftp.should_receive(:upload!).with('/tmp/server/home/fcoury/file.txt', '/home/fcoury/file.txt')
          subject.save('/home/fcoury/file.txt', 'contents')
        end

        it "returns the saved file" do
          file = double('File').as_null_object
          File.should_receive(:open).with('/tmp/server/home/fcoury/file.txt', 'wb').and_yield(file)
          subject.save('/home/fcoury/file.txt', 'contents').should == file
        end
      end
    end
    
    context "Private methods" do
      describe '#connection' do
        it "delegates the connection to Remote.connect" do
          Net::SSH.should_receive(:start).with('server', 'user', hash_including(:password => 'secret'))
          subject.send(:connection)
        end
      end
    end
  end
end