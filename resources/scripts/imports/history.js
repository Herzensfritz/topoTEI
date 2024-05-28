class History {
    constructor(){
        this.undoStack = [];
        this.redoStack = [];
        this._valueHandler = null;
        this._positioner = null;
        this.undoButton = document.getElementById('undoButton');
        this.redoButton = document.getElementById('redoButton');
        this.undoButton.addEventListener("click", (event) => {
                this.undo();   
        });
        this.redoButton.addEventListener("click", (event) => {
                this.redo();   
        });
    }
    get canUndo() {
        return (this.undoStack.length > 0);    
    }
    get canRedo() {
        return (this.redoStack.length > 0);    
    }
    set valueHandler(valueHandler){
        this._valueHandler = valueHandler;    
    }
     set positioner(positioner){
        this._positioner = positioner;    
    }
    redo() {
        Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
        if (this.redoStack.length > 0){
            let lastEvent = this.redoStack.pop();
            lastEvent.undo(false);    
        }
    }
    undo() {
        Array.from(document.getElementsByClassName('selected')).forEach(selected =>selected.classList.remove("selected"));
        if (this.undoStack.length > 0){
            let lastEvent = this.undoStack.pop();
            lastEvent.undo(true);
        }
    }
    recordNewValueChange(input, isRedoing){
        if (this._valueHandler){
            let inputObject = this._valueHandler.getObject(input);
            let currentElement = (inputObject.isClass) ? Array.from(document.getElementsByClassName(inputObject.id))[0] : document.getElementById(inputObject.id);
            let oldValue = currentElement.style[inputObject.paramName];
        
            let change = new ParamChange(input, oldValue, this._valueHandler);    
            let currentStack = (isRedoing) ? this.redoStack : this.undoStack;
            currentStack.push(change);
        } else {
            console.warn('ValueHandler empty!')    
        }
        this.handleButtons();
    }
    recordChange(currentElement, offsetX, offsetY, isRedoing){
        if (this._positioner){
           let change = new Change(currentElement, offsetX, offsetY, this._positioner);
           let currentStack = (isRedoing) ? this.redoStack : this.undoStack;
           currentStack.push(change);
           
        }
        else {
            console.warn('Positioner empty!')    
        }
        this.handleButtons();
    }
    handleButtons(){
        if (this.undoStack.length > 0){
            this.undoButton.removeAttribute('disabled');
            this.undoButton.classList.add('active');
        }   
        if (this.redoStack.length > 0){
            this.redoButton.removeAttribute('disabled');
            this.redoButton.classList.add('active');
        }
    
    }
}