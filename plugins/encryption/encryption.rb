
require 'openssl'
require File.dirname(__FILE__) + "/jarmor-1.1"
require File.dirname(__FILE__) + "/ezcrypto"

module Encryption
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
  
  class DecryptDocumentCommand < Redcar::EditTabCommand
    def execute
      result = Redcar::Application::Dialog.input(win, "Password", "Enter password")
      pw = result[:value]
      encrypted = dearmour(doc.to_s)
      begin
        decrypted = decrypt(encrypted, pw)
        doc.text = decrypted
      rescue => e
        Redcar::Application::Dialog.message_box(win, "Couldn't decrypt!", :type => :error)
      end
    end
    
    def dearmour(data)
      stream = java.io.ByteArrayInputStream.new(java.lang.String.new(data).getBytes)
      armour = org.spaceroots.jarmor.Base64Decoder.new(stream)
      encrypted = ""
      while (byte = armour.read) != -1
        encrypted << byte
      end
      armour.close
      encrypted
    end
    
    def decrypt(data, pw)
      key = EzCrypto::Key.with_password pw, "system salt"
      key.decrypt(data)
    end
  end
  
  class EncryptDocumentCommand < Redcar::EditTabCommand
    def encrypt(data, pw)
      key = EzCrypto::Key.with_password pw, "system salt"
      key.encrypt(data)
    end
    
    def armour(data)
      stream = java.io.ByteArrayOutputStream.new
      armour = org.spaceroots.jarmor.Base64Encoder.new(stream)
      data.each_byte {|byte| armour.write(byte) }
      armour.close
      stream.toString
    end
    
    def execute
      result = Redcar::Application::Dialog.input(win, "Password", "Enter password")
      pw = result[:value]
      encrypted = encrypt(doc.to_s, pw)
      armoured = armour(encrypted)
      doc.text = armoured
    end
  end
end
