xquery version "3.1";

(:~ This library module contains XQSuite tests for the exist_test app.
 :
 : @author Christian Steiner
 : @version 1.0.0
 : @see https://nietzsche.philhist.unibas.ch
 :)

module namespace tests = "http://exist-db.org/apps/topoTEI/tests";

import module namespace app = "http://exist-db.org/apps/topoTEI/templates" at "../../modules/app.xqm";
 
declare namespace test="http://exist-db.org/xquery/xqsuite";


declare variable $tests:map := map {1: 1};

declare
    %test:name('dummy-templating-call')
    %test:arg('n', 'div')
    %test:arg('name', 'Christian')
    %test:assertEquals("<p>Hello World! Christian</p>")
    function tests:templating-foo($n as xs:string, $name as xs:string) as node(){
        app:hello(element {$n} {}, $tests:map, $name)
};

declare
    %test:name('dummy-templating-call2')
    %test:arg('n', 'div')
    %test:arg('name', 'Christian')
    %test:assertEquals("<p>Hello World! Christian</p>")
    function tests:templating-fox($n as xs:string, $name as xs:string) as node(){
        app:hello(element {$n} {}, $tests:map, $name)
};
