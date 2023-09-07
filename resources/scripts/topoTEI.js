/** 
**/
const OBJ_PARAMS = [{targetName: 'id', dataName: 'data-id'}, 
                    {targetName: 'isClass', dataName: 'data-is-class', type: 'boolean'}, 
                    {targetName: 'paramName', dataName: 'data-param'}, 
                    {targetName: 'cssName', dataName: 'data-css'}, 
                    {targetName: 'unit', dataName: 'data-unit'}];

var LINE_PARAM = { paramName: 'lineHeight', cssName: 'line-height'};
var runsOnBakFile = false;
var NEWEST = "newest";
var FILENAME = 'filename';
var COLLECTION = 'collection';
var DOWNLOAD_LINK = 'downloadLink';
var VERSIONS = 'versions';
var MARGIN_LEFT = 'marginLeft';
var POSITION_CHANGED = 'positionChanged';
var LINE_CHANGED = 'lineChanged';
var VALUE_CHANGED = 'valueChanged';
var ZONE_LINE = 'zoneLine';
var TEXT_BLOCK = 'textBlockInput';
var LINE_INPUT = 'lineInput';
var LINE_POSITION = 'linePosition';
var LINE_HEIGHT_INPUT = 'lineHeightInput';
var PADDING_TOP = 'paddingTop';
var PADDING_BOTTOM = 'paddingBottom';
var TEXT_BLOCK_INPUTS = [ PADDING_TOP, PADDING_BOTTOM, LINE_HEIGHT_INPUT];
var LINE = 'line';
const INSERTION_MARK_REGEX = /(insM|Ez)/g;
var fileIsOpenedInEditor = false;
var currentLine = null;
var currentInput = null;
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
    constructor(line, value, isDefault, paramName){
        this.line = line;
        this.value = value;
        this.isDefault = isDefault;
        this.paramName = paramName;
    }    
    undo(isRedoing) {
        currentLine = this.line;
        setLineHeight(this.value, this.isDefault, this.paramName, isRedoing);
    }
};
class ParamChange {
    constructor(input, oldValue){
        this.input = input;
        this.oldValue = oldValue;
    }    
    undo(isRedoing) {
        setNewValue(this.input, this.oldValue, isRedoing);
    }
};

window.onload = function() {
    if(window.location.hash == '#reload') {
        console.log('reloading .........')
        history.replaceState(null, null, ' ');
        window.location.reload(true);
    }
} 
function recordLineChange(line, isDefault, paramName, isRedoing){
    let oldValue = Number(currentLine.parentElement.style[paramName].replace('em',''));
    let change = new LineChange(line, oldValue, isDefault, paramName);    
    let currentStack = (isRedoing) ? redoStack : undoStack;
    currentStack.push(change);
}
function getObject(input, dataParams){
    const obj = {};
    dataParams.forEach(param =>{
        if(input.getAttribute(param.dataName)){
            obj[param.targetName] = (param.type == 'boolean') ? input.getAttribute(param.dataName) == 'true' : input.getAttribute(param.dataName);    
        }
    });
    return obj;
}

function recordNewValueChange(input, isRedoing){
    let inputObject = getObject(input, OBJ_PARAMS);
    let currentElement = (inputObject.isClass) ? Array.from(document.getElementsByClassName(inputObject.id))[0] : document.getElementById(inputObject.id);
    let oldValue = currentElement.style[inputObject.paramName];
    let change = new ParamChange(input, oldValue);    
    let currentStack = (isRedoing) ? redoStack : undoStack;
    currentStack.push(change);
}
function setNewValue(input, isRedoing){
    let inputObject = getObject(input, OBJ_PARAMS);
    recordNewValueChange(input, isRedoing);
    let newValue = (input.type == 'number') ? Number(input.value) : input.value;
    handleButtons();
    if (inputObject.isClass){
         Array.from(document.getElementsByClassName(inputObject.id)).forEach(element =>{
            setStyleToElement(element, newValue, inputObject)
         });
    } else {
        let element = document.getElementById(inputObject.id);
        setStyleToElement(element, newValue, inputObject);
    } 
}
function setStyleToElement(element, newValue, paramObject){
    element.style[paramObject.paramName] = newValue + paramObject.unit;
    element.classList.add(VALUE_CHANGED);
    if (element.dataset.index) {
        if (!containsValue(element, 'data-param', paramObject.paramName)){
            element.setAttribute('data-param' + element.dataset.index, paramObject.paramName);
            element.setAttribute('data-css' + element.dataset.index, paramObject.cssName);
            element.setAttribute('data-index', Number(element.dataset.index)+1);    
        }
    } else {
        element.setAttribute('data-param' + 0, paramObject.paramName);
        element.setAttribute('data-css' + 0, paramObject.cssName);
        element.setAttribute('data-index', 1);  
    }
}
function containsValue(element, param, value){
    let length = (element.dataset.index) ? element.dataset.index : 0;
    let data = [];
    for (var i = 0; i < length; i++){
        data[i] = element.getAttribute(param + i);
    }
    return data.filter(name => name == value).length > 0;
}
function getStyleFromElement(element, targetArray){
    let length = (element.dataset.index) ? Number(element.dataset.index) : 0;
    let style = '';
    for (var i = 0; i < length; i++){
        style = style + element.getAttribute('data-css' + i) + ':' + element.style[element.getAttribute('data-param' + i)] + ';';  
    }
    targetArray.push({id: element.id, style: style});
}

