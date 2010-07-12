require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class Redcar::Project
  # describe Adapters::Remote do
  #   context "with FTP provider" do
  #     subject do
  #       Adapters::Remote.new(:ftp, 'ftpserver.com', 'ftpuser', 'ftpsecret')
  #     end
  # 
  #     its(:provider) { should == :ftp }
  #     its(:host)     { should == 'ftpserver.com' }
  #     its(:user)     { should == 'ftpuser' }
  #     its(:password) { should == 'ftpsecret' }
  # 
  #     describe "Class methods" do
  #       subject { Adapters::Remote }
  #     
  #       describe '#init_connection' do
  #         it "starts a new FTP connection" do
  #           Net::FTP.should_receive(:open).with('ftpserver.com', 'ftpuser', 'ftpsecret')
  #           subject.init_connection(:ftp, 'ftpserver.com', 'ftpuser', 'ftpsecret')
  #         end
  #       end
  #     end
  #   end
  #   
  #   context "with SFTP provider" do
  #     subject do
  #       Adapters::Remote.new(:sftp, 'myserver.com', 'user', 'secret')
  #     end
  # 
  #     its(:provider) { should == :sftp }
  #     its(:host)     { should == 'myserver.com' }
  #     its(:user)     { should == 'user' }
  #     its(:password) { should == 'secret' }
  # 
  #     describe "Class methods" do
  #       subject { Adapters::Remote }
  # 
  #       describe '#init_connection' do
  #         it "starts a new SSH connection" do
  #           Net::SSH.should_receive(:start).with('myserver.com', 'user', hash_including(:password => 'secret'))
  #           subject.init_connection(:sftp, 'myserver.com', 'user', 'secret')
  #         end
  #       end
  # 
  #       describe "#connect" do
  #         context "when first invoked for same host+user" do
  #           it "invokes init_connection" do
  #             subject.should_receive(:init_connection).with(:sftp, 'a', 'b', 'c')
  #             subject.connect(:sftp, 'a', 'b', 'c')
  #           end
  #         end
  # 
  #         context "when connection was already stabilished" do
  #           it "reuses the connection" do
  #             connection = double('connection')
  #             subject.stub!(:connections).and_return({"ftp-a-b" => connection})
  # 
  #             subject.should_receive(:init_connection).never
  #             subject.connect(:sftp, 'a', 'b', 'c')
  #           end
  #         end
  #       end
  #     end
  # 
  #     describe '#dir_listing' do
  #       it "retrieves all files and dirs on a given remote folder" do
  #         subject.should_receive(:check_folder).with('/home/fcoury').and_return(true)
  #         subject.should_receive(:exec).with(%Q(
  #           for file in /home/fcoury/*; do 
  #             test -f "$file" && echo "file|$file"
  #             test -d "$file" && echo "dir|$file"
  #           done
  #         ))
  #         subject.dir_listing('/home/fcoury')
  #       end
  # 
  #       it "raises an exception when the folder doesn't exist" do
  #         subject.should_receive(:check_folder).and_return(false)
  #         lambda { subject.dir_listing('/home/fcoury') }.should raise_error(Adapters::Remote::PathDoesNotExist)
  #       end
  #     end
  # 
  #     describe "#retrieve_dir_contents" do
  #       it "returns dir contents in a hash with file names and types" do
  #         subject.should_receive(:dir_listing).with('/home/fcoury').and_return([
  #           'file|/home/fcoury/.bashrc',
  #           'dir|/home/fcoury/.vimrc',
  #           'file|/home/fcoury/hello_world.rb',
  #           'dir|/home/fcoury/snippets'
  #         ])
  # 
  #         result = subject.retrieve_dir_contents('/home/fcoury')
  #         result[0][:fullname].should == '/home/fcoury/.bashrc'
  #         result[0][:name].should == '.bashrc'
  #         result[0][:type].should == 'file'
  # 
  #         result[1][:fullname].should == '/home/fcoury/.vimrc'
  #         result[1][:name].should == '.vimrc'
  #         result[1][:type].should == 'dir'
  # 
  #         result[2][:fullname].should == '/home/fcoury/hello_world.rb'
  #         result[2][:name].should == 'hello_world.rb'
  #         result[2][:type].should == 'file'
  # 
  #         result[3][:fullname].should == '/home/fcoury/snippets'
  #         result[3][:name].should == 'snippets'
  #         result[3][:type].should == 'dir'
  #       end
  #     end
  # 
  #     describe '#check_folder' do
  #       it "tries to retrieve the parent folder from cache" do
  #         subject.should_receive(:cache).with('/home/fcoury').and_return([
  #           { :fullname => '/home/fcoury/hello_world.rb', :name => 'hello_world.rb', :type => 'file' },
  #           { :fullname => '/home/fcoury/snippets',       :name => 'snippets',       :type => 'dir' }
  #         ])
  #         subject.should_receive(:exec).never
  #         subject.check_folder('/home/fcoury/snippets').should be_true
  #       end
  # 
  #       it "when parent folder isn't cached, retrieves from SSH" do
  #         conn = stub('connection')
  #         subject.stub!(:connection).and_return(conn)
  # 
  #         subject.should_receive(:cache).with('/home').and_return(nil)
  #         conn.should_receive(:exec!).with(%Q(
  #             test -d "/home/fcoury" && echo y
  #           )).and_return("y\n")
  #         subject.check_folder('/home/fcoury').should be_true
  #       end
  #     end
  #   end
  # end
end