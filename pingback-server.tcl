#!/usr/bin/tclsh8.6
# change the above line to point to the tclsh8.6 executable

lappend auto_path .
package require wibble
package require xmlrpc

package require sqlite3

source [string map {tcl conf} $argv0]

lassign [time {
    sqlite3 ::db $dbpath
    puts "Initialising..."
    ::db eval {begin; create table if not exists pingbacks (source string, target string); commit;}
}] time
puts "Database initialised in [expr {$time/1000}] ms"

set ::totalrecords [::db eval {select count() from pingbacks;}]

proc ::dump {a} {
    puts $a
    set a
}

proc /pingback {state} {
    set method [dict get $state request method]
    if {$method ne "POST"} {
        dict set response status 405
        dict set response header content-type text/html\;\ charset=UTF-8
        dict set response content "<h1>Invalid method</h1><p>Use XMLRPC HTTP POST, not GET</p>"
    } else {
        if {[catch {
            dict set response status 200
            dict set response header content-type text/xml\;\ charset=UTF-8
            set rawpost [dict get $state request rawpost]
            lassign [::XMLRPC::parsequery $rawpost] method params
            lassign $params source target
            ::db eval {insert into pingbacks values(:source, :target);}
            dict set response content [::XMLRPC::reply Okay]
        }]} {
            dict set response content [::XMLRPC::fault 0 "General error"]
        }
    }
    ::wibble::sendresponse $response
}

proc /pingbacks {state} {
    set method [dict get $state request method]
    if {$method ne "GET"} {
        dict set response status 405
        dict set response header content-type text/html\;\ charset=UTF-8
        dict set response content "<h1>Invalid method</h1><p>Use HTTP GET</p>"
    } else {
        dict set response status 200
        dict set response header content-type text/html\;\ charset=UTF-8
        set result [::db eval {select * from pingbacks;}]
        dict set response content <ul>[join [lmap {source target} $result {set s "<li><a href=\"$source\">$source</a> links to <a href=\"$target\">$target</a></li>"}]]</ul>
    }
    ::wibble::sendresponse $response
}

# Demonstrate Wibble if being run directly.
if {$argv0 eq [info script]} {
    # Guess the root directory.
    set root [file normalize [file dirname [info script]]]/static

    # Define zone handlers.
    ::wibble::handle /vars vars
    ::wibble::handle /pingback /pingback
    ::wibble::handle /pingbacks /pingbacks
    ::wibble::handle / dirslash root $root
    # ::wibble::handle / indexfile root $root indexfile index.html
    # ::wibble::handle / static root $root
    # ::wibble::handle / template root $root
    # ::wibble::handle / script root $root
    # ::wibble::handle / dirlist root $root
    ::wibble::handle / notfound

    # Start a server and enter the event loop if not already there.
    catch {
        ::wibble::listen 9090
        if {!$tcl_interactive} {
			vwait forever
		}
    }
}
