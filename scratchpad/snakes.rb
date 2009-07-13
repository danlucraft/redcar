#!/usr/bin/env ruby -w
# (Thanks to) Sample code from Programing Ruby, page 643
# Modified by rahul http://www.benegal.org/files
# 2008-09-10 18:24 
# $Id: snakes.rb,v 0.4 2008/09/12 12:48:08 arunachala Exp arunachala $
# move in 4 directions. and eat the apples on the board.

require 'curses'
include Curses
require 'time'

class Sprites
  X = [10,14,16,18,11,15,17,19]
  Y = [10,20,30,40,50,60,70,75]
  SPRITES = %w[^ ^ @ $ @ + @ $] 
  DEAD=0
  REMARKSLINE=28
  
  def initialize (howmany)
    @sprites = []
    @start = Time.now.to_i
    @count = howmany
    howmany.times{|i| @sprites << [X[i], Y[i]]}
    drawsprites
  end

  def drawsprites
    (0..@count-1).each {|i| sp = @sprites[i]; 
    schar=SPRITES[i]

    # after 20 seconds he comes deadly
    if elapsed() > 20
      if SPRITES[i]=="+"
        SPRITES[i]="X"
        schar=SPRITES[i]
        setpos(REMARKSLINE,0); addstr("X is deadly...................")
      end
    elsif elapsed() > 15
      if SPRITES[i]=="+"
      schar="\\-/| "[rand(5)].chr
      setpos(REMARKSLINE,0); addstr("Eat + quickly ................")
      end
    end
    #if SPRITES[i]=="$"
    #  if elapsed()+2 % 4 == 0 
    #    sp[0]+=1 if sp[0] < 25
    #  end
    #end
    #case SPRITES[i]
    #when 'X' : SPRITES[i]='+'
    #when '+' : SPRITES[i]='X'
    #end
    setpos(sp[0], sp[1])
    #addstr(SPRITES[i])
    addstr(schar)
    }
  end
  def get_sprite_value(offset)
    case SPRITES[offset]
    when '^' : -1
    when '@' : 1
    when '$' : 1
    when 'X' : -4
    when '+' : 2
    when 'z' : -10    # dead (for the moment)
    else
      0
    end
  end
  def get_sprites
    @sprites
  end
  def delete_at(offset)
    # can't delete during an iteration of sprites
    #@sprites.delete_at(offset)
    #SPRITES.delete_at(offset)
    @sprites[offset] = [DEAD,offset]
    SPRITES[offset]="z"
  end
  def elapsed
    Time.now.to_i - @start
  end
  def is_dead(offset)
    @sprites[offset][0]==DEAD
    #X[offset]==DEAD
  end
end
class PlayerXY
  HEIGHT = 4
  PCHAR = "#"
  TIMELINE=26
  STATUSLINE=27
  POSLIVES=65
  SPACE=" "
  def initialize
    @lives=2
    # reduce or increase the chap with lives or food etc
    @lenp=4
    @data = Array.new
    ptop = (Curses::lines - HEIGHT)/2
    pleft = 5
    @lenp.times{ |i| @data.push([ptop, pleft+i]) }
    @tail=@data.first
    drawme
  end   
  def update_lives(incval)
    @lives += incval
    update_len(incval)
  end
  def lives
    @lives 
  end
  def movelt
    x=@data.last 
    update(0,-1) if x[1]-1 > 1
  end
  def movert
    x=@data.last 
    update(0,1) if x[1]+1 < 80
  end
  def moveup
    x=@data.last
    update(-1,0) if x[0] > 1
  end
  def movedn
    x=@data.last 
    update(1,0) if (x[0]+HEIGHT+3 <= Curses::lines)
    #setpos(28,0); addstr((x[0]+HEIGHT+2).to_s + ":" + Curses::lines.to_s)
  end

  # take off head so i can update and push back
  def update(inctop, incleft)
    x=@data.last.dup
    # FIX -- don't allow movement and shift if he's hitting border that can only be done in move methods
    @tail=@data.shift
    x0 = x[0]
    x1 = x[1]
    x[0]+=inctop
    x[1]+=incleft 
    @data.push(x)
    drawme
    refresh
  end
  # update length of player
  def update_len(howmuch) 
    if howmuch < 0
      tail = @data.shift
      setpos(tail[0], tail[1])
      addstr(SPACE)
    elsif howmuch > 0
      x=@data.first.dup
      @data.insert(0,x)
    end
    @lenp += howmuch; # not doing anything really
  end
  def drawme
    setpos(TIMELINE, POSLIVES); addstr("Lives: " + @lives.to_s)
    positions=@data
    # wipe out tail
    tail= getTail
    setpos(tail[0], tail[1])
    addstr(SPACE)
    positions.each{ | posxy | setpos(posxy[0], posxy[1]); addstr(PCHAR); }
  end
  # for drawing
  def getPlayer
    @data
  end
  # for clearing off
  def getTail
    @tail
  end
  # currently check collision with head only
  def get_head
    @data.last
  end
