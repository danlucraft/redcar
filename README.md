Web Bookmarks
-------------

A Webpage Viewer for the Redcar Text Editor

Usage
=====

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
                "url"  : "/APIs/groovy/docs/api/index.html"
            },
            {
                "name" : "Java 6 API",
                "protocol" : "http",
                "url"  : "www.javac.com/api/"
            }
    }
</code>

 * Select Project > Web Bookmarks from the main menu or the globe icon in the toolbar
 * Go!