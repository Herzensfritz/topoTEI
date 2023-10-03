xquery version "3.1";

(: The following external variables are set by the repo:deploy function :)

(: the target collection into which the app is deployed :)
declare variable $target external;

if (xmldb:collection-available(concat($target, 'data'))) then () 
else (
    let $data := xmldb:create-collection($target, "data")
    let $col := xs:anyURI($data)
    return (
        sm:chown($col, "test"),
        sm:chgrp($col, "test-group"),
        sm:chmod($col, "rw-rw-r--")
    )
)

