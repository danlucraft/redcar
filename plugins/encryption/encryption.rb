

module Encryption
  def self.encrypt(text, password)
    EncryptionTools.encrypt_and_armour(text, password)
  end
  
  def self.decrypt(text, password)
    EncryptionTools.dearmour_and_decrypt(text, password)
  end
  
  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Plugins" do
        sub_menu "Encryption" do
          item "Encrypt Document", EncryptDocumentCommand
          item "Decrypt Document", DecryptDocumentCommand
        end
      end
    end
  end

  def self.lazy_load
    require File.dirname(__FILE__) + "/jarmor-1.1"
    require File.dirname(__FILE__) + "/ezcrypto"
  end

  class DecryptDocumentCommand < Redcar::EditTabCommand
    def execute
      Encryption.lazy_load
      result = Redcar::Application::Dialog.input("Password", "Enter password")
      pw = result[:value]
      begin
        doc.text = Encryption.decrypt(doc.to_s, pw)
      rescue => e
        Redcar::Application::Dialog.message_box("Couldn't decrypt!", :type => :error)
      end
    end
  end
  
  class EncryptDocumentCommand < Redcar::EditTabCommand
    def execute
      Encryption.lazy_load
      result = Redcar::Application::Dialog.input("Password", "Enter password")
      pw = result[:value]
      doc.text = Encryption.encrypt(doc.to_s, pw)
    end
  end
end

