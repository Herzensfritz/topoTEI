xquery version "3.1";

(:~ This is the default application library module of the exist_test app.
 :
 : @author Christian Steiner
 : @version 1.0.0
 : @see https://nietzsche.philhist.unibas.ch
 :)

(: Module for app-specific template functions :)
module namespace app="http://exist-db.org/apps/topoTEI/templates";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://exist-db.org/apps/topoTEI/config" at "config.xqm";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace system="http://exist-db.org/xquery/system";
import module namespace compression="http://exist-db.org/xquery/compression";
import module namespace unzip="http://joewiz.org/ns/xquery/unzip" at "unzip.xql";
import module namespace storage="http://exist-db.org/apps/myapp/storage" at "storage.xqm";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace file="http://exist-db.org/xquery/file";

import module namespace transform="http://exist-db.org/xquery/transform";
import module namespace functx="http://www.functx.com";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace upgrade="http://exist-db.org/apps/topoTEI/upgrade";


declare
     %templates:wrap
function app:uploadDialog($node as node(), $model as map(*)) {
    let $files :=  local:getTeiFiles($model('newest-first'))
    return <p>
        <div><button title="debug" onclick="location.href = '/exist/restxq/transform?file=a30r.xml'">debug</button></div> 
          {
              if(count($files) > 0) 
                    then (<div class="col-md-6">
                 <form action="/exist/restxq/transform" method="get">
                
                 <select id="fileSelection" name="file" onChange="enableVersionButton(file.value, 'versionButton')">
                    {for $resource in $files
                        return <option>  {$resource}</option>
                    }</select>
                <input type="submit" value="auswählen"/>
              <input id="newest" class="newest" type="checkbox" onChange="updateOrderBy(this)"/><label class="newest" for="newest"> Neueste zuerst</label>
            </form> 
            
             <span>
                <button title="Ausgewählte Datei runterladen" class="fbutton" onclick="exportFile('fileSelection')">Download ...</button>
                    
                <button title="Ausgewählte Datei löschen" class="fbutton"onClick="deleteFile('fileSelection')">Datei löschen</button>
                <button title="Alle Dateien exportieren" class="fbutton" onClick="location.href = '/exist/restxq/export'">Exportieren</button>
                 <button title="Manuskript als eine Datei exportieren" class="fbutton" onClick="exportManuscript(this)">Manuskript exportieren ...</button>
             </span>
             </div>) else ()
           }
          
          <div class="col-md-6">
              <form method="POST" action="/exist/restxq/posttransform" enctype="multipart/form-data">
                  
                  <input type="file" name="content" accept=".xml"/>
                  <input type="submit" value="upload"/>
                </form>
          </div>
           
          <div>{ if(count($files) > 0) 
                    then (<a hidden="true" id="downloadLink" href="/exist/restxq/download?file={$files[1]}" download="{$files[1]}">Download</a>) 
                    else ()
            }
          </div>
         
      </p>
};
declare 
function app:checkUpgrade ($node as node(), $model as map(*)) as node() {
    let $filename := 'upgrade.xml'
    let $local := doc(concat($config:app-root, '/config/', $filename))
    let $href := $local/upgrade:upgrade/@href
    return try {
       let $remote := doc($href)
       return if (xs:dateTime($local/upgrade:upgrade/upgrade:deployed/text()) lt xs:dateTime($remote/upgrade:upgrade/upgrade:deployed/text())) then (
            <a href="/exist/restxq/upgrade?file={concat($config:app-root, '/config/', $filename)}">upgrade {$remote/upgrade:upgrade/upgrade:deployed/text()}</a>
        ) else (
           <a/>
        )
    } catch * {
        <a class="error" data-msg="{$err:code}" />
    }
    
};
declare function app:importData($node as node(), $model as map(*)) as node()* {
    let $importDir := concat($config:app-root, '/import')
    let $output-collection := xmldb:login($importDir, 'test', 'test')
    let $create-importDir := if (xmldb:collection-available($importDir)) then () else (
        let $login := xmldb:login($config:app-root, 'test', 'test')
        return xmldb:create-collection($config:app-root, 'import'))
    let $removeZip := for $zipFile in xmldb:get-child-resources($importDir)
        where ends-with($zipFile, 'zip')
        let $zipFile := concat($importDir, '/', $zipFile)
        let $unzip := unzip:unzip($zipFile)
        return xmldb:remove($importDir, $zipFile)
    let $childCollection := for $child in xmldb:get-child-collections($importDir) 
        let $targetDir := $config:dirMap($child)
        let $login := xmldb:login($targetDir, 'test', 'test')
        let $childDir := concat($importDir, '/', $child)
        let $rMove := for $resource in xmldb:get-child-resources($childDir)
            return local:moveResource($childDir, $targetDir, $resource)
        return xmldb:remove(concat($importDir, '/', $child))
    let $singleFiles := for $singleFile in xmldb:get-child-resources($importDir)
        where ends-with($singleFile, '.xml')
        return local:moveResource($importDir, $config:data-root, $singleFile)
    return <div class="dataImported"/>
};

