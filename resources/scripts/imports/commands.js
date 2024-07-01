function showJSFunc(){
        let funcs = [];
        Array.from(document.querySelectorAll('*[onclick], *[onchange]')).forEach(elem =>{
           const func = (elem.onclick) ? elem.onclick : elem.onchange;
           if (func.toString().indexOf('=') == -1){
                const f = func.toString().replace('function onclick(event) {\n','').replace('function onchange(event) {\n','').replace('\n}','');
                funcs.push(f);
           }
        })
        Array.from(new Set(funcs)).sort().forEach(f =>console.log(f, window[f.split('(')[0]]));
}

function checkVersions(button){
    if (!button.getAttribute('disabled')){
        let versionPanel = document.getElementById("versionPanel"); 
        hideOtherInputs(versionPanel.id);
        versionPanel.style.visibility = (versionPanel.style.visibility == 'visible') ? 'hidden' : 'visible';
    }
}
function deleteVersion(all){
    if (all){
        let file = document.getElementById(FILENAME);
        let dialogText = 'Alle alten Versionen wirklich löschen?'
        if (file && confirm(dialogText) == true){
            location.href = '/exist/restxq/deleteBak?file=' + file.value;
        }
    } else {
        let form = document.getElementById(VERSIONS);
        if (form && form.elements.file.value){
            let currentFile = 'bak/' + form.elements.file.value;   
            location.href = '/exist/restxq/deleteBak?file=' + currentFile;
        }
    }
}
function downloadFile(button){
    if (!button.getAttribute('disabled')){
       let link = document.getElementById('downloadLink');
       if (link){
            if(topoTEIObject.runsOnBakFile){
                let currentFile = link.href.substring(link.href.indexOf('?')).replace('?file=','');   
                let filename = currentFile.substring(0, currentFile.indexOf('.')) + '_' + currentFile.substring(currentFile.indexOf('.')).replace('.xml_','') ;
                link.setAttribute('download', filename);
                console.log(currentFile, filename)
                let newHref = link.href.substring(0, link.href.indexOf('?')) + "?file=bak/" + currentFile;
                link.setAttribute('href', newHref)
            }
            link.click();    
        } 
    }
}
function enableButtons(buttonIds){
    buttonIds.forEach(buttonId =>{
	    let button = document.getElementById(buttonId);
	    if (button){
	        button.removeAttribute('disabled');    
	    }
	});
}

function revertVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/revertVersion?file=' + currentFile;
    }
}

function setInputValue(input, styleValue, id, isClass){
    if (styleValue) {
        input.value = saveReplaceLength(styleValue, topoTEIObject.pixelLineHeight) 
    }
    input.setAttribute('data-is-class', String(isClass));
    input.setAttribute('data-id', id);
}
function showDefaultVersion(defaultFile){
    location.href = '/exist/restxq/transform?file=' + defaultFile;
}
function showHelp() {
    alert('Tastenbelegung:\n <Enter>: ')   ; 
}
function showPreview () {
   let file = document.getElementById(FILENAME); 
   window.open('/exist/restxq/export2TP?file=' + file.value, '_blank');
}
function showVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/transform?file=' + currentFile;
    }
}
function zoom(zoomLink){
    const zoomValue = (zoomLink.dataset.direction == 'in') ? 1 : -1;
    topoTEIObject.pixelLineHeight += zoomValue;
    const tf = document.getElementsByClassName(TRANSCRIPTION_FIELD)[0]
    tf.style.fontSize = topoTEIObject.pixelLineHeight + 'px';
    positionInfo();
}

















