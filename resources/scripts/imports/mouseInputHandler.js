class MouseInputHandler {
    constructor(inputLogger){
        this.inputLogger = inputLogger;
    }
    clickItem(item, event){
        this.inputLogger.addEvent(event, item);
        if (!runsOnBakFile){
            if (event) {
                event.stopPropagation();
            }
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
            positionInfo(item);
        }
    } 
}