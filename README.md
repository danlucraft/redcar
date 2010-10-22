Web Bookmarks
-------------

A Webpage Viewer for the Redcar Text Editor

![Screenshot](http://github.com/kattrali/redcar-web-bookmarks/raw/master/Screenshot.png "Example usage")

Installation
============

    cd ~/.redcar/plugins
    git clone git://github.com/kattrali/redcar-web-bookmarks.git web_bookmarks

Usage
=====

 * Preview Markup files (HTML,etc) from the "Web Preview" option in the File menu
 * View saved web and project links from the bookmarks menu
 * Add bookmarks to a 'web_bookmarks.json' file in either the project .redcar directory or ~/.redcar (or both) in the following format:

<code>
    {
        "bookmarks" : [
            {
                "name" : "JUnit Test Results",
                "protocol" : "file",
                "url"  : "__PROJECT_PATH__/target/test-reports/html/index.html"
            },
            {
                "name" : "Groovy JDK",
                "protocol" : "file",
                "url"  : "/APIs/groovy/docs/api/index.html",
                "group" : "API"
            },
            {
                "name" : "Java 6 API",
                "protocol" : "http",
                "url"  : "www.javac.com/api/",
                "group" : "API"
            }
    }
</code>
  
 * Links can be relative to the project directory using \_\_PROJECT\_PATH__ variable in URLs
 * Bookmarks without groups will be displayed at the top of the list.
 * Select Project > Web Bookmarks from the main menu or the globe icon in the toolbar
 * Go!

Using the Browser Navigation Bar
================================

 * Bookmarks can be added by pressing the '+' button
 * The browser bar can be disabled by default in Plugins > Edit Preferences > web_bookmarks
 * To reopen a closed browser bar, open Edit > Document Navigation > Open Browser Bar
 * Browser bar works on __any__ HtmlTab, not just bookmarks
