class InputLogger {
    
    constructor(maxTime){
        this.button = document.getElementById('logButton');
        this.eventStack = [];
        this.MAX_TIME = (maxTime) ? maxTime : 5 * 60;
        this.dialog = document.querySelector('dialog');
    }
    addEvent(event, item){
        const entry = {date: new Date(), timestamp: Math.floor(Date.now() / 1000), event: this._eventToString(event, item)}
        if (this.eventStack.length > 0){
            this.eventStack = this.eventStack.filter(item =>(entry.timestamp - item.timestamp) < this.MAX_TIME);
        }
        this.eventStack.push(entry);
        if(this.button.getAttribute('disabled')){
            this.enableButton();
        }
    }
    _eventToString(event, item){
        switch(event.type){
            case 'keydown':
                return `${event.type} (key='${event.key}', char=${event.keyCode})`;
            case 'keyup':
                return `${event.type} (key='${event.key}', char=${event.keyCode})`;
            case 'click':
                return `${event.type} ('${item.id}')`;
            case 'position-info-click':
                return `${event.type} ('${item.id}')`;
            default:
                const targetId = (event.target) ? event.target.id : null;
                return `${event.type} (target='${targetId}')`;
        }
    }
    _entryToString(entry){
        return `${entry.date.toISOString()}: ${entry.event}`;
    }
    _getDate(){
        const date = this.eventStack[this.eventStack.length-1].date;
        return date.toJSON().slice(0,10);
    }
    
    show() {
        if (this.dialog){
            const textfield = document.getElementById('logTextField'); 
            textfield.value = this.eventStack.map(entry=>this._entryToString(entry)).join('\n'); 
            const closeButton = document.getElementById('dialogClose');
            const downloadButton = document.getElementById('downloadLog');
            closeButton.addEventListener("click", () => {
                this.dialog.close();
            });
            downloadButton.addEventListener("click", () => {
                const link = document.createElement("a");
                const content = textfield.value;
                const file = new Blob([content], { type: 'text/plain' });
                link.href = URL.createObjectURL(file);
                link.download = "topoTEI-" + this._getDate() + '.log';
                link.click();
                URL.revokeObjectURL(link.href);
                this.dialog.close();
            });
            this.dialog.showModal();
        } else {
            alert(this.eventStack.map(entry=>this._entryToString(entry)).join('\n'))
        }
    }
    enableButton(){
        this.button.removeAttribute('disabled');
        this.button.classList.add('active');
        this.button.addEventListener("click", () => {
            this.show();
        });
    }
}