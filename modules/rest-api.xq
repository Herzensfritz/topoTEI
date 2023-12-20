xquery version "3.1";

module namespace myrest="http://exist-db.org/apps/restxq/myrest";


declare namespace rest="http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace transform="http://exist-db.org/xquery/transform";
import module namespace compression="http://exist-db.org/xquery/compression";


declare namespace system="http://exist-db.org/xquery/system";
import module namespace config="http://exist-db.org/apps/topoTEI/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace req="http://exquery.org/ns/request";
import module namespace functx="http://www.functx.com";
import module namespace file="http://exist-db.org/xquery/file";
import module namespace app="http://exist-db.org/apps/topoTEI/templates" at "app.xqm";
import module namespace storage="http://exist-db.org/apps/myapp/storage" at "storage.xqm";
declare namespace upgrade="http://exist-db.org/apps/topoTEI/upgrade";
import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "dbutils.xqm";
declare namespace json="http://www.json.org";



import module namespace myparsedata="http://exist-db.org/apps/myapp/myparsedata" at "myparsedata.xqm";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";
import module namespace hc="http://expath.org/ns/http-client";


(: downloads a file from a remote HTTP server at $file-url and save it to an eXist-db $collection.
 : we try hard to recognize XML files and save them with the correct mimetype so that eXist-db can 
 : efficiently index and query the files; if it doesn't appear to be XML, though, we just trust 
 : the response headers :)
declare function local:http-download($file-url as xs:string, $collection as xs:string, $file as xs:string?) as item()* {
    let $request := <hc:request href="{$file-url}" method="GET"/>
    let $response := hc:send-request($request)
    let $head := $response[1]
    

    
    return
        (: check to ensure the remote server indicates success :)
        if ($head/@status = '200') then
            (: try to get the filename from the content-disposition header, otherwise construct from the $file-url :)
            let $filename := if ($file) then ($file) else (
                if (contains($head/hc:header[@name='content-disposition']/@value, 'filename=')) then 
                    $head/hc:header[@name='content-disposition']/@value/substring-before(substring-after(., 'filename="'), '"')
                else 
                    (: use whatever comes after the final / as the file name:)
                    replace($file-url, '^.*/([^/]*)$', '$1')
            )
            (: override the stated media type if the file is known to be .xml :)
            let $media-type := $head/hc:body/@media-type
            let $mime-type := 
                if (ends-with($file-url, '.xml') and $media-type = 'text/plain') then
                    'application/xml'
                else 
                    $media-type
            (: if the file is XML and the payload is binary, we need convert the binary to string :)
            let $content-transfer-encoding := $head/hc:body[@name = 'content-transfer-encoding']/@value
            let $body := $response[2]
            let $output-collection := xmldb:login($collection, 'test', 'test')
           
            return if (ends-with($file-url, '.xml') and $content-transfer-encoding = 'binary') then 
                    let $file := util:binary-to-string($body) 
                    return xmldb:store($collection, $filename, $file, $mime-type)
                else 
                    try {
                    xmldb:store-as-binary($collection, $filename, $body)
                    } catch * {
                        console:log('Error (' || $err:code || '): ' || $err:description || " "|| xmldb:collection-available(concat($collection,'/')))
                    }
            
                
        else
            <error>
                <message>Oops, something went wrong:</message>
                {$head}
            </error>
};





declare
  %rest:path("/save")
  %rest:POST
   %rest:form-param("file", "{$file}", "unknown.xml")
   %rest:form-param("elements", "{$elements}", "[]")
function myrest:saveData($file as xs:string*,$elements as xs:string*) {
   let $newfile := local:updateFile($file, $elements)
   
   return 
     <rest:response>
        <http:response status="200" message="OK">
             <response name="location" value="/exist/restxq/transform?file={$file}"/>
        </http:response>
        
    </rest:response>
};
declare
  %rest:path("/upgrade")
  %rest:GET
  %rest:query-param("file", "{$file}", "/config/upgrade.xml")
  %rest:header-param("Referer", "{$referer}", "none")