declare %private function local:moveResource($childDir, $targetDir, $resource){
    
    if (not(ends-with($resource, '.xml'))) then (
        xmldb:move($childDir, $targetDir, $resource)    
    ) else (
        let $document := doc(concat($childDir, '/', $resource))
        return if (local:isTeiFile($document)) then (
            let $stored := storage:storeDocument($document, $targetDir, $resource)
            return xmldb:remove($childDir, $resource)
        ) else (
            xmldb:move($childDir, $targetDir, $resource)     
        )
    )    
};

declare 
     %templates:wrap
function app:checkStatus ($node as node(), $model as map(*), $msg as xs:string?, $newest as xs:string?) as map(*) {
    let $default := map { "newest-first": ($newest = 'true' )}
    return if ($msg) then (
        switch($msg)
            case ("422") return map { "error": "Falscher Dateityp" }
            default return map:merge(($default, map { 'status' : $msg }))
    ) else (
        $default
    )
};
declare function app:link($node as node(), $model as map(*)) as node() {
    let $msg := console:log( replace($config:app-root, 'db', 'exist'))
    (: TODO create a link with the real path :)
    return <link rel="stylesheet" type="text/css" href="../apps/topoTEI/resources/css/test.css"/>
};
declare function app:title($node as node(), $model as map(*)) as element(h1) {
    let $msg := "Datei auswählen:"
    return if (map:contains($model, 'error')) then (
        <h1>Fehler: {$model('error')}! Bitte neue {$msg}</h1> 
    ) else (
        <h1>{$msg}</h1>
    )
};
declare function local:getTeiFiles($newest as xs:boolean) as xs:string* {
    let $contentList := doc(concat($config:app-root, '/TEI/TEI-Header_D20.xml'))//tei:msContents//tei:locus/text()
    return if ($newest) then (
        for $resource in xmldb:get-child-resources($config:data-root)
                        where local:isTeiFile(doc(concat($config:data-root, '/', $resource)))
                        
                        order by xmldb:last-modified($config:data-root, $resource) descending
                        return $resource
    ) else (
        if (count($contentList) gt 0) then (
            for $resource in xmldb:get-child-resources($config:data-root)
                        where local:isTeiFile(doc(concat($config:data-root, '/', $resource)))
                        order by local:getPageIndex(doc(concat($config:data-root, '/', $resource)), $contentList)
                        return $resource    
        ) else (
            for $resource in xmldb:get-child-resources($config:data-root)
                        where local:isTeiFile(doc(concat($config:data-root, '/', $resource)))
                        order by $resource
                        return $resource
        )
    )
                        
};
declare %private function local:getPageIndex($document as node(), $contentList) as xs:decimal {
    let $pb := $document//tei:pb/@xml:id
    return if ($pb) then (
        let $index := index-of($contentList, $pb)
        return if (count($index) gt 0) then (
            $index[1]
        ) else (
            let $new-index := index-of($contentList, replace($pb, 'v','r'))
            return if (count($new-index) gt 0) then (count($contentList) + $new-index[1]) else (count($contentList)*2)      
    )) else (
        count($contentList)*2 + 1    
    )
};
declare function local:isTeiFile($document as node()) {
    $document/tei:TEI    
};
declare function local:getVersions($resource as xs:string, $date_suffix as xs:string?) as map(*)* {
    let $bakDir := concat($config:data-root, '/bak')
    return if (xmldb:collection-available($bakDir)) then (
        for $bakFile in xmldb:get-child-resources($bakDir)
            where starts-with($bakFile, $resource)
            order by xmldb:last-modified($bakDir, $bakFile) descending
            return map { 'name': $bakFile, 'selected': (not(empty($date_suffix)) and ends-with($bakFile, $date_suffix))}
    ) else ()
};
declare function app:versions($node as node(), $model as map(*)) as element(div){
    let $file := $model('filename')
    let $mainVersion := if (contains($file, '.xml_')) then (concat(substring-before($file, '.xml_'), '.xml')) else ($file)
    let $suffix := if (contains($file, '.xml_')) then (substring-after($file, '.xml_')) else ()
    return 
    <div id="versionPanel" class="input">
        <h2>Versionen:</h2>
        <form id="versions">
            <fieldset>
               
                {   for $bakMap in local:getVersions($mainVersion, $suffix)
                        return   if($bakMap('selected')) 
                                then ( <div><input type="radio" name="file" value="{$bakMap('name')}" checked="true"/><label for="{$bakMap('name')}">{$bakMap('name')}</label></div>)
                                 else (<div><input type="radio" name="file" value="{$bakMap('name')}" onChange="enableButtons(['revertVersionButton','showVersionButton', 'deleteVersionButton'])"/>    <label for="{$bakMap('name')}">{$bakMap('name')}</label></div>)
                                 
                        
                    }
            </fieldset>
        </form>
        { if (not(empty($suffix))) 
            then(<span>
                        <button id="revertVersionButton" onClick="revertVersion()" title="Ausgewählte Version wiederherstellen"><i class="fa fa-undo"></i></button>
                        <button id="showVersionButton" onClick="showVersion()">Anzeigen</button>
                        <button title="Ausgewählte Version löschen" id="deleteVersionButton" onClick="deleteVersion(false)">Löschen</button>
                </span>) 
            else (<span>
                        <button id="revertVersionButton" onClick="revertVersion()" title="Ausgewählte Version wiederherstellen" disabled="true"><i class="fa fa-undo"></i></button>
                        <button id="showVersionButton" onClick="showVersion()" disabled="true">Anzeigen</button>
                        <button title="Ausgewählte Version löschen" id="deleteVersionButton" onClick="deleteVersion(false)" disabled="true">Löschen</button>
                </span>)
        }
        <button onClick="showDefaultVersion('{$mainVersion}')">Abbrechen</button>
        <button title="Alle alten Versionen löschen" onClick="deleteVersion(true)"><i class="fa fa-trash-o"></i></button>
    </div>

};

