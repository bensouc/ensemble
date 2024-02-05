// pwa_installer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["installPrompt"];

  INSTALLATION_STATUS = "app_status";
  DONT_SHOW_PROMPT_AGAIN = "show_prompt";

  connect() {
    this.deferredPrompt = null;

    window.addEventListener("beforeinstallprompt", this.handleBeforeInstallPrompt.bind(this));
    window.addEventListener("appinstalled", this.handleAppInstalled.bind(this));
    // this.managePromptDisplay();
  }

  getDeviceInfo() {
    const ua = navigator.userAgent;
    return {
      device: {
        isMobile: /Mobi|Android/i.test(ua),
        isIOS: /iPhone|iPad|iPod/i.test(ua),
      },
      pwa: {
        isStandalone: window.matchMedia('(display-mode: standalone)').matches,
      }
    };
  }

  handleBeforeInstallPrompt(e) {
    console.log("Before install prompt event fired");
    e.preventDefault();
    this.deferredPrompt = e;
    this.managePromptDisplay();
  }

  handleAppInstalled(e) {
    console.log("App installed event fired");
    localStorage.setItem(this.INSTALLATION_STATUS, 'true');
    this.deferredPrompt = null;
    this.managePromptDisplay();
  }

  managePromptDisplay() {
    const { device, pwa } = this.getDeviceInfo();
    const isInstalled = localStorage.getItem(this.INSTALLATION_STATUS) === 'true';
    const dontShowAgain = localStorage.getItem(this.DONT_SHOW_PROMPT_AGAIN) === 'true';

    if (dontShowAgain || pwa.isStandalone || isInstalled) {
      this.hidePrompt();
      return;
    }

    if (device.isMobile) {
      const showInstallPrompt = !!this.deferredPrompt;
      this.installPromptTarget.classList.toggle("hidden", !showInstallPrompt);
      // this.manualPromptTarget.classList.toggle("hidden", showInstallPrompt);
    }
  }

  hidePrompt() {
    localStorage.setItem(this.DONT_SHOW_PROMPT_AGAIN, 'true');
    this.installPromptTarget.classList.add("hidden");
    // this.manualPromptTarget.classList.add("hidden");
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
  }
}
