// pwa_installer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["installPrompt"];

  INSTALLATION_STATUS = "app_status";
  DONT_SHOW_PROMPT_AGAIN = "show_prompt";

  connect() {
    this.deferredPrompt = null;
    // window.addEventListener("scroll", this.handleScroll.bind(this))
    window.addEventListener("beforeinstallprompt", this.handleBeforeInstallPrompt.bind(this));
    window.addEventListener("appinstalled", this.handleAppInstalled.bind(this));
    this.managePromptDisplay();
    setTimeout(() => {
      this.hideDiv();
    }, 3000);
  }

  getDeviceInfo() {
    return {
      pwa: {
        isStandalone: window.matchMedia('(display-mode: standalone)').matches,
      }
    };
  }

  handleBeforeInstallPrompt(e) {
    e.preventDefault();
    this.deferredPrompt = e;
    this.managePromptDisplay();
  }

  handleAppInstalled(e) {

    localStorage.setItem(this.INSTALLATION_STATUS, 'true');
    this.deferredPrompt = null;
    this.managePromptDisplay();
  }

  managePromptDisplay() {
    const { pwa } = this.getDeviceInfo();
    const isInstalled = localStorage.getItem(this.INSTALLATION_STATUS) === 'true';
    const dontShowAgain = localStorage.getItem(this.DONT_SHOW_PROMPT_AGAIN) === 'true';


    if (dontShowAgain || pwa.isStandalone || isInstalled) {
      this.hidePrompt();
      return;
    }
  }

  hidePrompt() {
    localStorage.setItem(this.DONT_SHOW_PROMPT_AGAIN, 'true');
    this.installPromptTarget.classList.add("hidden-prompt");
  }

  hideDiv() {

    this.installPromptTarget.classList.add("hidden-prompt");
  }

  showDiv() {
    this.installPromptTarget.classList.remove("hidden-prompt");
  }

  async onInstall() {
    if (this.deferredPrompt) {
      // The browser uses the name and icons properties from the Manifest to build the prompt.
      // https://web.dev/learn/pwa/installation-prompt
      this.deferredPrompt.prompt();
      try {
        const { outcome } = await this.deferredPrompt.userChoice;
        if (outcome === 'accepted') {
          localStorage.setItem(this.INSTALLATION_STATUS, 'true');
        }
      } catch (error) {
        console.error('Installation prompt error:', error);
      }
      this.deferredPrompt = null;
      this.installPromptTarget.classList.add("hidden");
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.handleBeforeInstallPrompt.bind(this));
    window.removeEventListener("appinstalled", this.handleAppInstalled.bind(this));
    window.removeEventListener("scroll", this.handleScroll.bind(this));
  }
}
