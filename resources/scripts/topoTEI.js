

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
var logStack = [];


var currentItems = [];
var currentItem = null;
var offset =  1;
var modOffset =  10;
var clickOffset = 10;
var positionInfoFeeder = null;
var showAbsolutePosition = true;
var modifierPressed = false;
var shiftPressed = false;
var logger = null;
var keyInputHandler = null;
var mouseInputHandler = null;
var sender = null;

function initWebcomponents(){
    if (KeyInputHandler && PositionInfoFeeder && InputLogger && KeyInputHandler && MouseInputHandler){
        const toggleListener = document.querySelector('toggle-listener')
        const positionInfoElement = document.querySelector('position-info')
        positionInfoFeeder = new PositionInfoFeeder(getElementLeft, getElementTop, positionInfoElement); 
        logger = new InputLogger();
        keyInputHandler = new KeyInputHandler(logger);
        mouseInputHandler = new MouseInputHandler(logger);
        toggleListener.keyListener = function (e){
            keyInputHandler.checkKey(e);    
        }
        const filename = document.getElementById(FILENAME);
        sender = new Sender(filename.value);
    }
}

document.onkeyup = function(e) {
    keyInputHandler.keyUp(e);
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

function clickItem(item, event){
    this.mouseInputHandler.clickItem(item, event);
}

function handleChange(event) {
      const valueChanged = event.target.readChangedValues;
      const item = document.getElementById(valueChanged.id);
      switch (valueChanged.action) {
         case 'click':
            clickItem(item, new Event('position-info-click'));
            break;
         case 'left':
            move(item, valueChanged, true);
            break;
         case 'top':
            move(item, valueChanged, false);
            break;
         case 'zIndex':
            item.style.zIndex = valueChanged.value; 
            break;
         default:
            console.log(valueChanged, item)
    }
}
function move(item, valueChanged, onX) {
    const currentFontSize = getComputedFontSize(item);
    const newValue = (valueChanged.absoluteValue) ? (valueChanged.value - valueChanged.oldValue): (valueChanged.value - valueChanged.oldValue)*currentFontSize;
    const offsetX = (onX) ? newValue : 0;
    const offsetY = (!onX) ? newValue : 0;
    console.log(offsetX, offsetY)
    repositionElement(item, offsetX, offsetY, false);
}
function positionInfo(caller){
    if (!runsOnBakFile){
        positionInfoFeeder.feedData(pixelLineHeight);
        const idList = (positionInfoFeeder.hasAddLines) ? [POSITION_INFO, LINE_INPUT] : [POSITION_INFO];
        hideOtherInputs(idList);
        if (caller && positionInfoFeeder.hasAddLines){
            if (caller.closest("div.zoneLine")){
                const targetLnr = caller.closest("div.zoneLine").getElementsByClassName("zlnr")[0] 
                const paramName = (targetLnr.dataset.paramName);
                showLinePositionDialog(targetLnr, paramName, true)
            } 
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
        let textBlock = document.getElementById(textBlockId);
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



function createConfigObject(objectId, objectValue, targetAttr, targetTag ){
    return { id: objectId, value: String(objectValue), attr: targetAttr, tag: targetTag }    
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


var dragStartPosX = null;
var dragStartPosY = null;


window.addEventListener("dragenter", (event) => { event.preventDefault(); });
window.addEventListener("dragover", (event) => { event.preventDefault(); });

window.addEventListener( 'dragstart', (event) => {
   if (event && !runsOnBakFile){
      logger.addEvent(event);
      dragStartPosX = event.clientX;
      dragStartPosY = event.clientY;
      event.dataTransfer.effectAllowed = "move";
      event.dataTransfer.setData("text/plain", event.target.id);
   }
});

window.addEventListener( 'dragend', (event) => {
   if (event && !runsOnBakFile){
       logger.addEvent(event);
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

