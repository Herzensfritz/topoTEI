/** 
**/
var runsOnBakFile = false;
var NEWEST = "newest";
var FILENAME = 'filename';
var COLLECTION = 'collection';
var DOWNLOAD_LINK = 'downloadLink';
var VERSIONS = 'versions';
var fileIsOpenedInEditor = false;
var currentLine = null;
var undoStack = [];
var redoStack = [];
var tester = [ FILENAME, COLLECTION, DOWNLOAD_LINK];
function test (){
    tester.forEach(test =>{
        console.log(document.getElementById(test))    
});
}
function updateOrderBy(checkbox){
    location.href = (location.search) ? location.href.substring(0, location.href.indexOf('?')) + '?newest=' + String(checkbox.checked) : location.href + '?newest=' + String(checkbox.checked);
     
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
function showDefaultVersion(defaultFile){
    location.href = '/exist/restxq/transform?file=' + defaultFile;
}
function enableButtons(buttonIds){
    buttonIds.forEach(buttonId =>{
        let button = document.getElementById(buttonId);
        if (button){
           button.removeAttribute('disabled');    
        }
    });
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
function checkVersions(button){
    if (!button.getAttribute('disabled')){
        let versionPanel = document.getElementById("versionPanel"); 
        versionPanel.style.visibility = (versionPanel.style.visibility == 'visible') ? 'hidden' : 'visible';
    }
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
function exportFile(selectName){
   
    let select = document.getElementById(selectName);
    let link = document.getElementById(DOWNLOAD_LINK);
    if (select && link){
       let currentFile = select.options[select.selectedIndex].text;
       link.setAttribute('download', currentFile);
       let newHref = link.href.substring(0, link.href.indexOf('?')) + "?file=" + currentFile;
       link.setAttribute('href', newHref)
      
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

class Change {
    constructor(element, offsetX, offsetY){
        this.element = element;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
    }    
    undo(isRedoing) {
        this.element.classList.add("selected");
        repositionElement(this.element, this.offsetX*-1, this.offsetY*-1, isRedoing);
    }
};
class LineChange {
    constructor(line, value, isTop){
        this.line = line;
        this.value = value;
        this.isTop = isTop;
    }    
    undo(isRedoing) {
        currentLine = this.line;
        changeLineHeight(this.value, this.isTop, isRedoing);
    }
};

window.onload = function() {
    if(window.location.hash == '#reload') {
        console.log('reloading .........')
        history.replaceState(null, null, ' ');
        window.location.reload(true);
    }
} 
function recordLineChange(line, isTop, isRedoing){
    let oldValue = (isTop) ? Number(currentLine.parentElement.style.paddingTop.replace('px','')) : Number(currentLine.parentElement.style.paddingBottom.replace('px',''));
    let change = new LineChange(line, oldValue, isTop);    
    let currentStack = (isRedoing) ? redoStack : undoStack;
    currentStack.push(change);
}
function changeLineHeight(value, isTop, isRedoing){
    if(currentLine){
        recordLineChange(currentLine, isTop, isRedoing);
        handleButtons();
        if (isTop){
            currentLine.parentElement.style.paddingTop = value + "px"; 
        } else {
            currentLine.parentElement.style.paddingBottom = value + "px"; 
        }
        if (Number(currentLine.parentElement.style.paddingTop.replace('px','')) != 0 
            || Number(currentLine.parentElement.style.paddingBottom.replace('px','')) != 0){
            currentLine.parentElement.classList.add('lineManuallyChanged');
        } else {
            currentLine.parentElement.classList.remove('lineManuallyChanged'); 
        }
    }  
}
function getLineHeightInput(element, id){
    if (!runsOnBakFile){
        let input = document.getElementById(id);
        if(currentLine === element){
            input.style.visibility = 'hidden';
            currentLine = null;
        } else {
            currentLine = element;
            input.firstElementChild.innerText = "Zeilenabstände für Zeile " + element.innerText;
            let top =  Number(element.parentElement.style.paddingTop.replace('px',''));
            let bottom =  Number(element.parentElement.style.paddingBottom.replace('px',''));
            Array.from(input.lastElementChild.children).filter(child =>child.value).forEach(child =>{child.value = (child.id == 'top') ? top : bottom });
            input.style.visibility = 'visible';
        }
    }
}
function saveStyleGet(element, attribute){
    return (element.style[attribute]) ? element.style[attribute] : "0px";   
}
function createInfo (element){
    let style = "left:" + saveStyleGet(element, 'left');
    if (element.parentElement && element.parentElement.className.includes('Ez')){
        if (element.parentElement.className.includes('below')){
            style = style + "; top:" + saveStyleGet(element, 'top') + "; height:" + saveStyleGet(element.parentElement, 'height');
        } else {
            style = style + "; top:" + saveStyleGet(element.parentElement, 'top') + "; height:" + saveStyleGet(element.parentElement, 'height');
        }    
    } else {
        style = style + "; top:" + saveStyleGet(element, 'top');    
    }
    return { id: element.id, style: style + ";"}    
}
function createStyleObject(element){
    let style = '';
    if (element.style.paddingTop){
        style =  'padding-top: ' +  element.style.paddingTop + ';';
    }
    if (element.style.paddingBottom){
        style =  style + 'padding-bottom: ' +  element.style.paddingBottom + ';';
    }
    return { id: element.id, style: style}    
}
function toggleConfig(){
    let config = document.getElementById("editorInput"); 
    config.style.visibility = (config.style.visibility == 'visible') ? 'hidden' : 'visible';
}
function createConfigObject(object){
    return { name: object.id, value: String(object.value)}    
}
function updateFont(font) {
    console.log(font)
    let xhr = new XMLHttpRequest()
    xhr.open('POST', "/exist/restxq/font", true)
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    xhr.send('font=' + font);
    xhr.onload = function () {
        //TODO
    }
  
}
function saveConfig(fontId, dataNameArray) {
    let fontSelector = document.getElementById(fontId);
    let font = fontSelector.options[fontSelector.selectedIndex].text;
   let configData = dataNameArray.map(id =>createConfigObject(document.getElementById(id)));
    let data = { font: font, config: configData }
    let jsonData = JSON.stringify(data);
    console.log(jsonData)
    let xhr = new XMLHttpRequest()
    xhr.open('POST', "/exist/restxq/config", true)
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    xhr.send('configuration=' + jsonData);
    xhr.onload = function () {
        if(this.status == '205'){
            window.location.reload(true);    
        }
        toggleConfig();
    }
  
}
function myPost(button) {
   if (!button.getAttribute('disabled')){
       let elements = Array.from(document.querySelectorAll("span[draggable]")).filter(element =>(element.style.length > 0 
                                                                                             || (element.parentElement && element.parentElement.style.length > 0)));
       let elementInfos = elements.map(element =>createInfo(element))
       let lineInfos = Array.from(document.getElementsByClassName('lineManuallyChanged')).map(element =>createStyleObject(element));
       let data = elementInfos.concat(lineInfos);
       let filename = document.getElementById(FILENAME);
       if (filename && data.length > 0) {
            let file = filename.value;   
            let xhr = new XMLHttpRequest()
            xhr.open('POST', "/exist/restxq/save", true)
            xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
            xhr.send("file=" + file + "&elements=" + JSON.stringify(data));
            xhr.onload = function () {
               undoStack = [];
               location.href = '/exist/restxq/transform?file=' + file
            }
       }
   } 
}
var currentItems = [];
var currentItem = null;
var offset =  1;
var modOffset =  10;
var clickOffset = 10;

function clickItem(item, event){
    if (!runsOnBakFile){
        event.stopPropagation();
        if (modifierPressed){
            if (shiftPressed){
                item.classList.add("selected")
                currentItems.push(item)
                if (currentItem){
                    currentItems.push(currentItem);
                    currentItem = null;
                }
            }else{
                currentItem = item;
                currentItem.classList.add("selected");
                let classList = Array.from(currentItem.classList)
                if (document.getElementById('toggleOffset') && Number(document.getElementById('toggleOffset').value)) {
                    clickOffset = Number(document.getElementById('toggleOffset').value);
                }
                let currentOffset =  ((currentItem.parentElement.className.includes('below') && !classList.includes('clicked')) || classList.includes('clicked')) ? clickOffset : clickOffset*-1;
                if (!classList.includes('clicked')){
                    currentItem.classList.add('clicked');    
                } else {
                    currentItem.classList.remove('clicked');    
                }
                repositionElement(currentItem, 0, currentOffset, false);
                
            }
        } else {
            currentItems.forEach(selected =>selected.classList.remove("selected"))
            currentItems = [];
            if (currentItem){
                currentItem.classList.remove("selected");    
            }
            if (currentItem === item){
                currentItem = null;   
            } else {
                currentItem = item;
                currentItem.classList.add("selected");
            }
        }
    }
}
var modifierPressed = false;
var shiftPressed = false;

document.onkeyup = function(e) {
  if (e.key == 'Shift' || e.key == 'Control') {
    modifierPressed = false;
    if (e.key == 'Shift'){
        shiftPressed = false;
    }
  }
};

document.onkeydown = checkKey;

function checkKey(e) {
    if (!runsOnBakFile){
        e = e || window.event;
        if (redoStack.length > 0){
            e.preventDefault();    
        }
        if(e.getModifierState(e.key)){
            modifierPressed = true; 
            shiftPressed = (e.key == 'Shift');
            
        }
        if (modifierPressed && (e.key == 'z' || e.key == 'r')){
            let execFunction = (e.key == 'z') ? undo : redo;
            execFunction();
        } else {
            let selectedElements = Array.from(document.getElementsByClassName('selected'));
            if (selectedElements.length > 0){
                e.preventDefault();
                if (document.getElementById('offset') && Number(document.getElementById('offset').value)) {
                    offset = Number(document.getElementById('offset').value);
                }
                if (document.getElementById('modOffset') && Number(document.getElementById('modOffset').value)) {
                    modOffset = Number(document.getElementById('modOffset').value);
                }
                selectedElements.forEach(item =>{
                    let currentOffset = (modifierPressed) ? modOffset : offset;
                    if (e.keyCode == '38') {
                        repositionElement(item, 0, currentOffset*-1, false)
                        // up arrow
                    }
                    else if (e.keyCode == '40') {
                        repositionElement(item, 0, currentOffset, false)
                        // down arrow
                    }
                    else if (e.keyCode == '37') {
                       // left arrow
                       repositionElement(item, currentOffset*-1, 0, false);
                    }
                    else if (e.keyCode == '39') {
                       // right arrow
                       repositionElement(item, currentOffset, 0, false);
                    }
                    else if (e.key == 'Enter'){
                        item.classList.remove("selected");
                        currentItem = null;
                    }
                });
            }
        }
    }
}
function recordChange(currentElement, offsetX, offsetY, isRedoing){
   let change = new Change(currentElement, offsetX, offsetY);
   let currentStack = (isRedoing) ? redoStack : undoStack;
   currentStack.push(change);
}
function handleButtons(){
    let onChangeActiveButtons = [ document.getElementById('undoButton'), document.getElementById('saveButton') ];
    let onChangeDisabledButtons = [  document.getElementById('editButton'),  document.getElementById('exportButton'), document.getElementById('versionButton')];
    let redoButton = document.getElementById('redoButton');
    onChangeActiveButtons.forEach(button =>{
       setDisabledStatus(button, (undoStack.length == 0))
    });
    onChangeDisabledButtons.forEach(button =>{
        setDisabledStatus(button, !(undoStack.length == 0))
    });
    setDisabledStatus(redoButton, (redoStack.length == 0))
}
function setDisabledStatus(button, disable){
    if(!button.getAttribute('disabled') && disable){
        button.setAttribute('disabled','true');
        button.classList.remove('active');
    }    
    if(button.getAttribute('disabled') && !disable){
        button.removeAttribute('disabled');
        button.classList.add('active');
    }
}

function repositionElement(currentElement, offsetX, offsetY, isRedoing){
    recordChange(currentElement, offsetX, offsetY, isRedoing);
    handleButtons();
    let oldLeft = (currentElement.style.left) ? Number(currentElement.style.left.replace('px','')) : currentElement.offsetLeft;
    currentElement.style.left = (oldLeft + offsetX) + 'px';
    if(currentElement.parentElement.className.includes('Ez')) {
        if (currentElement.parentElement.className.includes('below')){
            let oldHeight =  (currentElement.parentElement.style.height) ? Number(currentElement.parentElement.style.height.replace('px','')) : currentElement.parentElement.offsetHeight;
            let newHeight = oldHeight + offsetY;
            currentElement.parentElement.style.height = newHeight + "px";
            currentElement.style.top = (currentElement.offsetTop + offsetY) + "px";
        } else {
            let oldTop = Number(currentElement.parentElement.style.top.replace('px',''));
            if (offsetY == 0 && !currentElement.parentElement.style.top){
                oldTop = -2    
            }
            let newTop = oldTop + offsetY;
            currentElement.parentElement.style.top = newTop + "px";
            currentElement.parentElement.style.height = ((currentElement.parentElement.offsetHeight-2) + newTop*-1) + "px";
        }
    } else {
        let oldTop = (currentElement.style.top) ? Number(currentElement.style.top.replace('px','')) : currentElement.offsetTop;
        currentElement.style.top = (oldTop + offsetY) + "px";
    }
}

var dragStartPosX = null;
var dragStartPosY = null;


window.addEventListener("dragenter", (event) => { event.preventDefault(); });
window.addEventListener("dragover", (event) => { event.preventDefault(); });

window.addEventListener( 'dragstart', (event) => {
   if (event && !runsOnBakFile){
      dragStartPosX = event.clientX;
      dragStartPosY = event.clientY;
      event.dataTransfer.effectAllowed = "move";
      event.dataTransfer.setData("text/plain", event.target.id);
   }
});

window.addEventListener( 'dragend', (event) => {
   if (event && !runsOnBakFile){
      let dragEndPosX = dragStartPosX - event.clientX;
      let dragEndPosY = dragStartPosY - event.clientY;
      repositionElement(event.target, dragEndPosX*-1, dragEndPosY*-1, false);
      event.preventDefault();
   }
});
window.onbeforeunload = function(event){
    if (undoStack.length > 0){
        return confirm("Confirm refresh");
    }
};
window.addEventListener("load", (event) => {
    let versions = document.getElementById(VERSIONS);
    if(versions){
        if (versions.elements.file == undefined){
           let button = document.getElementById('versionButton')
            setDisabledStatus(button, true);     
        }    
    }
  runsOnBakFile = window.location.search.replace('?file=', '').startsWith('bak/');
  if (runsOnBakFile){
      let button = document.getElementById('versionButton')
      checkVersions(button);
      setDisabledStatus(button, true);
  }
  let newest = document.getElementById(NEWEST);
  if (newest){
      
    let checkNewest = (location.search && location.search.includes('newest=')) ? location.search.includes('newest=true') : true;  
    //newest.style.setProperty('checked', String(checkNewest));
    if (checkNewest) {
        newest.setAttribute('checked', 'true');
    } else {
        newest.removeAttribute('checked');    
    }
    console.log('checked', String(checkNewest));
  }
});
document.addEventListener("visibilitychange", (event) =>{
    if (document.visibilityState != 'visible' && fileIsOpenedInEditor){
        console.log('file opended')    
    }
    if (document.visibilityState == 'visible' && fileIsOpenedInEditor){
        window.location.reload(true);    
    }
});

