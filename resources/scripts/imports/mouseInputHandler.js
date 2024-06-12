class MouseInputHandler {
    constructor(inputLogger, keyStorage, positioner){
        this.inputLogger = inputLogger;
        this.keyStorage = keyStorage;
        this.positioner = positioner;
        this.dragStartPosX = null;
        this.dragStartPosY = null;
        this.clickOffset = 10;
        this._keyListenerHandler = document.querySelector('toggle-listener')
    }
    _offset(item) {
        if (document.getElementById('toggleOffset') && Number(document.getElementById('toggleOffset').value)) {
            this.clickOffset = Number(document.getElementById('toggleOffset').value);
        }  
        let currentOffset = (item.classList.contains('clicked')) ? this.clickOffset : this.clickOffset*-1;
        return (item.parentElement.className.includes('below')) ? currentOffset*-1 : currentOffset;
    }
    clickItem(item, event){
        this.inputLogger.addEvent(event, item);
        if (event) {
             event.stopPropagation();
         }
         if (this.keyStorage.modifierPressed){
             if (this.keyStorage.shiftPressed){
                 item.classList.toggle("selected")
             }else{
                 if (item.classList.contains('selected')){
                     item.classList.remove("selected");
                 } else {
                     item.classList.add("selected");
                     let currentOffset =  this._offset(item);
                     item.classList.toggle('clicked');
                     this.positioner.repositionElement(item, 0, currentOffset, false);
                 }
             }
         } else {
            const selected = Array.from(document.getElementsByClassName('selected'))
            const selectItem = (!selected.includes(item))
            if (selectItem) {
                selected.forEach(s=>{s.classList.remove('selected')})
                item.classList.add("selected");
            } else {
                item.classList.remove("selected");    
            }
            if (document.getElementsByClassName('selected').length > 0 && !this._keyListenerHandler.isKeyListenerOn){
                this._keyListenerHandler.appendKeyListener();
            }
         }
         positionInfo(item);
    } 
    dragStart(event){
      this.inputLogger.addEvent(event);
      this.dragStartPosX = event.clientX;
      this.dragStartPosY = event.clientY;
      event.dataTransfer.effectAllowed = "move";
      event.dataTransfer.setData("text/plain", event.target.id);
    }
    dragEnd(event){
      this.inputLogger.addEvent(event);
      let dragEndPosX = (this.dragStartPosX - event.clientX);
      let dragEndPosY = (this.dragStartPosY - event.clientY);
      this.positioner.repositionElement(event.target, dragEndPosX*-1, dragEndPosY*-1, false);
      event.preventDefault();
    }
}