declare function local:createHiddenInput($map as map(*)) as element(input){
    let $id := $map('id')
    let $value := $map('value')
    return <input type="hidden" id="{$id}" name="{$id}" value="{$value}"/>    
};

declare function app:hiddenData($node as node(), $model as map(*)) as element(div) {
    let $collection := $config:data-root
    let $filename := $model('filename')
    let $maps := [ map { 'id': 'collection', 'name':'collection','value': $collection}, map {'id': 'filename','name':'file', 'value': $filename}]
    return <div class="input">
        {   for $index in 1 to array:size($maps)
                let $map := array:get($maps, $index)
                return local:createHiddenInput($map)
            }
       <a hidden="true" id="downloadLink" href="/exist/restxq/download?file={$filename}" download="{$filename}">Download</a>
    </div> 
};
declare function local:createFontFaces($current_font as xs:string?) as element(option)* {
    let $fontDir := concat(replace($config:data-root, "data", "resources/"), 'fonts/')
    return if (xmldb:collection-available($fontDir)) then (
        for $fontFile in xmldb:get-child-resources($fontDir)
            order by xmldb:last-modified($fontDir, $fontFile) descending
            return if ($fontFile = $current_font) then (
                <option selected="true">{$fontFile}</option>
                ) else (
                <option>{$fontFile}</option>    
                )
    ) else ()
};
declare function local:createWebFonts($currentFont) as element(option)* {
    for $localFont in $config:font-config//webfont/text()
            return if ($localFont = $currentFont) then (
                <option selected="true">{$localFont}</option>
                ) else (
                <option>{$localFont}</option>    
                )
   
};
declare function local:createFontFace($css, $family, $name, $resources) as xs:string {
    if (contains($name, '.')) then (
        if (starts-with($name, 'http')) then (
            '@font-face {
                font-family: "' || $family || '";
                src: url("' || $name || '");}
    .' || $css ||' {
        font-family: ' || $family ||';    
    }
       ' ) else (
    '@font-face {
                font-family: "' || $family || '";
                src: url("' || $resources || '/fonts/' || $name || '");}
    .' || $css ||' {
        font-family: ' || $family ||';    
    }
    ')) else (
        '.' || $css ||' {
            font-family: ' || $name ||';    
        }'    
    )  
};
declare function app:importScripts($node as node(), $model as map(*)) as element(script)* {
    let $dir := concat($config:app-root, substring-after($node/@src, '../apps/topoTEI'))
    for $script in xmldb:get-child-resources($dir)
        return <script type="{$node/@type}" src="{concat($node/@src, $script)}"/>
        
};
declare function app:fontLink($node as node(), $model as map(*)) as element(link)* {
    for $link in $config:font-config/fonts/links/url/text()
        return <link href='{$link}' rel='stylesheet' type='text/css'/>
};

