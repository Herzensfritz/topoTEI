function initWebcomponents(){
    if (typeof topoTEIObject == 'undefined') {
       topoTEIObject = {};
    }
    toggleListener = document.querySelector('toggle-listener');
    topoTEIObject.history = new History();
    const valueHandler = new ValueHandler(topoTEIObject.history);
    topoTEIObject.positioner = new Positioner(valueHandler, topoTEIObject.history);
    const positionInfoElement = document.querySelector('position-info');
    topoTEIObject.positionInfoFeeder = new PositionInfoFeeder(getElementLeft, getElementTop, positionInfoElement); 
    const logger = new InputLogger();
    const keyStorage = { modifierPressed: false, shiftPressed: false };
    topoTEIObject.keyInputHandler = new KeyInputHandler(logger, keyStorage,  topoTEIObject.history, topoTEIObject.positioner);
    toggleListener.keyListener = function (e){
        if (!topoTEIObject.runsOnBakFile){
            topoTEIObject.keyInputHandler.checkKey(e);   
        }
    };
    topoTEIObject.mouseInputHandler = new MouseInputHandler(logger, keyStorage, topoTEIObject.positioner);
    topoTEIObject.pixelLineHeight = getComputedFontSize(document.body);
    topoTEIObject.sender = new Sender(topoTEIObject.filename, topoTEIObject.history);
    topoTEIObject.runsOnBakFile = window.location.search.replace('?file=', '').startsWith('bak/');
    let versions = document.getElementById(VERSIONS);
    if(versions){
        if (versions.elements.file == undefined){
           let button = document.getElementById('versionButton');
            setDisabledStatus(button, true);     
        }    
    }
    if (topoTEIObject.runsOnBakFile){
      let button = document.getElementById('versionButton');
      checkVersions(button);
      setDisabledStatus(button, true);
    }
    if (localStorage.getItem('topoTEI.zoom')){
        topoTEIObject.pixelLineHeight = Number(localStorage.getItem('topoTEI.zoom')); 
        updateZoom();
    }
}

document.onkeyup = function(e) {
    topoTEIObject.keyInputHandler.keyUp(e);
};

window.onload = function() {
    if(window.location.hash == '#reload') {
        console.log('reloading .........');
        history.replaceState(null, null, ' ');
        window.location.reload(true);
    }
}; 




function hideOtherInputs(ids){
    const idsList = Array.isArray(ids) ? ids :  [ids];
    Array.from(document.getElementsByClassName('input')).filter(input =>!ids.includes(input.id)).forEach(input =>{
        input.style.visibility = 'hidden';
        if (input.hideChildren){
            input.hideChildren();    
        }
    });
}

function getElementTop(currentElement){
    const currentFontSize = getComputedFontSize(currentElement);    
    const parentFontSize = getComputedFontSize(currentElement.parentElement);
    if (currentElement.className.includes('below') || currentElement.parentElement.className.search(INSERTION_MARK_REGEX) == -1 ) {
        return (currentElement.style.top) ? saveReplaceLength(currentElement.style.top, currentFontSize) : currentElement.offsetTop/currentFontSize;    
    }else {
        return (currentElement.parentElement.style.top) ? saveReplaceLength(currentElement.parentElement.style.top, parentFontSize)  : 
            (currentElement.parentElement.offsetTop-currentElement.parentElement.parentElement.offsetTop)/parentFontSize;
    }
    
}
function getComputedStyleAsEm(currentElement, currentFontSize, style){
    return Number(window.getComputedStyle(currentElement, null).getPropertyValue(style).replace('px',''))/currentFontSize    
}
function getElementLeft(currentElement){
    const currentFontSize = getComputedFontSize(currentElement); 
    const style = (currentElement.className.includes(MARGIN_LEFT)) ? 'margin-left' : 'left';
    return (currentElement.style[style]) ? saveReplaceLength(currentElement.style[style], currentFontSize) :  getComputedStyleAsEm(currentElement, currentFontSize, style);
}

function clickItem(item, event){
    if (!topoTEIObject.runsOnBakFile){
        topoTEIObject.mouseInputHandler.clickItem(item, event);
    }
}