function myrest:upgrade($file, $referer) {

    let $target := concat($config:app-root, '/import')
    let $upgrade := doc($file)
    let $filename := substring-after($file, '/config/')
    let $collection := substring-before($file, $filename)
    let $result := for $url in $upgrade//upgrade:url
        let $logDownload := console:log("Downloading " || $url/@target)
        return local:http-download($url/@href, $target, $url/@target)
    let $newUpgrade := doc($upgrade/upgrade:upgrade/@href)
    let $collection := concat($config:app-root, '/config')
    let $output-collection := xmldb:login($collection, 'test', 'test')
    let $store := xmldb:store($collection, $filename, $newUpgrade,  'application/xml')
    let $newUpgradeConfig := doc($store)
    let $result := update value $newUpgradeConfig//upgrade:deployed with current-dateTime()
    return
    <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$referer}#reload"/>
      
        </http:response>
    </rest:response> 
   
};

declare function local:getLocalPath() as xs:string {
    let $path := substring-before(substring-after(system:get-module-load-path(), '/db/'), '/modules')
    return $path
};

declare
    %rest:path("/preview")
    %rest:GET
    %rest:query-param("file", "{$file}", "default.xml")
    %output:media-type("text/html")
    %output:method("html5")
function myrest:preview($file as xs:string*) {
   let $filepath := concat($config:data-root,'/', $file)
        let $resources := "../apps/topoTEI/resources/"
        let $node-tree := doc($filepath)
        let $links := $config:font-config/fonts/links/url/text()
        let $styles := app:fontStyleStrings($resources)
    let $stylesheet := doc(concat($config:app-root, "/xslt/sourceDoc.xsl"))
    let $param := <parameters>
                    <param name="fonts" value="{$styles}"/> 
                    <param name="fontLinks" value="{$links}"/> 
                    <param name="resources" value="{$resources}"/> 
                    <param name="fullpage" value="true"/>   
                </parameters>
    return transform:transform($node-tree, $stylesheet, $param, (), "method=html5 media-type=text/html")
   
};
declare
    %rest:path("/content")
    %rest:GET
    %rest:query-param("file", "{$file}", "default.xml")
    %output:media-type("text/html")
    %output:method("html5")
function myrest:content($file as xs:string*) {
   let $filepath := concat($config:data-root,'/', $file)
        let $node-tree := doc($filepath)
    let $stylesheet := doc(concat($config:app-root, "/xslt/sourceDoc.xsl"))
 let $param := <parameters>
                    <param name="fullpage" value="false"/>
                    <param name="editorModus" value="false"/>   
                </parameters>
    return transform:transform($node-tree, $stylesheet, $param, (), "method=html5 media-type=text/html")
   
};

declare
    %rest:path("/toc")
    %rest:GET
    %rest:query-param("file", "{$file}", "TEI-Header_D20.xml")
    %rest:produces("text/xml")
    %output:media-type("text/xml")
    %output:method("xml")
function myrest:toc($file as xs:string*) {
    let $document := doc(concat($config:app-root, '/TEI/', $file))
    return 
        <toc header="{$file}" title="{$document//tei:titleStmt/tei:title/text()}">
        {   for $p in $document//tei:msContents//tei:p[tei:locus]
                where collection($config:data-root)//tei:pb[@xml:id = $p//tei:locus/text()]
                return <entries id="{$p//tei:locus/text()}" desc="{$p//tei:desc/text()}" resource="{util:document-name(xmldb:xcollection($config:data-root)//tei:pb[@xml:id = $p//tei:locus/text()][1])}"/>
        }
    </toc>
};

declare
    %rest:path("/tocJson")
    %rest:GET
    %rest:query-param("file", "{$file}", "TEI-Header_D20.xml")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
function myrest:tocJson($file as xs:string*) {
    myrest:toc($file)
};

declare
    %rest:path("/transform")
    %rest:GET
    %rest:query-param("file", "{$file}", "default.xml")
    %output:media-type("text/html")
    %output:method("html5")
