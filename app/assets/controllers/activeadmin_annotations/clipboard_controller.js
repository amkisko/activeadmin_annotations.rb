import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status", "manualCopy"];

  static values = {
    sourceUrl: String,
    successMessage: { type: String, default: "Copied annotation details" },
  };

  async copyFromUrl() {
    if (!this.hasSourceUrlValue || !this.sourceUrlValue) {
      this.announce("Annotation details are not available to copy.");
      return;
    }

    try {
      const response = await fetch(this.sourceUrlValue, {
        credentials: "same-origin",
        headers: { Accept: "text/plain" },
      });
      if (!response.ok) {
        this.announce("Annotation details could not be loaded.");
        return;
      }

      const text = await response.text();
      await this.copyText(text, this.successMessageValue);
    } catch (_error) {
      this.announce("Annotation details could not be copied.");
    }
  }

  async copyText(text, successMessage) {
    if (!text) {
      this.announce("There is nothing to copy for this annotation.");
      return;
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      try {
        await navigator.clipboard.writeText(text);
        this.hideManualCopy();
        this.announce(successMessage);
        return;
      } catch (_error) {}
    }

    if (!this.hasManualCopyTarget) {
      this.announce("Clipboard access failed.");
      return;
    }

    this.manualCopyTarget.hidden = false;
    this.manualCopyTarget.value = text;
    this.manualCopyTarget.focus();
    this.manualCopyTarget.select();
    this.announce("Clipboard access failed. The annotation details are selected for manual copy.");
  }

  hideManualCopy() {
    if (!this.hasManualCopyTarget) return;

    this.manualCopyTarget.hidden = true;
    this.manualCopyTarget.value = "";
  }

  announce(message) {
    if (!this.hasStatusTarget) return;

    this.statusTarget.textContent = message;
  }
}
