class Change {
    constructor(element, offsetX, offsetY, positioner){
        this.element = element;
        this.offsetX = offsetX;
        this.offsetY = offsetY;
        this.positioner = positioner;
    }    
    undo(isRedoing) {
        this.element.classList.add("selected");
        this.positioner.repositionElement(this.element, this.offsetX*-1, this.offsetY*-1, isRedoing);
    }
}
class ParamChange {
    constructor(input, oldValue, valueHandler){
        this.input = input;
        this.oldValue = oldValue;
        this.valueHandler = valueHandler;
    }    
    undo(isRedoing) {
        this.valueHandler.setNewValue(this.input, this.oldValue, isRedoing);
    }
}
