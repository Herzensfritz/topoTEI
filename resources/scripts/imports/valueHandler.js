class ValueHandler {
    static ID = 'valueHandler';
    static PAGE_SETUP = 'pageSetup';
    static TRANSCRIPTION_FIELD = 'transkriptionField';
    static OBJ_PARAMS = [{targetName: 'id', dataName: 'data-id'}, 
                    {targetName: 'isClass', dataName: 'data-is-class', type: 'boolean'}, 
                    {targetName: 'paramName', dataName: 'data-param'}, 
                    {targetName: 'unit', dataName: 'data-unit'}];
    
    constructor(history) {
        this.history = history;
        this._keyListenerHandler = document.querySelector('toggle-listener')
        const selector = '*[data-handler=\"' + ValueHandler.ID + '\"]';
        const inputs = Array.from(document.querySelectorAll(selector))
        inputs.forEach(input =>{
            input.addEventListener("change", (event) => {
                this.setNewValue(event.target, false)    
            });
            input.addEventListener("focusout", (event) => {
                this.__addKeyListener(event);   
            });
            input.addEventListener("click", (event) => {
                this.__removeKeyListener(event);   
            });
        })
        this.history.valueHandler = this;
        const pageButton = document.getElementById('pageButton');
        pageButton.addEventListener("click", () => {
            this.pageSetup();    
        });
        
    }
    pageSetup(){
        if (!topoTEIObject.runsOnBakFile){
            let form = document.getElementById(ValueHandler.PAGE_SETUP);
            hideOtherInputs(form.id);
            form.style.visibility = (form.style.visibility == 'visible') ? 'hidden' : 'visible';
            if (form.style.visibility == 'visible'){
                Array.from(form.lastElementChild.children).filter(child =>child.id).forEach(pageInput =>{
                    let tf = Array.from(document.getElementsByClassName(ValueHandler.TRANSCRIPTION_FIELD))[0];
                    let style = tf.style[pageInput.dataset.param];
                    this.setInputValue(pageInput, style, tf.id, false);
                });
            }
        }   
    }
    setInputValue(input, styleValue, id, isClass){
        if (styleValue) {
            input.value = saveReplaceLength(styleValue, topoTEIObject.pixelLineHeight) 
        }
        input.setAttribute('data-is-class', String(isClass));
        input.setAttribute('data-id', id);
    }
     __addKeyListener(e){
      if (this._keyListenerHandler){
        this._keyListenerHandler.appendKeyListener();    
    }
  }
  __removeKeyListener(e){
    if (this._keyListenerHandler){
        this._keyListenerHandler.removeKeyListener();    
    }
  }
  getObject(input){
    const obj = {};
    ValueHandler.OBJ_PARAMS.forEach(param =>{
        if(input.getAttribute(param.dataName)){
            obj[param.targetName] = (param.type == 'boolean') ? input.getAttribute(param.dataName) == 'true' : input.getAttribute(param.dataName);    
        }
    });
    return obj;
 }
 setNewValue(input, isRedoing){
    if(!isRedoing && input.dataset.function){
        window[input.dataset.function]();  
        input.closest('div.input').style.visibility = 'visible';
    }
    let inputObject = this.getObject(input);
    this.history.recordNewValueChange(input, isRedoing);
    let newValue = (input.type == 'number') ? Number(input.value) : input.value;
    handleButtons();
    if (inputObject.isClass){
         Array.from(document.getElementsByClassName(inputObject.id)).forEach(element =>{
             this.setStyleToElement(element, newValue, inputObject)
         });
    } else {
        let element = document.getElementById(inputObject.id);
        this.setStyleToElement(element, newValue, inputObject);
    } 
}
setStyleToElement(element, newValue, paramObject){
    element.style[paramObject.paramName] = (paramObject.unit) ? newValue + paramObject.unit : newValue;
    element.classList.add(VALUE_CHANGED);
    if (element.inputMap && Object.hasOwn(element.inputMap,paramObject.paramName)) {
        element.inputMap[paramObject.paramName].value = newValue; 
        element.inputMap[paramObject.paramName].setAttribute('title', paramObject.paramName + ': ' + newValue);
    }
}
}