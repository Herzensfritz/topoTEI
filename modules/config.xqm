xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)

module namespace config="http://exist-db.org/apps/topoTEI/config";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace functx="http://www.functx.com";
declare namespace upgrade="http://exist-db.org/apps/topoTEI/upgrade";
(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:gui-config := doc(concat($config:app-root, "/config/gui_config.xml"));

declare variable $config:font-config := doc(concat($config:app-root, "/config/fonts.xml"));

declare variable $config:tp-extension := '_tp.xml';

declare variable $config:data-root := $config:app-root || "/data";

declare variable $config:dirMap := map{ "data": $config:data-root,
                        "config" : concat($config:app-root, '/config'),
                        "css" : concat($config:app-root, '/resources/css'),
                        "fonts" : concat($config:app-root, '/resources/fonts'),
                        "images" : concat($config:app-root, '/resources/images'),
                        "scripts" : concat($config:app-root, '/resources/scripts'),
                        "modules" : concat($config:app-root, '/modules'),
                        "templates" : concat($config:app-root, '/templates'),
                        "TEI" : concat($config:app-root, '/TEI'),
                        "xslt" : concat($config:app-root, '/xslt')
};

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};
declare %templates:wrap function config:app-version($node as node(), $model as map(*)) as xs:string* {
    "Version " || $config:expath-descriptor/@version
};
declare function config:app-home($node as node(), $model as map(*)) as node() {
    <a title="{$config:repo-descriptor//repo:description/text()}" class="{$node/@class}" href="{$node/@href}">{
    $config:expath-descriptor/expath:title/text()
    }</a>
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
          <caption>Application Info</caption>
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                  if ($attr eq '')
                then (<tr>
                    <td>{node-name($attr)}:</td>
                    <td>{$attr/@*/string()}</td>
                </tr>)
                else (<tr>
                    <td>{node-name($attr)}:</td>
                    <td>{$attr/string()}</td>
                </tr>)
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};

declare function config:app-changelog($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    let $upgrade := doc(concat($config:app-root, '/config/upgrade.xml'))
    return <div>
    {if (xs:dateTime($upgrade/upgrade:upgrade/upgrade:deployed/text()) gt xs:dateTime($config:repo-descriptor//repo:deployed/text())) then (
        <div><h2>Upgrade (deployed: {$upgrade/upgrade:upgrade/upgrade:deployed/text()})</h2>
        { for $url in $upgrade/upgrade:upgrade/upgrade:url
            return <div><h3>{$url/@target/string()}</h3>
                    {$url}
                    </div>
        }
        </div>
        ) else ()}
    
   {for $change in $config:repo-descriptor//repo:change
                    return <div>
                        <h2>Version {$change/@version/string()} :</h2>
                      <ul>
                            {for $text in $change/repo:ul/repo:li/text()
                                return <li>{local:addTags($text)}</li>
                            }  
                        
                        </ul>
                        <span>(deployed: { $config:repo-descriptor//repo:deployed/text()})</span>
                    </div>}
    </div>
        
};

declare function local:addTags($text) as xs:string* {
    if (contains($text, '%')) then (
        let $before := substring-before($text, '%')
        let $after := substring-after($text, '%')
        let $word := if (substring-before($after, ' ')) then (substring-before($after, ' ')) else ($after)
        let $rest := substring-after($after, ' ')
        return $before || '&lt;' || $word || '&gt; ' || local:addTags($rest) 
    ) else ($text)
};
