/** 
**/
const OBJ_PARAMS = [{targetName: 'id', dataName: 'data-id'}, 
                    {targetName: 'isClass', dataName: 'data-is-class', type: 'boolean'}, 
                    {targetName: 'paramName', dataName: 'data-param'}, 
                    {targetName: 'unit', dataName: 'data-unit'}];

var runsOnBakFile = false;
var NEWEST = "newest";
var FILENAME = 'filename';
var VERSIONS = 'versions';
var MARGIN_LEFT = 'marginLeft';
var VALUE_CHANGED = 'valueChanged';
var TEXT_BLOCK = 'textBlock';
var TEXT_BLOCK_INPUT = 'textBlockInput';
var LINE_INPUT = 'lineInput';
var LINE_POSITION = 'linePosition';
var VERTICAL_POSITION = 'verticalPosition';
var LINE_HEIGHT_INPUT = 'lineHeightInput';
var PAGE_SETUP = 'pageSetup';
var PAGE_WIDTH = 'pageWidth';
var PADDING_TOP = 'paddingTop';
var PADDING_BOTTOM = 'paddingBottom';
var POSITION_INFO = 'myPositionInfo';
var POSITION_FORM = 'addPositionForm'
var POSITION_CLASS = 'positionClass';
var TEXT_BLOCK_INPUTS = [ PADDING_TOP, PADDING_BOTTOM, LINE_HEIGHT_INPUT];
var TRANSCRIPTION_FIELD = 'transkriptionField';
var LINE = 'line';
var ZINDEX = 'zindex'
var ZONE_LINE = 'zoneLine';
const INSERTION_MARK_REGEX = /[A-Za-z]+insertion-(above|below)/g;
var pixelLineHeight = 16;
var fileIsOpenedInEditor = false;
var undoStack = [];
var redoStack = [];


