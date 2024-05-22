class KeyInputHandler {
    constructor(inputLogger){
        this.inputLogger = inputLogger;
        this.modifierKeyCode = -1;
    }
    keyUp(e) {
        if (e.keyCode == this.modifierKeyCode) {
            this.inputLogger.addEvent(e);
            modifierPressed = false;
            if (e.key == 'Shift'){
                shiftPressed = false;
            }
        } 
    }
    checkKey(e) {
        if (!runsOnBakFile){
            e = e || window.event;
            
            if (redoStack.length > 0){
                e.preventDefault();    
            }
            if(e.getModifierState(e.key)){
                this.modifierKeyCode = e.keyCode;
                modifierPressed = true; 
                shiftPressed = (e.key == 'Shift');
                
            }
            if (modifierPressed && (e.key == 'z' || e.key == 'r')){
                let execFunction = (e.key == 'z') ? undo : redo;
                execFunction();
            } else {
                this.inputLogger.addEvent(e);
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
                            positionInfo();
                        }
                    });
                }
            }
        }
    }
}