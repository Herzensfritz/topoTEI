xquery version "3.1";

module namespace myrest="http://exist-db.org/apps/restxq/myrest";


declare namespace rest="http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace transform="http://exist-db.org/xquery/transform";
declare namespace system="http://exist-db.org/xquery/system";
import module namespace config="http://exist-db.org/apps/topoTEI/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace req="http://exquery.org/ns/request";
import module namespace functx="http://www.functx.com";
import module namespace app="http://exist-db.org/apps/topoTEI/templates" at "app.xqm";
import module namespace myparsedata="http://exist-db.org/apps/myapp/myparsedata" at "myparsedata.xqm";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";

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
  %rest:path("/fix")
  %rest:GET
function myrest:fixD($file as xs:string*,$elements as xs:string*) {
    let $bakDir := concat($config:data-root, '/bak')
    let $output-collection := xmldb:login($bakDir, 'test', 'test')
    (:  :let $output := for $bakFile in xmldb:get-child-resources($bakDir)
        where not(ends-with($bakFile, '.xml'))
        let $new := xmldb:remove($bakDir, $bakFile)
        return $new :)
   return 
    
      <rest:response>
        <http:response status="200" message="OK">
  
        </http:response>
        
    </rest:response>
   
};

declare function local:getLocalPath() as xs:string {
    let $path := substring-before(substring-after(system:get-module-load-path(), '/db/'), '/modules')
    return $path
};

declare
    %rest:path("/transform")
    %rest:GET
    %rest:query-param("file", "{$file}", "default.xml")
    %output:media-type("text/html")
    %output:method("html5")
function myrest:transform($file as xs:string*) {
    let $filepath := concat($config:data-root,'/', $file)
    return local:showTransformation($filepath)
   
};
declare function local:storeFile($data, $type as xs:string, $targetType as xs:string, $collection as xs:string) as map(*) {
    let $output-collection := xmldb:login($collection, 'test', 'test')
    
    let $parsedData := myparsedata:parseData($data, $type, $targetType)
    return if (map:contains($parsedData, $targetType)) then (
        let $filename := $parsedData('filename')
        let $content := $parsedData($targetType)
        return if (contains($targetType, 'xml')) then (
            let $document := local:prepareDocument($content)
            let $backup := local:backupFile($filename, $collection)
            let $localUri := xmldb:store($collection, $filename, $document)
            return map:merge(($parsedData, map{ 'localUri': $localUri }))
        ) else (
            let $localUri := xmldb:store($collection, $filename, $content)
            return map:merge(($parsedData, map{ 'localUri': $localUri }))    
        )
    ) else (
        $parsedData    
    )
};
declare function local:prepareDocument($xmlContent as xs:string) as node() {
    let $document := parse-xml($xmlContent)
    let $stylesheet := config:resolve("xslt/remove_hierarchies.xsl")
    let $fix := config:resolve("xslt/remove_namespaces.xsl")
    let $new-document := transform:transform($document, $stylesheet, (), (), "method=xml media-type=text/xml")
    let $fix-document := transform:transform($new-document, $fix, (), (), "method=xml media-type=text/xml")
    return $fix-document
};
declare
 %rest:path("/revertVersion")
 %rest:GET
 %rest:query-param("file", "{$file}", "none")
function myrest:revertVersion($file) {
    let $collection := concat($config:data-root, '/')
    let $output-collection := xmldb:login($collection, 'test', 'test') 
    let $originalFile := concat(substring-after(substring-before($file, '.xml_'), 'bak/'), '.xml')
    let $log := console:log($file)
    let $bakfile := local:backupFile($originalFile, $collection )
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
 %rest:path("/posttransform")
 %rest:POST("{$data}")
 %rest:header-param("Content-Type", "{$type}")
 %output:media-type("text/html")
 %output:method("html5")
  %rest:header-param("Referer", "{$referer}", "none")
function myrest:uploadTransform($data, $type, $referer) {
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
    %rest:path("/download")
    %rest:GET
    %rest:query-param("file", "{$file}", "D20_a28r_check2.xml")
    %rest:produces("application/xml")
function myrest:donwload($file as xs:string*) {
    let $doc-uri := concat($config:data-root, '/', $file)
    let $mimetype   := 'application/xml'
    let $method     := 'xml'
    let $data := doc($doc-uri)
    let $stylesheet := config:resolve('xslt/recreate_hierarchies.xsl')

    let $export-data := transform:transform($data, $stylesheet, (), (), "method=xml media-type=text/xml")
return (
    <rest:response>
        <http:response>
            <http:header name="Content-Type" value="{$mimetype}"/>
        </http:response>
        <output:serialization-parameters>
            <output:method value="{$method}"/>
            <output:media-type value="{$mimetype}"/>
        
        </output:serialization-parameters>
    </rest:response>
    , $export-data
    (:  :<serverinfo accept="{req:header("Accept")}" method="{$method}" mimetype="{$mimetype}">
        <desc language="en-US"/>
        <database version="{system:get-version()}"/>
    </serverinfo>:)
)
  
    
};
declare function local:createCollection($collection as xs:string, $child as xs:string) as xs:string {
    let $new-collection := concat($collection, $child)
    return if  (not(xmldb:collection-available($new-collection))) then (
           let $target-collection := xmldb:create-collection($collection, $child)
           return $target-collection
    ) else (
        $new-collection    
    )   
};
declare function local:getBackupFileName($file as xs:string) as xs:string {
    let $damyrestring := format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]_[H01][m01][s01]")
    let $fileName := concat($file, "_", $damyrestring, '.xml')  
    return string($fileName)
};
declare function local:backupFile($file as xs:string*, $collection as xs:string*) as xs:string* {
   let $output-collection := xmldb:login($collection, 'test', 'test') 
   return if (doc(concat($collection, $file))) then (
      let $backup-collection := local:createCollection($collection, "bak")
      let $backup := xmldb:store($backup-collection, local:getBackupFileName($file), doc(concat($collection, $file)))
      (:  :let $remove := xmldb:remove($collection, $file):)
      return $backup
    ) else ()
    
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
    let $backup := local:backupFile($filename, $collection)
    
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
     let $backup := local:backupFile($file, $collection)
     let $document := doc(concat($collection, $file))
     for $index in 1 to array:size($array)
        let $item := array:get($array, $index)
        let $out := local:update($item, $document)
     return $file
};
declare function local:saveConfigItems($configArray, $document)  {
    for $index in 1 to array:size($configArray)
        let $item := array:get($configArray, $index) 
        let $out := local:updateConfigFile($item, $document)
        let $name := $item("name")
    return 0
};
declare function local:processConfig($configuration as xs:string*) as xs:boolean {
    let $config := parse-json($configuration)
    let $log := console:log($config)
    let $configArray := $config('config')
    let $collection := replace($config:data-root, "data", "config/")
   
   let $output-collection := xmldb:login($collection, 'test', 'test')
   let $document := doc(concat($collection, "gui_config.xml"))
   let $oldFontSameAsNew := ($document/config/fonts/current/text() = $config('font'))
   let $update := local:updateConfigFontValue($config('font'), $document)
   let $configItemsChanged := local:saveConfigItems($configArray, $document)
    return $oldFontSameAsNew
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

declare function local:updateConfigFontValue($font, $document){
   update value $document/config/fonts/current with $font 
};
declare function local:updateConfigFile($item, $document){
   update value $document/config/param[@name= $item("name") ] with $item("value")   
};

