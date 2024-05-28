class Sender {
    static VALUE_CHANGED = 'valueChanged';
    
    constructor(file, history){
        this.file = file;
        this.history = history;
        const saveButton = document.getElementById('saveButton');
        saveButton.addEventListener("click", () => {
            if (!saveButton.getAttribute('disabled')){
               let elements = Array.from(document.getElementsByClassName(Sender.VALUE_CHANGED));
               let elementInfos = [];
               elements.forEach(element =>{
                   this._getStyleFromElement(element, elementInfos)
                });
                this.send(elementInfos);
            } 
        });
        const form = document.getElementById('editorInputForm')
        const fontIdArray = form.dataset.fonts.split(',')
        const dataNameArray = form.dataset.paramNames.split(',')
        const editorInputButton = document.getElementById('editorInputButton');
        editorInputButton.addEventListener("click", () => {
            let fontSelectors = Array.from(fontIdArray.map(id =>document.getElementById(id)));
            let fonts =  fontSelectors.map(fontSelector => this._createConfigObject(fontSelector.id, fontSelector.options[fontSelector.selectedIndex].text, 'family', 'current'));
            let configData = dataNameArray.map(id =>this._createConfigObject(id, document.getElementById(id).value, 'name', 'param'));
            let data = { font: fonts, config: configData }
            let jsonData = JSON.stringify(data);
            this.sendConfig(jsonData)
        });
        const configToggleButton = document.getElementById('configToggleButton');
        configToggleButton.addEventListener("click", () => {
            this._toggleConfig();
        });
    }
    _createConfigObject(objectId, objectValue, targetAttr, targetTag ){
        return { id: objectId, value: String(objectValue), attr: targetAttr, tag: targetTag }    
    }

    _toggleConfig(){
        let config = document.getElementById("editorInput"); 
        config.style.visibility = (config.style.visibility == 'visible') ? 'hidden' : 'visible';
        hideOtherInputs(config.id);
    
    }
    _getStyleFromElement(element, targetArray){
        let style = '';
        for (const value of Object.values(element.style)) {
            style = style + value + ':' + element.style[value] + ';';
        }
        targetArray.push({id: element.id, style: style});
    }
    send(data){
        if (this.file && data.length > 0) {
            let xhr = new XMLHttpRequest()
            xhr.open('POST', "/exist/restxq/save", true)
            xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
            const href = '/exist/restxq/transform?file=' + this.file
            xhr.send("file=" + this.file + "&elements=" + JSON.stringify(data));
            this.history.undoStack = [];
            xhr.onload = function () {
                location.href = href
            }
        }
    }
    sendConfig(jsonData){
        let xhr = new XMLHttpRequest()
        xhr.open('POST', "/exist/restxq/config", true)
        xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhr.send('configuration=' + jsonData);
        this._toggleConfig();
        xhr.onload = function () {
            if(this.status == '205'){
                window.location.reload(true);    
            }
            
        }
    }
}