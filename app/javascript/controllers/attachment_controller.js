import { Controller } from "@hotwired/stimulus";

// Handles pasting an image (screenshot) from clipboard into a hidden file input and previews it.
export default class extends Controller {
  static targets = ["fileInput", "preview", "clear", "info"];
  static values = {
    maxSize: { type: Number, default: 5 * 1024 * 1024 }, // 5MB
    types: { type: Array, default: ["image/png", "image/jpeg", "image/gif"] },
  };

  connect() {
    this.boundPasteHandler = this.paste.bind(this);
    this.element.addEventListener("paste", this.boundPasteHandler);
    this.updateInfo();
  }

  disconnect() {
    this.element.removeEventListener("paste", this.boundPasteHandler);
  }

  pick(event) {
    // Trigger native file chooser
    this.fileInputTarget.click();
  }

  fileChanged() {
    const file = this.fileInputTarget.files[0];
    if (!file) {
      this.clearPreview();
      return;
    }
    if (!this.validate(file)) {
      return;
    }
    this.renderPreview(file);
  }

  paste(event) {
    const items = event.clipboardData?.items || [];
    for (const item of items) {
      if (item.kind === "file") {
        const file = item.getAsFile();
        if (file && this.validate(file)) {
          // Put file into input via DataTransfer
          const dt = new DataTransfer();
          dt.items.add(file);
          this.fileInputTarget.files = dt.files;
          this.renderPreview(file);
          event.preventDefault();
          break;
        }
      }
    }
  }

  clear(event) {
    if (event) event.preventDefault();
    this.fileInputTarget.value = "";
    this.clearPreview();
  }

  validate(file) {
    if (file.size > this.maxSizeValue) {
      this.showError(
        `ファイルサイズが大きすぎます (最大 ${(
          this.maxSizeValue /
          1024 /
          1024
        ).toFixed(1)}MB)`
      );
      return false;
    }
    if (!this.typesValue.includes(file.type)) {
      this.showError("許可されていないコンテンツタイプです");
      return false;
    }
    this.clearError();
    return true;
  }

  renderPreview(file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      this.previewTarget.innerHTML = "";
      const img = document.createElement("img");
      img.src = e.target.result;
      img.alt = file.name;
      img.style.maxWidth = "150px";
      img.style.maxHeight = "150px";
      this.previewTarget.appendChild(img);
      this.updateInfo(file);
    };
    reader.readAsDataURL(file);
  }

  clearPreview() {
    this.previewTarget.innerHTML = "";
    this.updateInfo();
  }

  showError(message) {
    this.previewTarget.innerHTML = `<span style='color:red'>${message}</span>`;
  }

  clearError() {
    // Only clear if it's an error span
    if (
      this.previewTarget.firstChild &&
      this.previewTarget.firstChild.tagName === "SPAN"
    ) {
      this.previewTarget.innerHTML = "";
    }
  }

  updateInfo(file) {
    if (!this.hasInfoTarget) return;
    if (file) {
      this.infoTarget.textContent = `${file.name} (${(file.size / 1024).toFixed(
        1
      )} KB)`;
    } else {
      this.infoTarget.textContent =
        "画像をクリック or 貼り付け (Ctrl+V / Cmd+V) できます";
    }
  }
}