declare function app:fontFace($node as node(), $model as map(*)) as element(style)* {
    for $font in $config:font-config/fonts/currentFonts/current
        return <style>{local:createFontFace($font/@css, $font/@family, $font/text(), "../apps/topoTEI/resources/")}</style>
};
declare function app:fontStyleStrings($resources) as  xs:string* {
    for $font in $config:font-config/fonts/currentFonts/current
        return local:createFontFace($font/@css, $font/@family, $font/text(), $resources)
};
declare function app:createConfig($node as node(), $model as map(*)) as element(div) {
 
    <div id="editorInput" class="input">
        <h2>Konfiguration</h2>
        <form name="config">
           { for $p in $config:gui-config/config/param
                   let $label := $p/@label
                   return <div><label class="config" for="{$p/@name}">{string($p/@label)}:</label><input type="number" id="{$p/@name}" value="{$p/text()}" step="any"/></div>
           }
            <div>
               
                {
                    for $currentFont in $config:font-config/fonts/currentFonts/current
                        return 
                         <div>
                             <label class="config" for="font"> {concat('Schrift ', $currentFont/@family)}:</label>    
                            <select id="{  $currentFont/@family}" name="font">
                                { local:createFontFaces($currentFont/text())}
                                { local:createWebFonts($currentFont/text()) }
                            </select></div>
                }   
            </div>
        
        </form>
        <button onClick="saveConfig([{string-join( for $item in $config:font-config/fonts/currentFonts/current/@family
            return concat("'", $item, "'"),',')}], [{string-join(
               for $item in $config:gui-config/config/param/@name
                    return concat("'", $item, "'"),
               ',')}])">Speichern</button>
               
    </div> 
};

declare function app:dialog($node as node(), $model as map(*)) as element(dialog) {
        <dialog>
            <nav>
                <button title="Download log" id="downloadLog"><iron-icon icon='cloud-download'></iron-icon></button>
                <button title="close" id="dialogClose"><iron-icon icon='close'></iron-icon></button>
             </nav>
            <p><textarea cols="70" rows="10" id="logTextField"></textarea></p>
           
        </dialog>
        
};
declare function app:positionInfo($node as node(), $model as map(*)) as element(position-info) {
        <position-info id="myPositionInfo" class="input" onChange="handleChange(event)">
            <toggle-listener></toggle-listener>
        </position-info>
        
};
declare function app:pageSetup($node as node(), $model as map(*)) as element(div) {
     <div id="pageSetup" class="input">
        <h2>Seiten Setup</h2>
         <form name="page">
            min-width <input type="number" value="56" id="pageWidth" step="1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="minWidth"/> em<br/>
             min-height <input type="number" value="30" id="pageHeight" step="1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="minHeight"/> em
             
      </form>
      </div>
};
declare function app:lineInput($node as node(), $model as map(*)) as element(div) {
 
     <div id="lineInput" class="input toppos">
      
        <h2>Zeilenposition</h2>
         <form name="line">
            <span id="param">bottom</span> <input type="number" value="3" id="linePosition" step="0.1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="bottom" data-function="positionInfo"/> em<br/>
            <span id="param">margin-left</span> <input type="number" value="3" id="verticalPosition" step="0.1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="marginLeft" data-function="positionInfo"/> em  <br/>
            z-index <input type="number" min="0" value="0" id="zindex" step="1" onChange="setZindex(this, value)"/> <iron-icon icon="help" onClick="alert('Elemente mit höherem z-index überlagern Elemente mit kleinerem z-index.')"></iron-icon>
      </form>
     

      </div>
};
declare function app:textBlockInput($node as node(), $model as map(*)) as element(div) {
    <div id="textBlockInput" class="input">
        <h2>Settings für Textblock</h2>
         <form name="line">
            Zeilenhöhe: <input type="number" value="3" id="lineHeightInput" step="0.1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="lineHeight"/> em<br/>
            padding-top: <input type="number" value="0" id="paddingTop" step="0.1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="paddingTop"/> em<br/>
            padding-bottom: <input type="number" value="0" id="paddingBottom" step="0.1" onkeypress="return noEnter(this)" onChange="setNewValue(this)" data-unit="em" data-param="paddingBottom"/> em
      </form>
    </div>
};

