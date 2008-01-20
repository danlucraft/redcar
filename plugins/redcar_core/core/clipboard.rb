
CLIPBOARD_MAX = 100

class Clipboard
  include Enumerable
  def self.<<(text)
    Redcar.event :clipboard_added do
      @@clips ||= []
      @@clips << text
      if @@clips.length > CLIPBOARD_MAX
        @@clips = @@clips[1..(@@clips.length-1)]
      end
    end
  end
  def self.top
    @@clips.last
  end
  def self.each
    @@clips.each do |el|
      yield el
    end
  end
  def self.to_a
    (@@clips||=[]).reverse
  end
end
