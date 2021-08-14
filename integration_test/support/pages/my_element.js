class MyElement extends HTMLElement {
  connectedCallback() {
    this.attachShadow({mode: 'open'});
    this.shadowRoot.innerHTML = `<div id='find_me'>stuff</div>`;
  }
}

window.customElements.define('my-element', MyElement);