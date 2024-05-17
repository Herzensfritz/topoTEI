import {html, css, LitElement} from 'https://esm.run/lit';
import './toggleSwitch.js';

export class ToggleKeyListener extends LitElement {
  static styles = css`


   `;

  static properties = {
    _keyListener: {type: Object},
  };

  constructor() {
    super();
    this._keyListener = null;
  }

  set keyListener(keyListener) {
     this._keyListener = keyListener;
     this.appendKeyListener();
  }
  get keyListener() {
      return this._keyListener;
  }
  get isKeyListenerOn() {
      return (document.onkeydown != null);
  }
  appendKeyListener(e) {
     document.onkeydown = this._keyListener;
     if (!e) {
         const toggle = this.renderRoot?.querySelector('toggle-switch')
         toggle.check(true);
     }
  }
  removeKeyListener() {
     document.onkeydown = null;
     const toggle = this.renderRoot?.querySelector('toggle-switch')
     toggle.check(false);
  }
 
  __toggle(e) {
     if (e.target.value) {
         this.appendKeyListener();
     } else {
         this.removeKeyListener();
     }
  }

  render() {
    return html`<div id="toggleKeyListener">
            <toggle-switch label1="keyListener" @change=${this.__toggle}></toggle-switch>
         </div> `;
  }
}
customElements.define('toggle-listener', ToggleKeyListener);

