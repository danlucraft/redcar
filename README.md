{Redcar}
========

[http://redcareditor.com/](http://redcareditor.com/)

## Description

A Ruby text editor.

 * written in Ruby from the ground up
 * runs on JRuby (a fast, compatible Ruby implementation)
 * is cross-platform (Linux, Mac OS X, Windows)
 * highly extensible

Some Redcar features:

 * supports Textmate themes and snippets
 * split screen mode
 * syntax checking for many languages
 * built in REPL for Ruby, plugins for Groovy, Clojure and Mirah.

Some (current) limitations:

 * Only supports UTF-8 file encodings (and therefore ASCII)

![alt text](http://redcareditor.com/images/redcar-4-thumb.png "Title")
![alt text](http://redcareditor.com/images/redcar-1-thumb.png "Title")

## Installation

    $ gem install redcar

for more details, see [User Guide: Installation](https://github.com/redcar/redcar/wiki/Installation)

* Note: On OS X, you must have Xcode and Xcode Command Line Tools (available view `Xcode > Preferences > Downloads`) installed.

## Usage

Run 

    $ redcar --help

To see full usage details.

## Experimental Installers

You must have Java installed. On Ubuntu, you can install `openjdk-7-jre` if you do not already have Java.


 * [OS X](https://github.com/downloads/redcar/redcar/Redcar-0.14.0dev.app.zip)

    unzip, then double click Redcar.app
    
 * [Debian](https://github.com/downloads/redcar/redcar/redcar_0.14.0dev_all.deb)

    install with sudo dpkg -i redcar_xx_all.deb
    
 * [Windows](https://github.com/downloads/redcar/redcar/redcar-0.14.0dev.zip)

    unzip, then run redcar.exe

## Installing From Source

    git clone git://github.com/redcar/redcar.git
    cd redcar
    rake init
    ruby bin/redcar

## Problems?

* Irc at #redcar on irc.freenode.net
* Mailing list at http://groups.google.com/group/redcar-editor

## License

Redcar is copyright 2007-2012 Daniel Lucraft and contributors.
It is licensed under the GPLv2. See the included LICENSE file for details.
