! Copyright (C) 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors furnace.actions math.parser
http.server.responses mason.server ;
IN: webapps.mason.increment-counter

: <increment-counter-action> ( -- action )
    <action>
    [
        [
            increment-counter-value
            number>string "text/plain" <content>
        ] with-mason-db
    ] >>submit ;
