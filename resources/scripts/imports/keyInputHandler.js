class KeyInputHandler {
    constructor(inputLogger, keyStorage, history, positioner){
        this.inputLogger = inputLogger;
        this.keyStorage = keyStorage;
        this.modifierKeyCode = -1;
        this.offset = 1;
        this.modOffset = 10;
        this.history = history;
        this.positioner = positioner;
    }
    keyUp(e) {
        if (e.keyCode == this.modifierKeyCode) {
            this.inputLogger.addEvent(e);
            this.keyStorage.modifierPressed = false;
            if (e.key == 'Shift'){
                this.keyStorage.shiftPressed = false;
            }
        } 
    }
    _offset() {
       if (document.getElementById('offset') && Number(document.getElementById('offset').value)) {
            this.offset = Number(document.getElementById('offset').value);
        }
        if (document.getElementById('modOffset') && Number(document.getElementById('modOffset').value)) {
            this.modOffset = Number(document.getElementById('modOffset').value);
        } 
        return (this.keyStorage.modifierPressed) ? this.modOffset : this.offset;
    }
    checkKey(e) {
        e = e || window.event;
        if (this.history.canUndo || this.history.canRedo){
            e.preventDefault();    
        }
        if(e.getModifierState(e.key)){
            this.modifierKeyCode = e.keyCode;
            this.keyStorage.modifierPressed = true; 
            this.keyStorage.shiftPressed = (e.key == 'Shift');
        }
        if (this.keyStorage.modifierPressed && (e.key == 'z' || e.key == 'r')){
            if (e.key == 'z') {
                this.history.undo();
            } else {
                this.history.redo();
            }
        } else {
            this.inputLogger.addEvent(e);
            let selectedElements = Array.from(document.getElementsByClassName('selected'));
            if (selectedElements.length > 0){
                e.preventDefault();
                let currentOffset = this._offset();
                switch(String(e.keyCode)){
                    case '38':
                        this._arrowUp(selectedElements, currentOffset);
                        break;
                    case '40':
                        this._arrowDown(selectedElements, currentOffset);
                        break;
                    case '37':
                        this._arrowLeft(selectedElements, currentOffset);
                        break;
                    case '39':
                        this._arrowRight(selectedElements, currentOffset);
                        break;
                    case 'Enter':
                        selectedElements.forEach(item=>{
                            item.classList.remove("selected");
                        });
                        positionInfo();
                        break;
                    default:
                        console.log(e);
                }
            }
        }
    }
    _arrowUp(items, offset){
        items.forEach(item =>{
             this.positioner.repositionElement(item, 0, offset*-1, false)    
        })    
    }
    _arrowDown(items, offset){
        items.forEach(item =>{
             this.positioner.repositionElement(item, 0, offset, false)    
        })
    }
    _arrowLeft(items, offset){
        items.forEach(item =>{
            this.positioner.repositionElement(item, offset*-1, 0, false)    
        })
    }
    _arrowRight(items, offset){
        items.forEach(item =>{
            this.positioner.repositionElement(item, offset, 0, false)    
        })
    }
}