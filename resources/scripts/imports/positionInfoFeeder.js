class PositionInfoFeeder {
    constructor(getLeft, getTop, positionInfoElement){
        this.getElementLeft = getLeft;
        this.getElementTop = getTop;
        this.positionInfoElement = positionInfoElement;
        this.hasAddLines = false;

    }
    
    feedData(currentFontSize){
        this.positionInfoElement.reset();
        this.positionInfoElement.defaultFontSize = currentFontSize;
        const selected = Array.from(document.getElementsByClassName('selected')).filter(item =>item.closest('div.line')).map(item =>item.closest("div.line"));
        const selectedLines = Array.from(new Set(selected))
        const selectedFws = Array.from(document.getElementsByClassName('selected')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('fw')).length > 0))
        const selectedNotes = Array.from(document.getElementsByClassName('selected')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('note')).length > 0))
        if (selectedLines.length > 0){
           selectedLines.forEach(line  =>{
               const lnr = line.getElementsByClassName('lnr')[0];
               const title = 'Zeile ' + lnr.innerText;
               const items = Array.from(line.querySelectorAll('.above, .below'))
               const itemObject = {title: title, items: items, left: this.getElementLeft, top: this.getElementTop}
               this.positionInfoElement.appendItem(itemObject)
            });
            
        }
        const selectedAdd = Array.from(document.getElementsByClassName('selected')).filter(item =>
            (item.closest('div.zoneLine') && item.closest('div.zoneLine').querySelectorAll('.above, .below').length > 0)
        ).map(item =>item.closest("div.zoneLine"));
        const selectedAddLines = Array.from(new Set(selectedAdd))
        if (selectedAddLines.length > 0){
           selectedAddLines.forEach(line  =>{
               const lnr = line.getElementsByClassName('zlnr')[0];
               const title = 'Zeile ' + lnr.innerText;
               const items = Array.from(line.querySelectorAll('.above, .below'))
               const itemObject = {title: title, items: items, left: this.getElementLeft, top: this.getElementTop}
               this.positionInfoElement.appendItem(itemObject)
            });
        }
        if (selectedFws.length > 0){
            const fws = Array.from(document.querySelectorAll('*[draggable]')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('fw')).length > 0))
            const itemObject = { title: 'FW:', items: fws, left: this.getElementLeft, top: this.getElementTop}
            this.positionInfoElement.appendItem(itemObject)      
        }
        if (selectedNotes.length > 0){
            const notes = Array.from(document.querySelectorAll('*[draggable]')).filter(item=>(Array.from(item.classList).filter(cls =>cls.startsWith('note')).length > 0))
            const itemObject = { title: 'Notes:', items: notes, left: this.getElementLeft, top: this.getElementTop}
            this.positionInfoElement.appendItem(itemObject)      
        }
        if (this.positionInfoElement.objects.length > 0) {
            this.positionInfoElement.style.visibility = 'visible';
        } else {
            this.positionInfoElement.style.visibility = 'hidden';
            this.positionInfoElement.hideChildren();
        }
        this.hasAddLines = selectedAddLines.length > 0;
    }
}