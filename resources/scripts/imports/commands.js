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
            if(runsOnBakFile){
                let currentFile = link.href.substring(link.href.indexOf('?')).replace('?file=','');   
                let filename = currentFile.substring(0, currentFile.indexOf('.')) + '_' + currentFile.substring(currentFile.indexOf('.')).replace('.xml_','')  + '.xml';
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
function myPost(button) {
   if (!button.getAttribute('disabled')){
       let elements = Array.from(document.getElementsByClassName(VALUE_CHANGED));
       let elementInfos = [];
       elements.forEach(element =>{
           getStyleFromElement(element, elementInfos)
        });
        sender.send(elementInfos);
   } 
}
function pageSetup(){
    if (!runsOnBakFile){
        let form = document.getElementById(PAGE_SETUP);
        hideOtherInputs(form.id);
        form.style.visibility = (form.style.visibility == 'visible') ? 'hidden' : 'visible';
        if (form.style.visibility == 'visible'){
            Array.from(form.lastElementChild.children).filter(child =>child.id).forEach(pageInput =>{
                let tf = Array.from(document.getElementsByClassName(TRANSCRIPTION_FIELD))[0];
                let style = tf.style[pageInput.dataset.param];
            });
        }
    }   
}

function redo(){
    let button = document.getElementById("redoButton");
    if(!button.getAttribute('disabled') && redoStack.length > 0){
        Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
        let lastEvent = redoStack.pop();
        lastEvent.undo(false);
    }    
}
function revertVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/revertVersion?file=' + currentFile;
    }
}
function saveConfig(fontIdArray, dataNameArray) {
    let fontSelectors = Array.from(fontIdArray.map(id =>document.getElementById(id)));
    let fonts =  fontSelectors.map(fontSelector => createConfigObject(fontSelector.id, fontSelector.options[fontSelector.selectedIndex].text, 'family', 'current'));
   let configData = dataNameArray.map(id =>createConfigObject(id, document.getElementById(id).value, 'name', 'param'));
    let data = { font: fonts, config: configData }
    let jsonData = JSON.stringify(data);
    sender.sendConfig(jsonData, toggleConfig)
}
function showDefaultVersion(defaultFile){
    location.href = '/exist/restxq/transform?file=' + defaultFile;
}
function showHelp() {
    alert('Tastenbelegung:\n <Enter>: ')   ; 
}
function showLog(){
    let button = document.getElementById("logButton");
    if(!button.getAttribute('disabled') && logger){
        logger.show();
    }
}
function showPreview () {
   let file = document.getElementById(FILENAME); 
   window.open('/exist/restxq/preview?file=' + file.value, '_blank');
}
function showVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/transform?file=' + currentFile;
    }
}
function toggleConfig(){
    let config = document.getElementById("editorInput"); 
    config.style.visibility = (config.style.visibility == 'visible') ? 'hidden' : 'visible';
    hideOtherInputs(config.id);
    
}
function undo(){
    let button = document.getElementById("undoButton");
    if(!button.getAttribute('disabled') && undoStack.length > 0){
        Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
        let lastEvent = undoStack.pop();
        lastEvent.undo(true);
    }
}
function zoom(zoomLink){
    const zoomValue = (zoomLink.dataset.direction == 'in') ? 1 : -1;
    pixelLineHeight = pixelLineHeight + zoomValue
    const tf = document.getElementsByClassName(TRANSCRIPTION_FIELD)[0]
    tf.style.fontSize = pixelLineHeight + 'px';
    positionInfo();
}







/* This function is currently not used */

function openFile(button){ 
    if (!button.getAttribute('disabled')){
        let collection = document.getElementById('collection');
        let file = document.getElementById(FILENAME);
        if (collection && file){
            redoStack = [];
            handleButtons();
            Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
            let filepath = (runsOnBakFile) ? collection.value + '/bak/' + file.value : collection.value + '/' + file.value;
            fileIsOpenedInEditor = true;
            window.open('/exist/apps/eXide/index.html?open=' + filepath, '_blank');
            
           
        }
    }
}










