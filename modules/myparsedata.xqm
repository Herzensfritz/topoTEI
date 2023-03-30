xquery version "3.0";

module namespace myparsedata="http://exist-db.org/apps/myapp/myparsedata";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace console="http://exist-db.org/xquery/console";

declare function myparsedata:parseHeader($data as xs:string, $type as xs:string) as map(*) {
    let $boundary := substring-after($type, "boundary=")
    let $head := replace(substring-before(substring-after($data, $boundary), "Content-Type:"),  '(\r?\n|\r)', '')
    let $content-type := concat("content-type: ", replace(tokenize(substring-after($data, "Content-Type:"), '\n')[1], '(\s+)', ''))
    let $full-header := concat($head, ";", $content-type, ";", "startBoundary: ", $boundary, ";", "endBoundary: ", concat("--", $boundary) )
    let $header := map:merge(
    for $item in tokenize($full-header, ";")
       return  if (contains($item, '="')) then (
            let $keyValue := tokenize($item, "=")
            let $out := map { replace($keyValue[1], '(^\s)', '') : replace($keyValue[2], '"', '') }
            return $out
            ) else (
            let $keyValue := tokenize($item, ": ")    
            let $out := map { $keyValue[1] : replace($keyValue[2], '"', '') }
            return $out
            )
    )
    return $header
};

declare function myparsedata:parseContent($data as xs:string, $header as map(*)) as xs:string {
    let $startBoundary := $header("startBoundary")
    let $endBoundary := $header("endBoundary")
    let $content := substring-before(substring-after($data, $startBoundary), $endBoundary)
    let $xmlContent := replace(substring-after($content, $header('content-type')), '(^\s+)', '')
    return $xmlContent
};

declare function myparsedata:parseXMLData($data as xs:string, $type as xs:string, $targetType as xs:string) as map(*)* {
    let $header := myparsedata:parseHeader($data, $type)
    return if ($header("content-type") = $targetType) then (
        let $content := myparsedata:parseContent($data, $header)
        return map:merge(($header, map { $targetType : $content, 'status': '200' }))
    ) else (
        map:merge(($header, map { 'status': '422'}))
    )
};