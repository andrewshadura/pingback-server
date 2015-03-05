# Based on XMLRPC package from TclSOAP

# XMLRPC.tcl - Copyright (C) 2001 Pat Thoyts <patthoyts@users.sourceforge.net>
#              Copyright (C) 2008 Andreas Kupries <andreask@activestate.com>

package require tdom

namespace eval ::XMLRPC {
}

# Description:
#   Prepare an XML-RPC fault response
# Parameters:
#   faultcode   the XML-RPC fault code (numeric)
#   faultstring summary of the fault
#   detail      list of {detailName detailInfo}
# Result:
#   Returns the XML text of the generated fault response
#
proc ::XMLRPC::fault {faultcode faultstring {detail {}}} {
    set xml [join [list \
        "<?xml version=\"1.0\" ?>" \
        "<methodResponse>" \
        "  <fault>" \
        "    <value>" \
        "      <struct>" \
        "        <member>" \
        "           <name>faultCode</name>"\
        "           <value><int>${faultcode}</int></value>" \
        "        </member>" \
        "        <member>" \
        "           <name>faultString</name>"\
        "           <value><string>${faultstring}</string></value>" \
        "        </member>" \
        "      </struct> "\
        "    </value>" \
        "  </fault>" \
        "</methodResponse>"] "\n"]
    return $xml
}

# -------------------------------------------------------------------------

# Description:
#   Generate a reply packet for a simple reply containing one result element
# Parameters:
#   result      the reply data
# Result:
#   Returns the XML text of the generated reply packet
#
proc ::XMLRPC::reply {result} {
    set xml [join [list \
        "<?xml version=\"1.0\" ?>" \
        "<methodResponse>" \
        "  <params>" \
        "    <param>" \
        "        <value><string>${result}</string></value>" \
        "    </param>" \
        "  </params>" \
        "</methodResponse>"] "\n"]

    return $xml
}

proc ::XMLRPC::parsequery {xml} {
    set doc [dom parse $xml]
    set method [[$doc selectNodes /methodCall/methodName] asText]
    set params [lmap param [$doc selectNodes {/methodCall/params/param/value/string}] {
        $param asText
    }]
    $doc delete
    return [list $method $params]
}

package provide xmlrpc 0.0
