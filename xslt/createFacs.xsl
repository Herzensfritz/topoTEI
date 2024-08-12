<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0">
   <xsl:output method="html" encoding="UTF-8"/>
   <!-- Transform root to html either as standalone or as part of a page depending on param 'fullpage' -->
   <xsl:template match="/">
              <html>
              <head>
                  <title>ED Faksimile xml:ids </title>
                  <meta charset="UTF-8"/>
                  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                  <meta http-equiv="X-UA-Compatible" content="ie=edge"/>
      <title>Klassik Stiftung Dm Faksimile Test</title>
      <script src="https://unpkg.com/@webcomponents/webcomponentsjs@2.4.3/webcomponents-loader.js"></script>
      <script type="module" src="https://unpkg.com/@teipublisher/pb-components@latest/dist/pb-components-bundle.js"></script>
      <script type="module" src="https://unpkg.com/@teipublisher/pb-components@latest/dist/pb-leaflet-map.js"></script>
      <style>
         #ids {
            width: 250px;
         }

         #navi {
            max-height: 500px;
            overflow: scroll;
         }

         body {
             margin: 10px 20px;
             font-size: 16px;
             font-family: 'Roboto', 'Noto', sans - serif;
             line-height: 1.42857;
             font-weight: 300;
             color: #333333;

             --paper-tooltip-delay-in: 200;
         }


         pb-facsimile {
             flex: 1 0;
             min-width: 400px;
             --pb-facsimile-border: 4px solid rgba(0, 128, 90, 0.5);
             margin-right: 20px;
         }

         main > div {
             display: flex;
             height: 70vh;
             flex-direction: row;
             justify-content: flex-start;
         }
         [slot="after"] {
             margin-top: 5px;
             padding-top: 10px;
             border-top: 1px solid #606060;
         }
         [slot="before"] {
             padding-bottom: 10px;
             margin-bottom: 5px;
             border-bottom: 1px solid #606060;
         }

      </style>
      </head>
              <body>
      	<pb-page endpoint="https://teipublisher.com/exist/apps/tei-publisher" api-version="1.0.0" url-path="query">
		    <main>
            
		        <div>
               <div id="ids">
                 <h2>xml:id</h2>
                 <div id="navi">
                  <xsl:apply-templates select="/tei:TEI/tei:facsimile"/>
                 </div>
               </div>
               <pb-facsimile type="iiif" show-full-page-control="show-full-page-control" default-zoom-level="0" show-navigator="" show-sequence-control="" reference-strip="" show-navigation-control="" show-home-control="" show-rotation-control="">
                  </pb-facsimile>
               

              </div>

                        </main>
         </pb-page>
              </body>
           </html>
   </xsl:template>
   <xsl:template match="tei:surface">
      <li>
         <pb-facs-link facs="{tei:graphic/@url}"><xsl:value-of select="@xml:id"/></pb-facs-link>
      </li>
   </xsl:template>
   <xsl:template match="tei:facsimile">
      <ul>
         <xsl:apply-templates/>
      </ul>
   </xsl:template>

</xsl:stylesheet>
