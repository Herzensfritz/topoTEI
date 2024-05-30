class Positioner {
    constructor(valueHandler, history){
        this.valueHandler = valueHandler;    
        this.history = history;
        this.history.positioner = this;
    }
    move(item, valueChanged, onX) {
        const currentFontSize = getComputedFontSize(item);
        const newValue = (valueChanged.absoluteValue) ? (valueChanged.value - valueChanged.oldValue): (valueChanged.value - valueChanged.oldValue)*currentFontSize;
        const offsetX = (onX) ? newValue : 0;
        const offsetY = (!onX) ? newValue : 0;
        this.repositionElement(item, offsetX, offsetY, false);
    }
    _repositionMarginLefts(currentElement, currentOffsetX, offsetY){
        let oldLeft = (currentElement.style.marginLeft) ? Number(currentElement.style.marginLeft.replace('em','')) : 0;
        this.valueHandler.setStyleToElement(currentElement, (oldLeft + currentOffsetX), { paramName: 'marginLeft', unit: 'em'} );
        if(currentElement.closest("div.zoneLine")) {
            if (offsetY != 0){
                    let ancestor = getAncestorWithClassName(currentElement, ZONE_LINE);
                    let size = getComputedFontSize(ancestor)
                    let currentOffsetY = offsetY/size
                    if (ancestor){
                        if (ancestor.style['bottom']){
                            let oldBottom = Number(ancestor.style['bottom'].replace('em',''));
                            let newBottom = oldBottom + currentOffsetY*-1;
                            this.valueHandler.setStyleToElement(ancestor, newBottom, { paramName: 'bottom', unit: 'em'} );
                            showLinePositionDialog(ancestor.firstChild, 'bottom', true);
                        } else {
                            let oldTop = ancestor.offsetTop;
                            let newTop = oldTop/size  + currentOffsetY;
                            this.valueHandler.setStyleToElement(ancestor, newTop, { paramName: 'top', unit: 'em'} );
                            showLinePositionDialog(ancestor.firstChild, 'top', true);
                        }
                    }
            } else {
                    const targetLnr = currentElement.closest("div.zoneLine").getElementsByClassName("zlnr")[0] 
                    const paramName = (targetLnr.dataset.paramName);
                    showLinePositionDialog(targetLnr, paramName, true)
                    
            }
        } else {
            positionInfo();
        }
    }
    _repositionLeft(currentElement, currentOffsetX, offsetY, currentFontSize){
         let oldLeft = (currentElement.style.left) ? saveReplaceLength(currentElement.style.left, currentFontSize) : currentElement.offsetLeft/currentFontSize;
            this.valueHandler.setStyleToElement(currentElement, (oldLeft + currentOffsetX), { paramName: 'left', unit: 'em'} );
            let currentOffsetY = offsetY/currentFontSize
            if(currentElement.parentElement && currentElement.parentElement.className.search(INSERTION_MARK_REGEX) > -1) {
                let parentFontSize = getComputedFontSize(currentElement.parentElement) 
                if (currentElement.className.includes('below')){
                    let oldHeight =  (currentElement.parentElement.style.height) ? saveReplaceLength(currentElement.parentElement.style.height, parentFontSize) : currentElement.parentElement.offsetHeight/parentFontSize;
                    let newHeight = oldHeight + (offsetY/parentFontSize);
                    this.valueHandler.setStyleToElement(currentElement.parentElement, newHeight, { paramName: 'height', unit: 'em'} );
                    this.valueHandler.setStyleToElement(currentElement, (currentElement.offsetTop + offsetY)/currentFontSize, { paramName: 'top', unit: 'em'} );
                } else {
                    let oldTop = (!currentElement.parentElement.style.top) ? -2/parentFontSize : saveReplaceLength(currentElement.parentElement.style.top, parentFontSize);
                    let newTop = oldTop + currentOffsetY;
                    this.valueHandler.setStyleToElement(currentElement.parentElement, newTop, { paramName: 'top', unit: 'em'} );
                    const oldHeight = currentElement.parentElement.offsetHeight/parentFontSize
                    this.valueHandler.setStyleToElement(currentElement.parentElement, ((currentElement.parentElement.offsetHeight-2)/parentFontSize + newTop*-1), { paramName: 'height', unit: 'em'} );
                }
            } else {
                let oldTop = (currentElement.style.top) ? saveReplaceLength(currentElement.style.top, currentFontSize) : currentElement.offsetTop/currentFontSize;
                this.valueHandler.setStyleToElement(currentElement, (oldTop + currentOffsetY) , { paramName: 'top', unit: 'em'} );
            }
            positionInfo();
    }
    repositionElement(currentElement, offsetX, offsetY, isRedoing){
        this.history.recordChange(currentElement, offsetX, offsetY, isRedoing);
        let currentFontSize = getComputedFontSize(currentElement) 
        let currentOffsetX = offsetX/currentFontSize
        handleButtons();
        if (currentElement.className.includes(MARGIN_LEFT)){
            this._repositionMarginLefts(currentElement, currentOffsetX, offsetY);    
        } else {
            this._repositionLeft(currentElement, currentOffsetX, offsetY, currentFontSize);  
        }
    }
}