end

class Paddle
  HEIGHT = 4
  PCHAR = "#"
  PADDLE = "#"*HEIGHT
  TIMELINE=26
  STATUSLINE=27
  WONLOSTLINE=12
  REMARKSLINE=28
  POSLIVES=55
  
  def initialize
    @top = (Curses::lines - HEIGHT)/2
    @gameover = false
    @left = 0
    @hitctr=0
    @howmany = 6
    @start = Time.now.to_i
    @sprite_ar = Sprites.new(@howmany)
    @player = PlayerXY.new
    paddle_draw
  end
  def up
    @player.moveup
  end
  def right
    @player.movert
  end
  def left
    @player.movelt
  end
  def down
    @player.movedn
  end
  def paddle_draw
    if gameover?
      return
    end
    @sprite_ar.drawsprites
    setcursor
    if check_collision?
      if @howmany <= @hitctr
        setpos(REMARKSLINE,36); addstr("YOU HAVE WON! Press q/Q to exit.")
        setpos(WONLOSTLINE,36); addstr("YOU HAVE WON! Press q/Q to exit.")
        @gameover = true
      end
      if @player.lives <= 0
        setpos(REMARKSLINE,36); addstr("YOU HAVE LOST ! Press q/Q to exit.")
        setpos(WONLOSTLINE,36); addstr("YOU HAVE LOST ! Press q/Q to exit.")
        @gameover = true
      end
    end
    refresh
  end
  def check_collision?
    sprites = @sprite_ar.get_sprites
    head = @player.get_head
    ctr = 0
    sprites.each{ |sp| 
      if @sprite_ar.is_dead(ctr)
        ctr+=1
        next
      end
      if (sp==head) then 
        value = @sprite_ar.get_sprite_value(ctr)
        case value
        when -1: 
          setpos(REMARKSLINE,0); addstr("O U C H! Eat apple to get well")
          setpos(STATUSLINE,0); addstr("^ takes a life, @ adds life.  ")
        when 1:
          setpos(REMARKSLINE,0); addstr("B U R P! That was good!       ")
          setpos(STATUSLINE,0); addstr("^ -1, @ +1, + +2, X -4        ")
        when 2:
          setpos(REMARKSLINE,0); addstr("Yummy ! That was great!       ")
        end
        @sprite_ar.delete_at(ctr)
        @player.update_lives(value);
        Curses::beep; 
        @hitctr += 1;
        setpos(TIMELINE,POSLIVES); #addstr("Eaten: " + @hitctr.to_s + " apples!")
        addstr("Lives: " + @player.lives.to_s)
        return true
      else
        false
      end 
      ctr += 1
    }
  end
  # getch blocks so now point. there should be some wy for getch to not block - a NOWAIT
  def puttime
    if gameover?
      return
    end
    setpos(TIMELINE,0)
    addstr( (Time.now.to_i - @start).to_s + " sec")
  end
  def self.paddle_time
    Time.now.to_i - @start
  end
  def setcursor
    head = @player.get_head
    setpos(head[0],head[1])
  end
  def gameover?
    @gameover 
  end
end # class Paddle

init_screen
begin
  crmode
  noecho
  stdscr.keypad(true)
  screen = stdscr.subwin(27, 81, 0, 0)
  screen.box(0,0)
  setpos(0,30); addstr("Snakes with Ruby/Curses");

  
  paddle = Paddle.new

  Curses.timeout=0
  loop do
      case getch
      when ?Q, ?q    :  break
      when Key::UP   :  paddle.up 
      when Key::DOWN :  paddle.down 
      when Key::RIGHT :  paddle.right
      when Key::LEFT :  paddle.left 
      else 
        #beep
      end
    paddle.puttime
    paddle.paddle_draw
  end
ensure
  close_screen
end
