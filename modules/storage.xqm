xquery version "3.0";

module namespace storage="http://exist-db.org/apps/myapp/storage";
import module namespace config="http://exist-db.org/apps/topoTEI/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare function storage:storeFile($parsedData, $type as xs:string, $targetType as xs:string, $collection as xs:string) as map(*) {
    if (map:contains($parsedData, $targetType)) then (
        let $filename := replace($parsedData('filename'), $config:tp-extension, '.xml')
        let $content := $parsedData($targetType)
        return if (contains($targetType, 'xml')) then (
            let $parsedXML := parse-xml($content)
            let $log := console:log($parsedXML)
            let $localUri := storage:storeDocument($parsedXML, $collection, $filename)
            return map:merge(($parsedData, map{ 'localUri': $localUri }))
        ) else (
            let $output-collection := xmldb:login($collection, 'test', 'test')
            let $localUri := xmldb:store($collection, $filename, $content)
            return map:merge(($parsedData, map{ 'localUri': $localUri }))    
        )
    ) else (
        $parsedData    
    )
};
declare function storage:storeDocument($document, $collection, $filename){
    let $output-collection := xmldb:login($collection, 'test', 'test')
    let $finalDocument := local:prepareDocument($document)   
    let $backup := storage:backupFile($filename, $collection)
    return xmldb:store($collection, $filename, $finalDocument)
};
declare function storage:store($document, $newCollection, $filename){
    let $output-collection := xmldb:login($config:app-root, 'test', 'test')
    let $collection := if (xmldb:collection-available(concat($config:app-root, '/',$newCollection)))        
        then (concat($config:app-root, '/',$newCollection))
        else (xmldb:create-collection($config:app-root, $newCollection))
    return xmldb:store($collection, $filename, $document)
};
declare function local:prepareDocument($document) as node() {
    let $stylesheet := config:resolve("xslt/createIDs4sourceDoc.xsl")
    let $fix := config:resolve("xslt/remove_namespaces.xsl")
    let $sourceDoc := config:resolve("xslt/updateSourceDoc.xsl")
    let $new-document := transform:transform($document, $stylesheet, (), (), "method=xml media-type=text/xml")
    let $fix-document := transform:transform($new-document, $fix, (), (), "method=xml media-type=text/xml")
    let $source-document := transform:transform($fix-document, $sourceDoc, (), (), "method=xml media-type=text/xml")
    return $source-document
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
declare function storage:backupFile($file as xs:string*, $collection as xs:string*) as xs:string* {
   let $output-collection := xmldb:login($collection, 'test', 'test') 
   return if (doc(concat($collection, $file))) then (
      let $backup-collection := local:createCollection($collection, "bak")
      let $backup := xmldb:store($backup-collection, local:getBackupFileName($file), doc(concat($collection, $file)))
      (:  :let $remove := xmldb:remove($collection, $file):)
      return $backup
    ) else ()
    
};