function myrest:transform($file as xs:string*) {
    let $filepath := concat($config:data-root,'/', $file)
    let $log := console:log($filepath) 
    return local:showTransformation($filepath)
   
};
declare function local:storeFile($data, $type as xs:string, $targetType as xs:string, $collection as xs:string) as map(*) {
    let $parsedData := myparsedata:parseData($data, $type, $targetType)
    return storage:storeFile($parsedData, $type, $targetType, $collection)
};
declare
 %rest:path("/revertVersion")
 %rest:GET
 %rest:query-param("file", "{$file}", "none")
function myrest:revertVersion($file) {
    let $collection := concat($config:data-root, '/')
    let $output-collection := xmldb:login($collection, 'test', 'test') 
    let $originalFile := concat(substring-after(substring-before($file, '.xml_'), 'bak/'), '.xml')

    let $bakfile := storage:backupFile($originalFile, $collection )
    let $out-file := xmldb:store($collection, $originalFile, doc(concat($collection, $file)))
    return <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="/exist/restxq/deleteBak?file={$file}"/>
        </http:response>
    </rest:response> 
};
declare
 %rest:path("/deleteBak")
 %rest:GET
 %rest:query-param("file", "{$file}", "none")
function myrest:deleteBakFile($file) {
    let $refFile := if (not(contains($file, '.xml_'))) then (
        let $collection := concat($config:data-root, '/')
        let $output := local:deleteAllVersions($file, $collection)
        return $file
    ) else (
        let $originalFile := concat(substring-after(substring-before($file, '.xml_'), 'bak/'), '.xml') 
        let $collection := concat($config:data-root, '/bak/')
        let $output-collection := xmldb:login($collection, 'test', 'test')
        let $deleted := xmldb:remove($collection, $file)
        return $originalFile
    )
    return <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="/exist/restxq/transform?file={$refFile}"/>
        </http:response>
    </rest:response> 
};

declare function local:deleteAllVersions($file, $collection) {
    let $output-collection := xmldb:login($collection, 'test', 'test')
    let $bakDir := concat($collection, 'bak/')
    let $output := for $bakFile in local:getVersions($file)
                            return  xmldb:remove($bakDir, $bakFile)
    return $output
};

declare function local:getVersions($resource as xs:string) as xs:string* {
    let $bakDir := concat($config:data-root, '/bak')
    for $bakFile in xmldb:get-child-resources($bakDir)
        where starts-with($bakFile, $resource)
        order by xmldb:last-modified($bakDir, $bakFile) descending
        return $bakFile
};

declare
 %rest:path("/delete")
 %rest:GET
 %rest:query-param("file", "{$file}", "none")
 %rest:header-param("Referer", "{$referer}", "none")
function myrest:deleteFile($file, $referer) {
        let $collection := concat($config:data-root, '/')
        let $output-collection := xmldb:login($collection, 'test', 'test')
        let $deleted := xmldb:remove($collection, $file)
        let $output := local:deleteAllVersions($file, $collection)
      return
    <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$referer}#reload"/>
      
        </http:response>
    </rest:response> 
};
declare
 %rest:path("/postfont")
 %rest:POST("{$data}")
 %rest:header-param("Content-Type", "{$type}")
 %output:media-type("text/html")
 %output:method("html5")
  %rest:header-param("Referer", "{$referer}", "none")
function myrest:uploadFont($data, $type, $referer) {
    let $targetType := 'font'
    let $collection := concat(replace($config:data-root, "data", "resources/"), 'fonts/')
    let $response := local:storeFile($data, $type, $targetType, $collection)
    let $location := concat(replace($referer, '(\?.*$)',''), '?msg=',  $response('status'))
    return  <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$location}"/>
      
        </http:response>
    </rest:response>
};
declare
 %rest:path("/old-posttransform")
 %rest:POST("{$data}")
 %rest:header-param("Content-Type", "{$type}")
 %output:media-type("text/html")
 %output:method("html5")
  %rest:header-param("Referer", "{$referer}", "none")
