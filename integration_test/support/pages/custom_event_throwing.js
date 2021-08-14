class CustomEventThrowing extends HTMLElement {
  connectedCallback() {
    this.attachShadow({mode: 'open'});
    this.shadowRoot.innerHTML = `<button id='click_me'>Click me</button>`;
    this.shadowRoot.querySelector('button').addEventListener('click', () => {
      this.dispatchEvent(new CustomEvent('custom'));
    });
  }
}

window.customElements.define('custom-event-throwing', CustomEventThrowing);