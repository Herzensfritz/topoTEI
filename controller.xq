xquery version "3.1";

(:~ The controller library contains URL routing functions.
 :
 : @see http://www.exist-db.org/exist/apps/doc/urlrewrite.xml
 :)


declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;



if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="no"/>
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

  else if ($exist:path eq "/") then
  (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="no"/>
      <redirect url="index.html"/>
    </dispatch>

  else if (ends-with($exist:resource, ".html")) then (
  (: the html page is run through view.xq to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="no"/>
        <view>
          <forward url="{$exist:controller}/modules/view.xq"/>
        </view>
        <error-handler>
      	  <forward url="{$exist:controller}/error-page.html" method="get"/>
      		<forward url="{$exist:controller}/modules/view.xq"/>
      	</error-handler>
    </dispatch>)
    else
          (: everything else is passed through :)
          <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
              <cache-control cache="no"/>
          </dispatch>
