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

import module namespace transform="http://exist-db.org/xquery/transform";
import module namespace functx="http://www.functx.com";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
     %templates:wrap
function app:uploadDialog($node as node(), $model as map(*)) {
    let $files :=  local:getTeiFiles($model('newest-first'))
    return <p>
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
                <button title="Ausgewählte Datei exportieren" class="fbutton" onclick="exportFile('fileSelection')">Datei exportieren ...</button>
                    
                <button title="Ausgewählte Datei löschen" class="fbutton"onClick="deleteFile('fileSelection')">Datei löschen</button>
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
     %templates:wrap
function app:fontUpload($node as node(), $model as map(*)){
    <p>
        <h2>Schrift hochladen</h2>
        <div class="col-md-6">
              <form method="POST" action="/exist/restxq/postfont" enctype="multipart/form-data">
                  <input type="file" name="content"/>
                  <input type="submit" value="upload"/>
                </form>
                
            { if ($model('status') = '200') then (
                    <div>Schrift gespeichert</div>
                ) else ()
                
            }
          </div>
    </p>
};

declare 
     %templates:wrap
function app:checkStatus ($node as node(), $model as map(*), $msg as xs:string?, $newest as xs:string?) as map(*) {
    let $default := map { "newest-first": ($newest = 'true' or empty($newest))}
    return if ($msg) then (
        switch($msg)
            case ("422") return map { "error": "Falscher Dateityp" }
            default return map:merge(($default, map { 'status' : $msg }))
    ) else (
        $default
    )
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
    if ($newest) then (
        for $resource in xmldb:get-child-resources($config:data-root)
                        where local:isTeiFile(doc(concat($config:data-root, '/', $resource)))
                        
                        order by xmldb:last-modified($config:data-root, $resource) descending
                        return $resource
    ) else (
        for $resource in xmldb:get-child-resources($config:data-root)
                        where local:isTeiFile(doc(concat($config:data-root, '/', $resource)))
                        order by $resource
                        return $resource
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
declare function local:createWebFonts($document) as element(option)* {
    for $localFont in $document/config/fonts/webfont/text()
            return if ($localFont = $document/config/fonts/current/text()) then (
                <option selected="true">{$localFont}</option>
                ) else (
                <option>{$localFont}</option>    
                )
   
};
declare function local:createFontFace($fontName) as xs:string {
    if (contains($fontName, '.')) then (
    '@font-face {
                font-family: "MyFont";
                src: url("../apps/topoTEI/resources/fonts/' || $fontName || '");}
    #transkription {
        font-family: MyFont;    
    }
    ') else (
        '#transkription {
            font-family: ' || $fontName ||';    
        }'    
    )  
};
declare function app:fontFace($node as node(), $model as map(*)) as element(style)* {
    let $configFile := doc(concat($config:app-root, '/config/gui_config.xml'))
    return 
        if ($configFile/config/fonts/current/text()) then (
            <style>{local:createFontFace($configFile/config/fonts/current/text())} 
        </style>
 
          ) else ()
};
declare function app:createConfig($node as node(), $model as map(*)) as element(div) {
    let $configFile := doc(concat($config:app-root, '/config/gui_config.xml'))
    return 
    <div id="editorInput" class="input">
        <h2>Konfiguration</h2>
        <form name="config">
           { for $p in $configFile/config/param
                   let $label := $p/@label
                   return <div><label class="config" for="{$p/@name}">{string($p/@label)}:</label><input type="number" id="{$p/@name}" value="{$p/text()}" step="any"/></div>
           }
            <div>
                <label class="config" for="font">Schrift:</label>
                <select id="fontSelection" name="font">
                    { local:createFontFaces($configFile/config/fonts/current/text())}
                    { local:createWebFonts($configFile) }
                </select>
                   
            </div>
        
        </form>
        <button onClick="saveConfig('fontSelection', [{string-join(
               for $item in $configFile/config/param/@name
                    return concat("'", $item, "'"),
               ',')}])">Speichern</button>
               
    </div> 
};
declare function app:lineInput($node as node(), $model as map(*)) as element(div) {
    <div id="lineInput" class="input">
        <h2>Lininenhöhe</h2>
         <form name="line">
            Abstand oben: <input type="number" value="0" id="top" step="any" onChange="changeLineHeight(top.value, true, false)"/>
                        <br/>
            Abstand unten: <input type="number" value="0" id="bottom" step="any" onChange="changeLineHeight(bottom.value, false, false)"/>
      </form>
    </div>
};

declare function app:transform($node as node(), $model as map(*)) {
    let $file := $model('file')
    let $node-tree := doc($file)
    let $stylesheet := doc(concat($config:app-root, "/xslt/gui_transcription.xsl"))
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