function handleChange(event) {
      const valueChanged = event.target.readChangedValues;
      const item = document.getElementById(valueChanged.id);
      switch (valueChanged.action) {
         case 'click':
            clickItem(item, new Event('position-info-click'));
            break;
         case 'left':
            topoTEIObject.positioner.move(item, valueChanged, true);
            break;
         case 'top':
            topoTEIObject.positioner.move(item, valueChanged, false);
            break;
         case 'zIndex':
            item.style.zIndex = valueChanged.value; 
            break;
         default:
            console.log(valueChanged, item);
    }
}
function positionInfo(caller){
    if (!topoTEIObject.runsOnBakFile){
        topoTEIObject.positionInfoFeeder.feedData(topoTEIObject.pixelLineHeight);
        const idList = (topoTEIObject.positionInfoFeeder.hasAddLines) ? [POSITION_INFO, LINE_INPUT] : [POSITION_INFO];
        hideOtherInputs(idList);
        const positionInfo = document.getElementById(POSITION_INFO)
        if ((!positionInfo.style || !positionInfo.style.left || !positionInfo.style.top) && localStorage.getItem(POSITION_INFO)) {
            const style = JSON.parse(localStorage.getItem(POSITION_INFO))
            positionInfo.style.left = style.left;
            positionInfo.style.top = style.top;
        }
        if (positionInfo.classList.contains(VALUE_CHANGED)){
            positionInfo.classList.remove(VALUE_CHANGED);
            const style = { left: positionInfo.style.left, top: positionInfo.style.top}
            localStorage.setItem(POSITION_INFO, JSON.stringify(style));
        }
        if (caller && topoTEIObject.positionInfoFeeder.hasAddLines){
            if (caller.closest("div.zoneLine")){
                const targetLnr = caller.closest("div.zoneLine").getElementsByClassName("zlnr")[0];
                const paramName = (targetLnr.dataset.paramName);
                showLinePositionDialog(targetLnr, paramName, true);
            } 
        }
    }     
}

function showLinePositionDialog(element, paramName, alwaysOn){
    if (!topoTEIObject.runsOnBakFile){
        let input = document.getElementById(LINE_INPUT);
        hideOtherInputs([LINE_INPUT, POSITION_INFO]);
        let id = element.parentElement.id;
        let lineInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == LINE_POSITION)[0];
        let verticalInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == VERTICAL_POSITION)[0];
        const zIndexInput =  Array.from(input.lastElementChild.children).filter(child =>child.id == ZINDEX)[0];
        const zone = element.closest('div.zoneLine');
        zIndexInput.value = window.getComputedStyle(zone, null).getPropertyValue('z-index');
        zIndexInput.setAttribute('data-id', zone.id);
        if (!alwaysOn && lineInput.dataset.id == id){
           lineInput.removeAttribute('data-id');
           input.style.visibility = 'hidden';
        } else {
           if (!alwaysOn){
                removeSelection();
                element.nextSibling.classList.add("selected");
           }
           lineInput.setAttribute('data-param', paramName);
           setInputValue(lineInput, element.parentElement.style[paramName], id, false);
           input.firstElementChild.innerText = "Position für Zeile " + element.innerText;  
           let label = Array.from(input.lastElementChild.children).filter(child =>child.id == 'param')[0];
           label.innerText = paramName;
           const fontSize = getComputedFontSize(element.nextSibling);
           let style = (element.nextSibling.style[verticalInput.dataset.param]) ? element.nextSibling.style[verticalInput.dataset.param] :  element.nextSibling.offsetLeft/fontSize + 'em';
           setInputValue(verticalInput, style, element.nextSibling.id, false);
           input.style.visibility = 'visible';
           if(element.nextSibling.querySelectorAll('.above, .below').length > 0){
                positionInfo();   
           }
        }
    }
}
function removeSelection(){
    Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"))
}
function showTextBlockDialog(textBlockId){
     if (!topoTEIObject.runsOnBakFile){
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

function handleButtons(){
    let onChangeActiveButtons = [ document.getElementById('undoButton'), document.getElementById('saveButton') ];
    //let onChangeDisabledButtons = [  document.getElementById('editButton'),  document.getElementById('exportButton'), document.getElementById('versionButton')];
    let onChangeDisabledButtons = [  document.getElementById('exportButton'), document.getElementById('versionButton')];
    let redoButton = document.getElementById('redoButton');
    onChangeActiveButtons.forEach(button =>{
       setDisabledStatus(button, (!topoTEIObject.history.canUndo))
    });
    onChangeDisabledButtons.forEach(button =>{
        setDisabledStatus(button, (topoTEIObject.history.canUndo))
    });
    setDisabledStatus(redoButton, (!topoTEIObject.history.canRedo))
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

function getAncestorWithClassName(element, className){
    if (element.parentElement){
        return (element.parentElement.classList.contains(className)) ? element.parentElement : getAncestorWithClassName(element.parentElement, className);     
    } 
    return null;
}


window.addEventListener("dragenter", (event) => { event.preventDefault(); });
window.addEventListener("dragover", (event) => { event.preventDefault(); });

window.addEventListener( 'dragstart', (event) => {
   if (event && !topoTEIObject.runsOnBakFile){
        topoTEIObject.mouseInputHandler.dragStart(event);
   }
});

window.addEventListener( 'dragend', (event) => {
   if (event && !topoTEIObject.runsOnBakFile){
       topoTEIObject.mouseInputHandler.dragEnd(event);
   }
});
window.onbeforeunload = function(event){
    if (topoTEIObject.history.canUndo){
        return confirm("Confirm refresh");
    }
};