declare    
function app:navigation($node as node(), $model as map(*), $direction as xs:string?) as element(a) {
    let $file := $model('file')
    let $node-tree := doc($file)
    let $contentList := doc(concat($config:app-root, '/TEI/TEI-Header_D20.xml'))//tei:msContents//tei:locus/text()
    let $index := local:getPageIndex($node-tree, $contentList)
    let $newIndex := if ($direction = 'next') then ($index + 1) else ($index - 1)
    return if ($newIndex gt 0 and $index le count($contentList)) then (
        let $newId := $contentList[$newIndex] 
        let $newPb := xmldb:xcollection($config:data-root)//tei:pb[@xml:id = $newId]
        return if (count($newPb) gt 0) then (
             let $filename := util:document-name($newPb[1])
             return 
            <a class="{$node/@class}" href="/exist/restxq/transform?file={$filename}">{concat($direction,': ',$newId)}</a>
        ) else (<a/>)
    ) else ( <a/> )
};

declare    
function app:zoom($node as node(), $model as map(*), $direction as xs:string?) as element(a) {
    <a class="{$node/@class}" title="zoom {$direction}" onClick="zoom(this)" data-direction="{$direction}"><iron-icon icon="zoom-{$direction}"></iron-icon></a>
};

declare function app:transform($node as node(), $model as map(*)) {
    let $file := $model('file')

    let $node-tree := doc($file)
    let $stylesheet := doc(concat($config:app-root, "/xslt/sourceDoc.xsl"))
    let $param := <parameters>
                    <param name="fullpage" value="false"/>   
                </parameters>
    return transform:transform($node-tree, $stylesheet, $param, (), "method=html5 media-type=text/html") 

};
(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute: data-template="app:test" or class="app:test" (deprecated).
 : The function has to take 2 default parameters. Additional parameters are automatically mapped to
 : any matching request or function parameter.
 :
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)

declare
    %templates:wrap %templates:default ("name", "default") 
function app:hello($node as node(), $model as map(*), $name as xs:string?) {
   let $log := console:log('hello: ') 
   return <p> Hello World, and so! {$model('name')}</p>
};
declare
    
function app:divs($node as node(), $model as map(*), $file as xs:string*) as element(div) {
   <div id="myTest" class="datacontainer">
   {if ($file) then (
    for $entry in doc(concat("/db/apps/topoTEI/data/", $file))/data/entry
       return <div id="{$entry/id}" class="data" style="{$entry/style/text()}" draggable="true">{$entry/id/text()} {$entry/style/text()}</div>
       ) else (
    <div id="data1" class="data" draggable="true"> 
        <div class="mydivheader">Click here to move</div>
      A
    </div>)}
        
    </div>
};
declare
    %templates:default ("file", "default.xml") 
function app:files($node as node(), $model as map(*), $file as xs:string?) as element(select){
    <select name="file">
    {for $resource in xmldb:get-child-resources("/db/apps/topoTEI/data")
        return if ($resource = $file) then (
            <option selected="selected">  {$resource}</option>
        ) else (
            <option>  {$resource}</option>
        )
    }</select>
};

declare function app:test($node as node(), $model as map(*)) {
   
    <p>Hello World at <strong>{format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]_[H01]:[m01]:[s01]")}</strong>. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};