function setLineHeight(newValue, isDefault, paramName, isRedoing){
    recordLineChange(currentLine, isDefault, paramName, isRedoing);
    handleButtons();
    if (isDefault){
        Array.from(document.getElementsByClassName(LINE)).forEach(line =>{
            line.style.lineHeight = newValue + 'em';   
            line.classList.add(LINE_CHANGED);
        });    
    } else {
        currentLine.parentElement.style[paramName] = newValue + 'em';
        currentLine.parentElement.classList.add(LINE_CHANGED);
    }
}
function setInputValue(input, styleValue, id, isClass, label){
    if (styleValue) {
        input.value = Number(styleValue.replace(input.dataset.unit, '')) 
    }
    input.setAttribute('data-is-class', String(isClass));
    input.setAttribute('data-id', id);
}
function showLinePositionDialog(element, paramName){
    if (!runsOnBakFile){
        let input = document.getElementById(LINE_INPUT);
        let textBlock = document.getElementById(TEXT_BLOCK);
        let id = element.parentElement.id;
        let lineInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == LINE_POSITION)[0];
        if (textBlock){
            textBlock.style.visibility = 'hidden';
        }
        if (lineInput.dataset.id == id){
           lineInput.removeAttribute('data-id');
           input.style.visibility = 'hidden';
        } else {
           lineInput.setAttribute('data-param', paramName);
           lineInput.setAttribute('data-css', paramName);
           setInputValue(lineInput, element.parentElement.style[paramName], id, false);
           input.firstElementChild.innerText = "Zeilenposition für Zeile " + element.innerText;  
           let label = Array.from(input.lastElementChild.children).filter(child =>child.id == 'param')[0];
           label.innerText = paramName;
           input.style.visibility = 'visible';
        }
    }
}
function showTextBlockDialog(textBlockId){
     if (!runsOnBakFile){
        let linePosition = document.getElementById(LINE_INPUT);
        let input = document.getElementById(TEXT_BLOCK);
        let inputs =  Array.from(input.lastElementChild.children).filter(child =>TEXT_BLOCK_INPUTS.includes(child.id));
        let textBlock = document.getElementById(textBlockId);
        let firstLine = Array.from(document.getElementsByClassName(LINE))[0];
        if (linePosition){
            linePosition.style.visibility = 'hidden';
        }
        if (inputs.filter(input =>input.dataset.isClass == 'false').map(input =>input.dataset.id).includes(textBlockId)){
           inputs.filter(input =>input.dataset.isClass == 'false').forEach(input =>{ input.removeAttribute('data-id') });
           input.style.visibility = 'hidden';
        } else {
           let elements = [ firstLine, textBlock, textBlock ];
           let ids = [ LINE, textBlockId, textBlockId ];
           for (var i = 0; i < elements.length; i++){
                let paramName = inputs[i].dataset.param;
                let style = elements[i].style[paramName];
                setInputValue(inputs[i], style, ids[i], ids[i] != textBlockId);
           }
           input.style.visibility = 'visible';
        }
    }
}
function getLineHeightInput(element, id, paramName){ //DEPRECATED
    if (!runsOnBakFile){
        let input = document.getElementById(id);
        if (currentInput && currentLine && input != currentInput){
            currentInput.style.visibility = 'hidden';
           
        }
        currentInput = input;
        let lineInput =  Array.from(input.lastElementChild.children).filter(child =>child.value)[0];
        let isClass = element.parentElement.classList.contains(LINE)
        let lineInputId = (isClass) ? LINE : element.parentElement.id;
        setInputValue(lineInput, element.parentElement.style[paramName], lineInputId, isClass);
        if( currentLine === element || (currentLine && currentLine.parentElement.classList.contains(LINE) && element.parentElement.classList.contains(LINE))){
            input.style.visibility = 'hidden';
            currentLine = null;
        } else {
            currentLine = element;
            if (element.parentElement.classList.contains(ZONE_LINE)){
                input.firstElementChild.innerText = "Zeilenposition für Zeile " + element.innerText;  
                let label = Array.from(input.lastElementChild.children).filter(child =>child.id == 'param')[0];
                label.innerText = paramName;
            } else {
                let currentElement = element.parentElement.parentElement;
                let currentParams = [ PADDING_TOP.paramName, PADDING_BOTTOM.paramName ];
                currentParams.forEach(param =>{
                    let paramInput = Array.from(input.lastElementChild.children).filter(child =>child.id == param)[0];
                    paramInput.value = (currentElement.style[param]) ? Number(currentElement.style[param].replace(paramInput.dataset.unit,'')) : 0;    
                })
            }
            if (element.parentElement.style[paramName]) {
                let lineInput =  Array.from(input.lastElementChild.children).filter(child =>child.value)[0];
                //lineInput.value =  Number(element.parentElement.style[paramName].replace('em',''));
                setInputValue(lineInput, element.parentElement.style[paramName], element.parentElement.id, element.parentElement.classList.contains(LINE));
            } 
            input.style.visibility = 'visible';
        }
    }
}
function showFixLineNumberButtonIfNeeded(element){
    let lines = Array.from(document.getElementsByClassName('lnr')).filter(line =>line.innerText == element.innerText);
    if (lines.length > 1){
        let button = document.getElementById('lineInputButton');  
        button.removeAttribute('hidden');
    }
}
function fixLineNumbering(){
    let lines = Array.from(document.getElementsByClassName('lnr')).map(line =>new Object({ id: line.parentElement.id, n: line.innerText.substring(0, line.innerText.indexOf(':')) }));    
    let data = adjustLineNumbers(lines);
    mySend(data);
}
function adjustLineNumbers(lines){
    if (lines.length < 2){
        return lines    
    } else {
        if (lines[0].n == lines[1].n){
            for (var i = 1; i < lines.length; i++){
                lines[i].n = String( Number(lines[i].n) + 2);    
            }
        }
        return [lines[0]].concat(adjustLineNumbers(lines.slice(1)));
    }   
}
function saveStyleGet(element, attribute){
    return (element.style[attribute]) ? element.style[attribute] : "0px";   
}
function createAddPositionInfo (element, isChild, targetArray){
    if (isChild){
        let style = (element.className.includes('below') 
        || !(element.parentElement && element.parentElement.className.search(INSERTION_MARK_REGEX) > -1)) 
        ? "left:" + saveStyleGet(element, 'left') + "; top:" + saveStyleGet(element, 'top') 
        : "left:" + saveStyleGet(element, 'left');
        targetArray.push({id: element.id, style: style});
        if (element.parentElement && element.parentElement.className.search(INSERTION_MARK_REGEX) > -1){
            createAddPositionInfo(element.parentElement, false, targetArray)    
        }
    } else {
        let style = (element.className.includes('below')) ? "height:" + saveStyleGet(element.parentElement, 'height') : "top:" + saveStyleGet(element, 'top') + "; height:" + saveStyleGet(element, 'height');
        targetArray.push({id: element.id, style: style});
    }
}
function createInfo (element, targetArray){
    if (element.className.includes(MARGIN_LEFT)){
        let style = "margin-left:" + element.style.marginLeft;
        targetArray.push({id: element.id, style: style});
    } else {
        createAddPositionInfo(element, true, targetArray);    
    }  
}
function createLineInfo (element, targetArray){
    if (element.classList.contains(LINE)){
        let style = 'line-height:' + element.style.lineHeight;
        targetArray.push({id: element.id, style: style});
    } else {
        let style = (element.style.bottom) ? 'bottom:' + element.style.bottom : 'top:' + element.style.top; 
        targetArray.push({id: element.id, style: style});
    } 
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
       let elements = Array.from(document.querySelectorAll("*[draggable]")).filter(element =>element.classList.contains(POSITION_CHANGED)); 
       let elementInfos = [];
       elements.forEach(element =>{
           createInfo(element, elementInfos)
        });
       Array.from(document.getElementsByClassName(LINE_CHANGED)).forEach(line =>{
            createLineInfo(line, elementInfos)   
        });
        mySend(elementInfos);
   } 
}
function mySend(data){
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
   if (!currentElement.classList.contains(POSITION_CHANGED)){
        currentElement.classList.add(POSITION_CHANGED);    
   }
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
    if (currentElement.className.includes(MARGIN_LEFT)){
        let oldLeft = (currentElement.style.marginLeft) ? Number(currentElement.style.marginLeft.replace('px','')) : currentElement.offsetLeft;
        currentElement.style.marginLeft = (oldLeft + offsetX) + 'px';
    } else {
        let oldLeft = (currentElement.style.left) ? Number(currentElement.style.left.replace('px','')) : currentElement.offsetLeft;
        currentElement.style.left = (oldLeft + offsetX) + 'px';
        if(currentElement.parentElement && currentElement.parentElement.className.search(INSERTION_MARK_REGEX) > -1) {
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

