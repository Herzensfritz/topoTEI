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
}
class ParamChange {
    constructor(input, oldValue){
        this.input = input;
        this.oldValue = oldValue;
    }    
    undo(isRedoing) {
        setNewValue(this.input, this.oldValue, isRedoing);
    }
}