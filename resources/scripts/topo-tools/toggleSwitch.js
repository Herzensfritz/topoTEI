import {html, css, LitElement} from 'https://esm.run/lit';

export class ToggleSwitch extends LitElement {
  static styles = css`

.switch {
  position: relative;
  display: inline-block;
  width: 2em;
  height: 1em;
}

.switch input { 
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--bg-color, #2196F3);
  -webkit-transition: .4s;
  transition: .4s;
}

.slider:before {
  position: absolute;
  content: "";
  height: 0.5em;
  width: 0.5em;
  left: 4px;
  bottom: 4px;
  background-color: white;
  -webkit-transition: .4s;
  transition: .4s;
}
input:checked + .single {
  background-color: #ccc;
}
input:checked + .nonsingle {
  background-color: #var(--bg-color, #2196F3);
}

input:focus + .slider {
  box-shadow: 0 0 1px var(--bg-color, #2196F3);
}

input:checked + .slider:before {
  -webkit-transform: translateX(26px);
  -ms-transform: translateX(26px);
  transform: translateX(1em);
}

/* Rounded sliders */
.slider.round {
  border-radius: 1em;
}

.slider.round:before {
  border-radius: 50%;
}

   `;

  static properties = {
    label1: {type: String},
    label2: {type: String},
    input: {type: Object},
    value: {type: Boolean},
    output: {type: String},
     fo: {}
  };

  constructor() {
    super();
    this.value = true;
  }
 
  _toggle(e) {
      const changeEvent = new Event('change');
      this.value = !this.value;
      this.output = (this.value) ? this.label1 : this.label2;
      this.dispatchEvent(changeEvent);
  }
  check(uncheck) {
      const input = this.renderRoot?.querySelector('input');
      input.checked = !uncheck;
      this.requestUpdate();
  }

  render() {
     const singleLabel = (this.label2 == undefined || this.label2 == null)
    return html`   <div id="toggleSwitch">
         <label for="toggleInput">${this.label1}</input>
         <label id="toggleInput" class="switch">
           <input type="checkbox" @click=${this._toggle}/>
           ${ singleLabel ?  html `<span class="single slider round"></span>`
                          : html `<span class="nonsingle slider round"></span>`
            }
         </label>
         <label for="toggleInput">${this.label2}</input>
      </div> `;
  }
}
customElements.define('toggle-switch', ToggleSwitch);