var currentItems = [];
var currentItem = null;
var offset =  1;
var modOffset =  10;
var clickOffset = 10;
var showAbsolutePosition = true;
var modifierPressed = false;
var shiftPressed = false;




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
function setZindex(input, value){
    const id = input.dataset.id
    const zone = document.getElementById(id)
    zone.style.zIndex = value;
}
function setNewValue(input, isRedoing){
    if(!isRedoing && input.dataset.function){
        window[input.dataset.function]();  
        input.closest('div.input').style.visibility = 'visible';
    }
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
    if (element.inputMap && Object.hasOwn(element.inputMap,paramObject.paramName)) {
        element.inputMap[paramObject.paramName].value = newValue; 
        element.inputMap[paramObject.paramName].setAttribute('title', paramObject.paramName + ': ' + newValue);
    }
}
function getStyleFromElement(element, targetArray){
    let length = (element.dataset.index) ? Number(element.dataset.index) : 0;
    let style = '';
    for (const value of Object.values(element.style)) {
        style = style + value + ':' + element.style[value] + ';';
    }
    targetArray.push({id: element.id, style: style});
}
function setInputValue(input, styleValue, id, isClass){
    if (styleValue) {
        input.value = saveReplaceLength(styleValue, pixelLineHeight) 
    }
    input.setAttribute('data-is-class', String(isClass));
    input.setAttribute('data-id', id);
}
function noEnter(input){
     setNewValue(input);
    
     return !(window.event && window.event.keyCode == 13);
}
function hideOtherInputs(ids){
    const idsList = Array.isArray(ids) ? ids :  [ids];
    Array.from(document.getElementsByClassName('input')).filter(input =>!ids.includes(input.id)).forEach(input =>{
        input.style.visibility = 'hidden';
        if (input.hideChildren){
            input.hideChildren()    
        }
    });
}
function deselect(item){
    console.log(item);    
}
function getElementTop(currentElement){
    const currentFontSize = getComputedFontSize(currentElement)    
    const parentFontSize = getComputedFontSize(currentElement.parentElement)
    if (currentElement.className.includes('below') || currentElement.parentElement.className.search(INSERTION_MARK_REGEX) == -1 ) {
        return (currentElement.style.top) ? saveReplaceLength(currentElement.style.top, currentFontSize) : currentElement.offsetTop/currentFontSize;    
    }else {
        return (currentElement.parentElement.style.top) ? saveReplaceLength(currentElement.parentElement.style.top, parentFontSize)  : 
            (currentElement.parentElement.offsetTop-currentElement.parentElement.parentElement.offsetTop)/parentFontSize;
    }
    
}
function getElementLeft(currentElement){
    const currentFontSize = getComputedFontSize(currentElement)    
    return (currentElement.style.left) ? saveReplaceLength(currentElement.style.left, currentFontSize) : currentElement.offsetLeft/currentFontSize; 
}
function addInput(item, parent, copyObject){
  const currentFontSize = getComputedFontSize(item);
  let itemDiv = document.createElement('span');
  let newField = document.createElement('input');
  newField.setAttribute('type','checkbox');
  if (item.classList.contains('selected')) {
    newField.setAttribute('checked', true);
  } else {
     newField.removeAttribute('checked');
  }
  itemDiv.appendChild(newField)
  
  let textSpan = document.createElement('input');
  textSpan.setAttribute('type','text');
  textSpan.setAttribute('size', 10);
  textSpan.setAttribute('readonly', true);
  textSpan.value =  item.innerText;
  textSpan.setAttribute('title', item.innerText + ' (font-size: ' + currentFontSize + 'px, global: ' + kk+ 'px)');
  let topInput = document.createElement('input');
  
  topInput.setAttribute('type', 'number');
  topInput.setAttribute('size', 8);
  topInput.ondblclick = function (event) {
      if (copyObject){
        copyObject.field.value = topInput.value; 
        copyObject.label.innerText = 'top: '
        copyObject.parent.style.visibility = 'visible';
      }
 }
  
  topInput.value = getElementTop(item, currentFontSize);
  topInput.setAttribute('title', 'top: ' + topInput.value);
   let leftInput = document.createElement('input');
  
  leftInput.setAttribute('type', 'number');
  leftInput.setAttribute('size', 8);
  leftInput.value = getElementLeft(item, currentFontSize);
  leftInput.setAttribute('title', 'left: ' + leftInput.value);
  leftInput.ondblclick = function (event) {
      if (copyObject){
        copyObject.field.value = leftInput.value; 
        copyObject.label.innerText = 'left: '
        copyObject.parent.style.visibility = 'visible';
      }
 }
  let zIndexInput = document.createElement('input');
  zIndexInput.setAttribute('type', 'number');
  zIndexInput.setAttribute('size', 2);
  zIndexInput.setAttribute('min', 0);
  zIndexInput.setAttribute('title','Mit dem z-index kann beinflusst werden, ob ein Element andere Elemente überlagert. Elemente mit höherem z-index überlagern Elemente mit kleinerem z-index.')
  zIndexInput.value = window.getComputedStyle(item, null).getPropertyValue('z-index')
  zIndexInput.onchange = function() {
        item.style.zIndex = zIndexInput.value;  
  }
  itemDiv.appendChild(textSpan);
  itemDiv.appendChild(topInput);
  itemDiv.appendChild(leftInput);
  itemDiv.appendChild(zIndexInput);
  newField.onchange = function(event) {
        clickItem(item, event)    
  };
  item.inputMap = { top: topInput, left: leftInput};
  parent.appendChild(itemDiv);
}
function toggleAbsolutePositions(output) {
    showAbsolutePosition = (output == 'absolut');   
    positionInfo();
}
function addLine(line, form, lnrClass){
    let mainDiv = document.createElement('div');
    mainDiv.setAttribute('class', POSITION_CLASS)
    let heading = document.createElement('h3');
    const lnr = line.getElementsByClassName(lnrClass)[0];
    heading.innerText = 'Zeile ' + lnr.innerText;
    mainDiv.appendChild(heading);
    let copySpan = document.createElement('span');
    let copyLabel = document.createElement('label');
    copyLabel.innerText = 'label'
    let copyField = document.createElement('input');
    copyField.setAttribute('size', 10)
    copyField.setAttribute('type', 'number');
    copyField.setAttribute('step', '0.1');
    let copyButton = document.createElement('button');
    copyButton.innerText = 'setzen';
    copyButton.onclick = function(event) {
        let isTop = copyLabel.innerText.startsWith('top')
        
        if (currentItem){
            let currentFont = getComputedFontSize(currentItem)
            let currentPos = (isTop) ? getElementTop(currentItem, currentFont) : getElementLeft(currentItem, currentFont)
            let offset = (showAbsolutePosition) ? (copyField.value - currentPos)/currentFont : copyField.value - currentPos
            if (isTop) {
                repositionElement(currentItem, 0, offset, false)
            } else {
                repositionElement(currentItem, offset, 0, false)
            }
        } else {
            currentItems.forEach(item =>{
                let currentFont = getComputedFontSize(item)
                let currentPos = (isTop) ? getElementTop(item, currentFont) : getElementLeft(item, currentFont)
                let offset = (showAbsolutePosition) ? (copyField.value - currentPos)/currentFont : copyField.value - currentPos
                if (isTop) {
                repositionElement(item, 0, offset, false)
            } else {
                repositionElement(item, offset, 0, false)
            }    
            })    
        }    
        positionInfo();
    }
    copySpan.append(copyLabel);
    copySpan.append(copyField);
    copySpan.append(copyButton);
    //copySpan.style.visibility = 'hidden'
    let copyObject = {label: copyLabel, field: copyField, parent: copySpan}
    Array.from(line.getElementsByClassName('above')).forEach(item =>{
        addInput(item, mainDiv, copyObject)    
    })
    Array.from(line.getElementsByClassName('below')).forEach(item =>{
        addInput(item, mainDiv, copyObject)    
    })
    mainDiv.append(copySpan)
    form.appendChild(mainDiv);
    
}
function addExtra(extras, title, form){
    let mainDiv = document.createElement('div');
    mainDiv.setAttribute('class', POSITION_CLASS)
    let heading = document.createElement('h3');
    heading.innerText = title;
    mainDiv.appendChild(heading);
    extras.forEach(item =>{
        addInput(item, mainDiv)    
    })
    form.appendChild(mainDiv);
    
}
function positionInfo(caller){
    if (!runsOnBakFile){
        let positionInfoElement = document.getElementById(POSITION_INFO);
        positionInfoElement.reset();
        positionInfoElement.defaultFontSize = pixelLineHeight;
        const selected = Array.from(document.getElementsByClassName('selected')).filter(item =>item.closest('div.line')).map(item =>item.closest("div.line"));
        const selectedLines = Array.from(new Set(selected))
        const selectedFws = Array.from(document.getElementsByClassName('selected')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('fw')).length > 0))
        const selectedNotes = Array.from(document.getElementsByClassName('selected')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('note')).length > 0))
        if (selectedLines.length > 0){
           selectedLines.forEach(line  =>{
               const lnr = line.getElementsByClassName('lnr')[0];
               const title = 'Zeile ' + lnr.innerText;
               const items = Array.from(line.querySelectorAll('.above, .below'))
               const itemObject = {title: title, items: items, left: getElementLeft, top: getElementTop}
               positionInfoElement.appendItem(itemObject)
            });
            
        }
        /*
        const selectedAdd = Array.from(document.getElementsByClassName('selected')).filter(item =>
            (item.closest('div.zoneLine') && item.closest('div.zoneLine').querySelectorAll('.above, .below').length > 0)
        ).map(item =>item.closest("div.zoneLine"));
        const selectedAddLines = Array.from(new Set(selectedAdd))
        if (selectedAddLines.length > 0){
           selectedAddLines.forEach(line  =>{
               addLine(line, rootForm, 'zlnr')
            });
        }
        if (selectedFws.length > 0){
            const fws = Array.from(document.querySelectorAll('*[draggable]')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('fw')).length > 0))
            addExtra(fws, 'FW:', rootForm)       
        }
        if (selectedNotes.length > 0){
            const notes = Array.from(document.querySelectorAll('*[draggable]')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('note')).length > 0))
            addExtra(notes, 'Notes:', rootForm)       
        }
        positionInfoElement.style.visibility = (selectedLines.length > 0 || selectedAddLines.length > 0 || selectedFws.length > 0 || selectedNotes.length > 0) ? 'visible' : 'hidden';
        const idList = (selectedAddLines.length > 0) ? [POSITION_INFO, LINE_INPUT] : [POSITION_INFO];
        */
        if (selectedLines.length > 0) {
            positionInfoElement.style.visibility = 'visible';
        } else {
            positionInfoElement.style.visibility = 'hidden';
            positionInfoElement.hideChildren();
        }
        
        hideOtherInputs([POSITION_INFO]);
        /*if (caller && selectedAddLines.length > 0){
            if (caller.target.closest("div.zoneLine")){
                const targetLnr = caller.target.closest("div.zoneLine").getElementsByClassName("zlnr")[0] 
                const paramName = (targetLnr.dataset.paramName);
                showLinePositionDialog(targetLnr, paramName, true)
            } 
        }*/
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
function showLinePositionDialog(element, paramName, alwaysOn){
    if (!runsOnBakFile){
        let input = document.getElementById(LINE_INPUT);
        hideOtherInputs([LINE_INPUT, POSITION_INFO]);
        let id = element.parentElement.id;
        let lineInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == LINE_POSITION)[0];
        let verticalInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == VERTICAL_POSITION)[0];
        const zIndexInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == ZINDEX)[0];
        const zone = element.closest('div.zoneLine')
        zIndexInput.value = window.getComputedStyle(zone, null).getPropertyValue('z-index')
        zIndexInput.setAttribute('data-id', zone.id)
        if (!alwaysOn && lineInput.dataset.id == id){
           lineInput.removeAttribute('data-id');
           input.style.visibility = 'hidden';
        } else {
           if (!alwaysOn){
                removeSelection();
                currentItem = element.nextSibling;
                currentItem.classList.add("selected");
           }
           lineInput.setAttribute('data-param', paramName);
           setInputValue(lineInput, element.parentElement.style[paramName], id, false);
           input.firstElementChild.innerText = "Position für Zeile " + element.innerText;  
           let label = Array.from(input.lastElementChild.children).filter(child =>child.id == 'param')[0];
           label.innerText = paramName;
           const fontSize = getComputedFontSize(element.nextSibling)
           let style = (element.nextSibling.style[verticalInput.dataset.param]) ? element.nextSibling.style[verticalInput.dataset.param] :  element.nextSibling.offsetLeft/fontSize + 'em';
           setInputValue(verticalInput, style, element.nextSibling.id, false);
           input.style.visibility = 'visible';
           if(element.nextSibling.querySelectorAll('.above, .below').length > 0){
                positionInfo()    
           }
        }
    }
}
function removeSelection(){
    currentItems.forEach(selected =>selected.classList.remove("selected"))
    currentItems = [];
    if (currentItem){
        currentItem.classList.remove("selected");    
    }   
}
function showTextBlockDialog(textBlockId){
     if (!runsOnBakFile){
        let input = document.getElementById(TEXT_BLOCK_INPUT);
        hideOtherInputs(input.id);
        removeSelection();
        let inputs =  Array.from(input.lastElementChild.children).filter(child =>TEXT_BLOCK_INPUTS.includes(child.id));
        let firstLine = Array.from(document.getElementsByClassName(LINE))[0];
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
function toggleConfig(){
    let config = document.getElementById("editorInput"); 
    config.style.visibility = (config.style.visibility == 'visible') ? 'hidden' : 'visible';
}
function createConfigObject(objectId, objectValue, targetAttr, targetTag ){
    return { id: objectId, value: String(objectValue), attr: targetAttr, tag: targetTag }    
}
function saveConfig(fontIdArray, dataNameArray) {
    
    let fontSelectors = Array.from(fontIdArray.map(id =>document.getElementById(id)));
    let fonts =  fontSelectors.map(fontSelector => createConfigObject(fontSelector.id, fontSelector.options[fontSelector.selectedIndex].text, 'family', 'current'));
   let configData = dataNameArray.map(id =>createConfigObject(id, document.getElementById(id).value, 'name', 'param'));
    let data = { font: fonts, config: configData }
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
       let elements = Array.from(document.getElementsByClassName(VALUE_CHANGED));
       let elementInfos = [];
       elements.forEach(element =>{
           getStyleFromElement(element, elementInfos)
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
            removeSelection();
            if (currentItem === item){
                currentItem = null;   
            } else {
                currentItem = item;
                currentItem.classList.add("selected");
            }
        }
        positionInfo(event);
    }
}


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
    //let onChangeDisabledButtons = [  document.getElementById('editButton'),  document.getElementById('exportButton'), document.getElementById('versionButton')];
    let onChangeDisabledButtons = [  document.getElementById('exportButton'), document.getElementById('versionButton')];
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
function getComputedFontSize(element){
    return Number(window.getComputedStyle(element, null).getPropertyValue('font-size').replace('px', ''))     
}
function saveReplaceLength(length, currentFontSize){
   
   return (length.endsWith('em')) ? Number(length.replace('em','')) : Number(length.replace('px',''))/currentFontSize
}
function repositionElement(currentElement, offsetX, offsetY, isRedoing){
    recordChange(currentElement, offsetX, offsetY, isRedoing);
    let currentFontSize = getComputedFontSize(currentElement) 
    let currentOffsetX = offsetX/currentFontSize
    handleButtons();
    if (currentElement.className.includes(MARGIN_LEFT)){
        let oldLeft = (currentElement.style.marginLeft) ? Number(currentElement.style.marginLeft.replace('em','')) : 0;
        setStyleToElement(currentElement, (oldLeft + currentOffsetX), { paramName: 'marginLeft', unit: 'em'} );
        if (offsetY != 0){
            let ancestor = getAncestorWithClassName(currentElement, ZONE_LINE);
            let size = getComputedFontSize(ancestor)
            let currentOffsetY = offsetY/size
            if (ancestor){
                if (ancestor.style['bottom']){
                    let oldBottom = Number(ancestor.style['bottom'].replace('em',''));
                    let newBottom = oldBottom + currentOffsetY*-1;
                    setStyleToElement(ancestor, newBottom, { paramName: 'bottom', unit: 'em'} );
                    showLinePositionDialog(ancestor.firstChild, 'bottom', true);
                } else {
                    let oldTop = ancestor.offsetTop;
                    let newTop = oldTop/size  + currentOffsetY;
                    setStyleToElement(ancestor, newTop, { paramName: 'top', unit: 'em'} );
                    showLinePositionDialog(ancestor.firstChild, 'top', true);
                }
            }
        } else {
              
            const targetLnr = currentElement.closest("div.zoneLine").getElementsByClassName("zlnr")[0] 
            const paramName = (targetLnr.dataset.paramName);
            showLinePositionDialog(targetLnr, paramName, true)
            
        }
    } else {
        let oldLeft = (currentElement.style.left) ? saveReplaceLength(currentElement.style.left, currentFontSize) : currentElement.offsetLeft/currentFontSize;
        setStyleToElement(currentElement, (oldLeft + currentOffsetX), { paramName: 'left', unit: 'em'} );
        let currentOffsetY = offsetY/currentFontSize
        if(currentElement.parentElement && currentElement.parentElement.className.search(INSERTION_MARK_REGEX) > -1) {
            let parentFontSize = getComputedFontSize(currentElement.parentElement) 
            if (currentElement.className.includes('below')){
                let oldHeight =  (currentElement.parentElement.style.height) ? saveReplaceLength(currentElement.parentElement.style.height, parentFontSize) : currentElement.parentElement.offsetHeight/parentFontSize;
                let newHeight = oldHeight + (offsetY/parentFontSize);
                setStyleToElement(currentElement.parentElement, newHeight, { paramName: 'height', unit: 'em'} );
                setStyleToElement(currentElement, (currentElement.offsetTop + offsetY)/currentFontSize, { paramName: 'top', unit: 'em'} );
            } else {
                let oldTop = (offsetY == 0 && !currentElement.parentElement.style.top) ? -2/parentFontSize : saveReplaceLength(currentElement.parentElement.style.top, parentFontSize);
                let newTop = oldTop + currentOffsetY;
                setStyleToElement(currentElement.parentElement, newTop, { paramName: 'top', unit: 'em'} );
                const oldHeight = currentElement.parentElement.offsetHeight/parentFontSize
                setStyleToElement(currentElement.parentElement, ((currentElement.parentElement.offsetHeight-2)/parentFontSize + newTop*-1), { paramName: 'height', unit: 'em'} );
            }
        } else {
            let oldTop = (currentElement.style.top) ? saveReplaceLength(currentElement.style.top, currentFontSize) : currentElement.offsetTop/currentFontSize;
            setStyleToElement(currentElement, (oldTop + currentOffsetY) , { paramName: 'top', unit: 'em'} );
        }
        positionInfo();
    }
}
function getAncestorWithClassName(element, className){
    if (element.parentElement){
        return (element.parentElement.classList.contains(className)) ? element.parentElement : getAncestorWithClassName(element.parentElement, className);     
    } 
    return null;
}
function zoom(zoomLink){
    const zoomValue = (zoomLink.dataset.direction == 'in') ? 1 : -1;
    pixelLineHeight = pixelLineHeight + zoomValue
    const tf = document.getElementsByClassName(TRANSCRIPTION_FIELD)[0]
    tf.style.fontSize = pixelLineHeight + 'px';
    positionInfo();
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
      let dragEndPosX = (dragStartPosX - event.clientX);
      let dragEndPosY = (dragStartPosY - event.clientY);
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
    pixelLineHeight = getComputedFontSize(document.body);
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
      
    let checkNewest = (location.search && location.search.includes('newest=')) ? location.search.includes('newest=true') : false;  
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