function myrest:OLDuploadTransform($data, $type, $referer) {
    let $targetType := "text/xml"
    let $collection := concat($config:data-root, "/")
    let $response := local:storeFile($data, $type, $targetType, $collection)
    let $status := $response('status')
    return if ($status = '200') then (
        local:showTransformation($response('localUri'))
    ) else (
        let $location := concat(replace($referer, '(\?.*$)',''), '?msg=', $status)
        return
    <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$location}"/>
      
        </http:response>
    </rest:response>
    )
};
declare
 %rest:path("/posttransform")
 %rest:POST("{$data}")
 %rest:header-param("Content-Type", "{$type}")
 %output:media-type("text/html")
 %output:method("html5")
  %rest:header-param("Referer", "{$referer}", "none")
function myrest:uploadTransform($data, $type, $referer) {
    let $targetType := 'text/xml'
    let $collection := concat($config:data-root, "/")
    let $response := local:storeFile($data, $type, $targetType, $collection)
    let $status := $response('status')
    return if ($status = '200') then (
        local:showTransformation($response('localUri'))
    ) else (
        let $location := concat(replace($referer, '(\?.*$)',''), '?msg=', $status)
        return
    <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$location}"/>
      
        </http:response>
    </rest:response>
    )
};
declare function local:showTransformation($file as xs:string){
   let $content := doc('transform.html')
    let $config := map {
        (: The following function will be called to look up template parameters :)
        $templates:CONFIG_APP_ROOT: $config:app-root,
        $templates:CONFIG_PARAM_RESOLVER : function($param as xs:string) as xs:string* {
            req:parameter($param)
        }
    }
    let $lookup := function($functionName as xs:string, $arity as xs:int) {
        
        try {
            function-lookup(xs:QName($functionName), $arity)
        } catch * {
            ()
        }
    }
    let $filename := functx:substring-after-last($file, '/')
    let $map := map { 'file': $file, 'filename': $filename}
    return
        templates:apply($content, $lookup, $map, $config) 
};


declare
    %rest:path("/export")
    %rest:GET
     %output:media-type("application/zip")
    %output:method("binary")
