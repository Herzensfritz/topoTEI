
var COLLECTION = 'collection';
var DOWNLOAD_LINK = 'downloadLink';
var FILENAME = 'filename';
var VERSIONS = 'versions';

function updateOrderBy(checkbox){
    location.href = (location.search) ? location.href.substring(0, location.href.indexOf('?')) + '?newest=' + String(checkbox.checked) : location.href + '?newest=' + String(checkbox.checked);
}
function toggleConfig(){
    let config = document.getElementById("editorInput"); 
    config.style.visibility = (config.style.visibility == 'visible') ? 'hidden' : 'visible';
    hideOtherInputs(config.id);
    
}
function revertVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/revertVersion?file=' + currentFile;
    }
}
function showVersion(){
    let form = document.getElementById(VERSIONS);
    if (form && form.elements.file.value){
        let currentFile = 'bak/' + form.elements.file.value;   
        location.href = '/exist/restxq/transform?file=' + currentFile;
    }
}
function showPreview () {
   let file = document.getElementById(FILENAME); 
   window.open('/exist/restxq/preview?file=' + file.value, '_blank');
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
function showDefaultVersion(defaultFile){
    location.href = '/exist/restxq/transform?file=' + defaultFile;
}


function deleteFile(selectName){
    let select = document.getElementById(selectName);
    if (select){
       let currentFile = select.options[select.selectedIndex].text;
       let dialogText = 'Datei "' + currentFile + '" und alle Versionen davon wirklich löschen?'   
       if (confirm(dialogText) == true){
         location.href = '/exist/restxq/delete?file=' + currentFile; 
       }
    }
}
function exportManuscript(button){
    button.setAttribute('disabled', true)
    let promiseA = new Promise((resolve, reject) => {
        resolve(location.href = '/exist/restxq/manuscript');
    });
    promiseA.then(() => button.removeAttribute('disabled'));
}
function exportFile(selectName){
   
    let select = document.getElementById(selectName);
    let link = document.getElementById(DOWNLOAD_LINK);
    if (select && link){
       let currentFile = select.options[select.selectedIndex].text;
       link.setAttribute('download', currentFile);
       let newHref = link.href.substring(0, link.href.indexOf('?')) + "?file=" + currentFile;
       link.setAttribute('href', newHref)
       console.log(link);
        link.click();    
    }
}
function downloadFile(button){
    if (!button.getAttribute('disabled')){
       let link = document.getElementById(DOWNLOAD_LINK);
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
function openFile(button){
    if (!button.getAttribute('disabled')){
        let collection = document.getElementById(COLLECTION);
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
function saveConfig(fontIdArray, dataNameArray) {
    let fontSelectors = Array.from(fontIdArray.map(id =>document.getElementById(id)));
    let fonts =  fontSelectors.map(fontSelector => createConfigObject(fontSelector.id, fontSelector.options[fontSelector.selectedIndex].text, 'family', 'current'));
   let configData = dataNameArray.map(id =>createConfigObject(id, document.getElementById(id).value, 'name', 'param'));
    let data = { font: fonts, config: configData }
    let jsonData = JSON.stringify(data);
    sender.sendConfig(jsonData, toggleConfig)
}
function checkVersions(button){
    if (!button.getAttribute('disabled')){
        let versionPanel = document.getElementById("versionPanel"); 
        hideOtherInputs(versionPanel.id);
        versionPanel.style.visibility = (versionPanel.style.visibility == 'visible') ? 'hidden' : 'visible';
    }
}

function enableVersionButton(file, versionButtonId){
    let versionButton = document.getElementById(versionButtonId);
    let fileInput = document.getElementById(file);
    if (versionButton && fileInput){
        if (fileInput.value == 'true'){
            versionButton.removeAttribute('disabled');    
        } else {
            versionButton.setAttribute('disabled', 'true');    
        }    
    }
}
function undo(){
    let button = document.getElementById("undoButton");
    if(!button.getAttribute('disabled') && undoStack.length > 0){
        Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
        let lastEvent = undoStack.pop();
        lastEvent.undo(true);
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
function showLog(){
    let button = document.getElementById("logButton");
    if(!button.getAttribute('disabled') && logger){
        logger.show();
    }
}
function showHelp() {
    alert('Tastenbelegung:\n <Enter>: ')   ; 
}
function zoom(zoomLink){
    const zoomValue = (zoomLink.dataset.direction == 'in') ? 1 : -1;
    pixelLineHeight = pixelLineHeight + zoomValue
    const tf = document.getElementsByClassName(TRANSCRIPTION_FIELD)[0]
    tf.style.fontSize = pixelLineHeight + 'px';
    positionInfo();
}

