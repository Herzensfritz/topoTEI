import {html, css, LitElement} from 'https://esm.run/lit';
import './toggleSwitch.js';

export class PositionInfo extends LitElement {
  static INSERTION_MARK_REGEX = /[A-Za-z]+insertion-(above|below)/g;
  static styles = css`
      div.position {
         display: grid;
      }
      #copySpan {
         visibility: hidden;
         position: relative;
         top: 1em;
         left: 2em;
      }
      #copyLabel {
         padding-right: 5px;
      }
      
   `;

  static properties = {
    _changedValues: {type: Object},
    _defaultFontSize: {type: Number},
    objects: {type: Array},
    title: {type: String},
    showAbsoluteValues: {type: Boolean},
  };

  constructor() {
    super();
    this._changedValues = null;
    this._defaultFontSize = 16;
    this.showAbsoluteValues = true;
    this.objects = [];
    this._keyListenerHandler = null;
  }
  
  set keyListenerHandler(handler){
    this._keyListenerHandler = handler;    
  }
  
  hideChildren () {
    Array.from(this.renderRoot?.querySelectorAll('*[style*="visibility"]')).forEach(child =>{
        child.style.visibility = 'hidden';    
    })
  }

  appendItem(object) {
      this.objects = [...this.objects, object];
  }
  reset() {
      this.objects = [];
  }

  get readChangedValues() {
      const tmp = this._changedValues;
      this._changedValues = null;
      return tmp;
  }
  set defaultFontSize(fontSize) {
      this._defaultFontSize = fontSize;
  }

  __toggle(e) {
      this.showAbsoluteValues = e.target.value;
      const span =  this.renderRoot?.querySelector('#copySpan')
      span.style.visibility = 'hidden';
      this.__addKeyListener();
  }

  __valueChanged(e) {
      const oldAbsolut = (e.target.dataset.absolut == 'true')
      const oldValue = (this.showAbsoluteValues == oldAbsolut) ? e.target.dataset.oldValue : e.target.value;
      this._changedValues = { action: e.target.dataset.action, id: e.target.dataset.id, value: e.target.value, oldValue: oldValue, absoluteValue: this.showAbsoluteValues};
      if (e.target.dataset.oldValue) {
         e.target.setAttribute('data-old-value', e.target.value);
      }
      const newEvent = new Event('change');
      this.dispatchEvent(newEvent)
  }
  _fontSize(item) {
      return Number(window.getComputedStyle(item, null).getPropertyValue('font-size').replace('px', '')) 
  }

  __copyValue(e) {
     const span =  this.renderRoot?.querySelector('#copySpan')
     const label =  this.renderRoot?.querySelector('#copyLabel')
     const button =  this.renderRoot?.querySelector('#copyButton')
     const input =  this.renderRoot?.querySelector('#copyInput')
     input.value = e.target.value;
     label.innerText = e.target.dataset.action;
     button.removeAttribute('disabled');
     span.style.visibility = 'visible';
  }

  _showItem(item, getTop, getLeft) {
      const checked = item.classList.contains('selected');
      const top = (this.showAbsoluteValues) ? Math.round(item.getBoundingClientRect().top*10)/10 : getTop(item);
      const left = (this.showAbsoluteValues) ? Math.round(item.getBoundingClientRect().left*10)/10 : getLeft(item);
      const step = (this.showAbsoluteValues) ? '1' : '0.1';
      const unit = (this.showAbsoluteValues) ? 'px': 'em';
      const zIndex = window.getComputedStyle(item, null).getPropertyValue('z-index')
      const fontSize = this._fontSize(item);
      return html `
         <span class="record">
            ${ checked ? html `<input type="checkbox" data-action="click" data-id="${item.id}" @change=${this.__valueChanged} checked="${checked}"/>` 
                       : html `<input type="checkbox" data-action="click" data-id="${item.id}" @change=${this.__valueChanged}/>` }
            <input type="text" size="10" readonly="true" value="${item.innerText}" title="${item.innerText} (font-size: ${fontSize}px, default: ${this._defaultFontSize}px)"/>
            <input type="number" size="8" .step="${step}" data-action="top" data-id="${item.id}" .value="${top}" title="top: ${top}${unit}" @change=${this.__valueChanged} data-old-value="${top}" data-absolut="${this.showAbsoluteValues}" @dblclick=${this.__copyValue}/>
            <input type="number" size="8" .step="${step}" data-action="left" data-id="${item.id}" .value="${left}" title="left: ${left}${unit}" @change=${this.__valueChanged} data-old-value="${left}" data-absolut="${this.showAbsoluteValues}" @dblclick=${this.__copyValue}/>
            <input type="number" size="2" min="0" data-action="zIndex" data-id="${item.id}" @change=${this.__valueChanged} .value="${zIndex}" title="Mit dem z-index kann beinflusst werden, ob ein Element andere Elemente überlagert. Elemente mit höherem z-index überlagern Elemente mit kleinerem z-index."  />
         </span>
      `
  }
  updateItems() {
      this.requestUpdate();
  }

  __updateSelected() {
     const span =  this.renderRoot?.querySelector('#copySpan')
     const button =  this.renderRoot?.querySelector('#copyButton')
     const copyInput =  this.renderRoot?.querySelector('#copyInput')
     const label =  this.renderRoot?.querySelector('#copyLabel')
     const results = Array.from(this.renderRoot?.querySelectorAll('.record')).filter(span =>span.querySelector('input:checked'))
     const selector = 'input[data-action=\"' + label.innerText + '\"]'
     results.forEach(span=>{
        const input = span.querySelector(selector)
        if (!input.dataset.oldValue) {
            input.setAttribute('data-old-value', input.value)
        }
        input.value = copyInput.value;
        this.__valueChanged({ target: input });
     });
     this.__addKeyListener();
  }

  _showObject(object) {
      return html `<div class="position">
         <h3>${object.title}</h3>
         ${object.items.map(item=>this._showItem(item, object.top, object.left))}
      </div>`
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
  handleSlotchange(e){
     const childNodes = Array.from(e.target.assignedNodes({flatten: true})).filter(elem =>elem.tagName);
     childNodes.forEach(elem =>{
        switch(elem.tagName.toLowerCase()) {
            case 'toggle-listener':
              this.keyListenerHandler = elem;
              break;
            default:
              console.log(elem.tagName);
        }
     })
  }

  render() {
    return html`   
       <div id="positionInfo">
         <h2>Positionen</h2>
         <slot @slotchange=${this.handleSlotchange}></slot>
         <toggle-switch label1="absolut" label2="relativ" @change=${this.__toggle}></toggle-switch>
         <form id="addPositionForm" name="adds">
         ${this.objects.map(object =>this._showObject(object))}
         </form>
         <span id="copySpan"><label id="copyLabel">label</label><input id="copyInput" @focusout=${this.__addKeyListener} @click=${this.__removeKeyListener} type="number"/><button id="copyButton" disabled="true" @click=${this.__updateSelected} >set</button></span>
      </div>
    `;
  }
}
customElements.define('position-info', PositionInfo);