function myrest:export() {
    let $mimetype   := 'application/zip'
    let $method     := 'zip'
    let $collection := $config:data-root
    let $entries :=  dbutil:scan(xs:anyURI($collection), function($coll as xs:anyURI, $res as xs:anyURI?) {
            (: compression:zip doesn't seem to store empty collections, so we'll scan for only resources :)
            if (exists($res)) then
                let $relative-path := substring-after($res, $config:app-root || "/")
                return
                    if (util:binary-doc-available($res)) then
                        <entry type="uri" name="{$relative-path}">{$res}</entry>
                    else
                        <entry type="xml" name="{$relative-path}">{
                            (: workaround until https://github.com/eXist-db/exist/issues/2394 is resolved :)
                            util:declare-option(
                                "exist:serialize", 
                                "expand-xincludes=" 
                                || "yes" 
                                || " indent=" 
                                || "yes" 
                                || " omit-xml-declaration=" 
                                || "no"
                            ),
                            doc($res)
                        }</entry>
            else
                ()
        })
  let $data := compression:zip($entries, true())
  let $login := xmldb:login(concat($config:app-root,'/config'), 'test', 'test')
  let $log := console:log(current-date())
  let $date := format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]_[H01][m01][s01]")
  let $name := concat(substring-after($collection, $config:app-root || '/'), $date,'.zip')
   return (
    <rest:response>
        <http:response>
            <http:header name="Content-Disposition" value="{concat("attachment; filename=", $name)}"/>
        </http:response>
       
    </rest:response>
    , $data) 
  
    
};
declare function local:getContentFiles($pb) {
    let $stylesheet := config:resolve('xslt/expandSourceDoc.xsl')
    return if (count($pb) gt 1) then (
        let $file := (for $pbItem in $pb
                        order by xmldb:last-modified($config:data-root, util:document-name($pbItem)) descending
                        return util:document-name($pbItem))[1]
        let $data := doc(concat($config:data-root, '/',$file))
        let $transform := transform:transform($data, $stylesheet, (), (), "method=xml media-type=text/xml")
        return $transform
    ) else (
        if (count($pb) gt 0) then (
            let $file := util:document-name($pb)
            let $data := doc(concat($config:data-root, '/',$file))
            let $transform := transform:transform($data, $stylesheet, (), (), "method=xml media-type=text/xml")
            return $transform
        ) else ()    
    )
};
declare function local:getFileContents($parentDoc) {
    for $locus in $parentDoc//tei:sourceDesc/tei:msDesc/tei:msContents//tei:locus/text()
        return local:getContentFiles(xmldb:xcollection($config:data-root)/tei:TEI[descendant::tei:title/text() = $locus]//tei:text//tei:pb)
};
declare
    %rest:path("/manuscript")
    %rest:GET
    %rest:query-param("headerFile", "{$headerFile}", "TEI-Header_D20.xml")
    %rest:produces("application/xml")
function myrest:donwloadManuscript($headerFile as xs:string*) {
    let $doc-uri := concat($config:app-root, '/TEI/', $headerFile)
    let $mimetype   := 'application/xml'
    let $method     := 'xml'
    let $data := doc($doc-uri)
    let $newFilename := concat(substring-before(replace($data//tei:titleStmt//tei:title//text(), ' ', '_'), '_('), '.xml')
    let $newFile := storage:store($data, 'output', $newFilename)
    let $newLog := console:log($newFile)
    let $newData := doc($newFile)
    let $emptyText := for $textContent in $newData//tei:text/tei:body/*
                        return update delete $textContent
    let $transform := local:getFileContents($newData)
    let $newText := for $text in $transform//tei:text/tei:body/*
        return update insert $text into $newData//tei:text/tei:body
    let $createSourceDoc := if ($newData/tei:sourceDoc) then () else (
        update insert <sourceDoc xmlns="http://www.tei-c.org/ns/1.0"/> into $newData/tei:TEI    
    )    
    let $newSurface := for $surface in $transform//tei:sourceDoc/*
        return update insert $surface into $newData//tei:sourceDoc
    
    return (
    <rest:response>
        <http:response>
            <http:header name="Content-Type" value="{$mimetype}"/>
            <http:header name="Content-Disposition" value='Attachment; filename="{$newFilename}"'/>
        </http:response>
        <output:serialization-parameters>
            <output:method value="{$method}"/>
            <output:media-type value="{$mimetype}"/>
        
        </output:serialization-parameters>
    </rest:response>, $newData
    )
};
declare
    %rest:path("/download")
    %rest:GET
    %rest:query-param("file", "{$file}", "D20_a28r_check2.xml")
    %rest:produces("application/xml")
function myrest:donwload($file as xs:string*) {
    let $doc-uri := concat($config:data-root, '/', $file)
    let $mimetype   := 'application/xml'
    let $method     := 'xml'
    let $data := doc($doc-uri)
    (:  :let $stylesheet := config:resolve('xslt/recreate_hierarchies.xsl')

    let $export-data := transform:transform($data, $stylesheet, (), (), "method=xml media-type=text/xml") :)
return (
    <rest:response>
        <http:response>
            <http:header name="Content-Type" value="{$mimetype}"/>
        </http:response>
        <output:serialization-parameters>
            <output:method value="{$method}"/>
            <output:media-type value="{$mimetype}"/>
        
        </output:serialization-parameters>
    </rest:response>, $data
    )
    

  
    
};


declare function local:parseHeader($data, $boundary){
    let $head := replace(substring-before(substring-after($data, $boundary), "Content-Type:"),  '(\r?\n|\r)', '')
    let $content-type := concat("content-type: ", replace(tokenize(substring-after($data, "Content-Type:"), '\n')[1], '(\s+)', ''))
    let $full-header := concat($head, ";", $content-type)
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

declare
%rest:path("/upload")
 %rest:POST("{$data}")
 %rest:header-param("Content-Type", "{$type}")
 %rest:header-param("Referer", "{$referer}", "none")
function myrest:uploadFile($data, $type, $referer as xs:string*) {
    let $collection := concat($config:data-root, "/data/")
    let $output-collection := xmldb:login($collection, 'test', 'test')
    let $boundary := substring-after($type, "boundary=")
    let $content := substring-before(substring-after($data, $boundary), concat("--", $boundary))
    let $header := local:parseHeader($data, $boundary)
    let $xmlContent := replace(substring-after($content, $header('content-type')), '(^\s+)', '')
    let $filename := $header('filename')
    let $backup := storage:backupFile($filename, $collection)
    
    let $response := xmldb:store($collection, $filename, $xmlContent)
    return 
     <rest:response>
        <http:response status="302" message="Temporary Redirect">
            <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
            <http:header name="Pragma" value="no-cache"/>
            <http:header name="Expires" value="0"/>
            <http:header name="X-XQuery-Cached" value="false"/>
             <http:header name="location" value="{$referer}"/>
      
        </http:response>
    </rest:response>
   
};

declare function local:update($item, $document){
    if ($item('style')) then(
        update insert attribute style { $item('style')} into $document//*[@xml:id = $item('id')] 
    ) else (
        update insert attribute n { $item('n')} into $document//*[@xml:id = $item('id')] 
    )
};

declare function local:updateFile($file as xs:string, $elements as xs:string*) as xs:string* {
     let $array := parse-json($elements)
     let $collection := concat($config:data-root, "/")
     let $output-collection := xmldb:login($collection, 'test', 'test')
     let $backup := storage:backupFile($file, $collection)
     let $document := doc(concat($collection, $file))
     for $index in 1 to array:size($array)
        let $item := array:get($array, $index)
        let $out := local:update($item, $document)
     return $file
};

declare %private function local:getOldValue($document, $tag, $attr, $id) as xs:string* {
    $document//*[name() = $tag and @*[name() = $attr] = $id]/text()  
};
declare %private function local:newValueNotEqualOldValue($document, $tag, $attr, $id, $value) as xs:boolean* {
    local:getOldValue($document, $tag, $attr, $id) ne $value
};
declare %private function local:updateDocumentWithItemValue($document, $item){
   update value $document//*[name() = $item('tag') and @*[name() = $item('attr')] = $item('id')] with $item("value")   
};
declare function local:saveArrayItems($array, $targetDoc, $index, $isUpdated){
    if ($index le array:size($array)) then (
        let $item := array:get($array, $index)
        return if (local:newValueNotEqualOldValue($targetDoc, $item('tag'), $item('attr'), $item('id'), $item('value'))) then (
            let $update := local:updateDocumentWithItemValue($targetDoc, $item)
            return local:saveArrayItems($array, $targetDoc, $index+1, $isUpdated+1)
        ) else (
            local:saveArrayItems($array, $targetDoc, $index+1, $isUpdated)
        )
    ) else (
        $isUpdated    
    )
};
declare function local:processConfig($configuration as xs:string*) as xs:boolean {
    let $config := parse-json($configuration)
    let $output-collection := xmldb:login(concat($config:app-root, '/config'), 'test', 'test')
    let $configArray := $config('config')
    let $configUpdateCount := local:saveArrayItems($configArray, $config:gui-config, 1, 0)
    let $fontArray := $config('font')
    let $fontUpdateCount := local:saveArrayItems($fontArray, $config:font-config, 1, 0)
    return $fontUpdateCount eq 0
};
declare
  %rest:path("/config")
  %rest:POST
  %rest:form-param("configuration", "{$configuration}", "[]")

function myrest:updateConfig($configuration as xs:string*) {
    let $oldFontSameAsNew := local:processConfig($configuration) 
    
    return if ($oldFontSameAsNew) then (
        <rest:response>
            <http:response status="200" message="OK"/>
        </rest:response>
        ) else (
        <rest:response>
            <http:response status="205" message="Reset Content">
                <http:header name="Cache-Control" value="no-cache, no-store, must-revalidate"/>
                <http:header name="Pragma" value="no-cache"/>
                <http:header name="Expires" value="0"/>
                <http:header name="X-XQuery-Cached" value="false"/>
            </http:response>
        </rest:response>)
};

