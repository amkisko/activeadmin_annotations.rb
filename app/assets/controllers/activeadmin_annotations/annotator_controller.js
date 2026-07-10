import { Controller } from "@hotwired/stimulus";

const PENDING_HIGHLIGHT_NAME = "aa-annotations-pending";
const SAVED_HIGHLIGHT_NAME = "aa-annotations-saved";

export default class extends Controller {
  static targets = [
    "annotatable",
    "sidebar",
    "annotationList",
    "composer",
    "composerHeading",
    "selectedPreview",
    "commentInput",
    "categoryInput",
    "errorMessage",
  ];

  static values = {
    reviewId: String,
    field: String,
    createUrl: String,
    updateUrlTemplate: String,
    categoryLabel: { type: String, default: "Category" },
    categories: { type: Object, default: {} },
    annotations: { type: Array, default: [] },
    readonly: { type: Boolean, default: false },
  };

  connect() {
    this.pendingSelection = null;
    this.editingAnnotationId = null;
    this.highlightsSupported = typeof CSS !== "undefined" && CSS.highlights;
    this.renderAnnotations();
    this.annotatableTarget.addEventListener("mouseup", this.commitAnnotatableSelection);
    this.annotatableTarget.addEventListener("keyup", this.commitAnnotatableSelection);
    document.addEventListener("selectionchange", this.handleSelectionChange);
    document.addEventListener("keydown", this.handleDocumentKeydown);
  }

  disconnect() {
    this.annotatableTarget.removeEventListener("mouseup", this.commitAnnotatableSelection);
    this.annotatableTarget.removeEventListener("keyup", this.commitAnnotatableSelection);
    document.removeEventListener("selectionchange", this.handleSelectionChange);
    document.removeEventListener("keydown", this.handleDocumentKeydown);
    this.clearPendingHighlight();
    this.clearSavedHighlights();
  }

  commitAnnotatableSelection = () => {
    if (this.readonlyValue) return;

    requestAnimationFrame(() => {
      const selection = this.currentSelection();
      if (selection) this.activateComposer(selection);
    });
  };

  handleSelectionChange = () => {
    if (this.readonlyValue) return;
    if (this.composerIsOpen()) this.ensurePendingHighlight();
  };

  activateComposer(selection) {
    this.editingAnnotationId = null;

    const selectionChanged =
      !this.pendingSelection ||
      this.pendingSelection.startOffset !== selection.startOffset ||
      this.pendingSelection.endOffset !== selection.endOffset ||
      this.pendingSelection.selectedText !== selection.selectedText;

    this.pendingSelection = selection;
    this.selectedPreviewTarget.textContent = selection.selectedText;

    if (selectionChanged) {
      this.commentInputTarget.value = "";
      this.categoryInputTarget.value = "";
    }

    this.hideError();
    this.setComposerHeading("New annotation");
    this.composerTarget.classList.remove("aa-annotations-composer-hidden");
    this.applyPendingHighlight(selection);
    window.getSelection()?.removeAllRanges();
  }

  editAnnotation(event) {
    if (this.readonlyValue) return;

    const annotationId = event.currentTarget.dataset.annotationId;
    const annotation = this.annotationsValue.find((entry) => String(entry.id) === String(annotationId));
    if (!annotation) return;

    this.editingAnnotationId = annotation.id;
    this.pendingSelection = {
      selectedText: annotation.selected_text,
      startOffset: Number(annotation.start_offset),
      endOffset: Number(annotation.end_offset),
    };
    this.selectedPreviewTarget.textContent = annotation.selected_text;
    this.commentInputTarget.value = annotation.comment;
    this.categoryInputTarget.value = annotation.category || "";
    this.hideError();
    this.setComposerHeading("Edit annotation");
    this.composerTarget.classList.remove("aa-annotations-composer-hidden");
    this.applyPendingHighlight(this.pendingSelection);
    window.getSelection()?.removeAllRanges();
    this.commentInputTarget.focus();
  }

  async deleteAnnotation(event) {
    if (this.readonlyValue) return;

    const annotationId = event.currentTarget.dataset.annotationId;
    const annotation = this.annotationsValue.find((entry) => String(entry.id) === String(annotationId));
    if (!annotation) return;

    if (!window.confirm("Delete this annotation?")) return;

    try {
      const response = await fetch(this.annotationUrl(annotationId), {
        method: "DELETE",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken(),
        },
      });

      if (!response.ok) {
        window.alert("Could not delete annotation.");
        return;
      }

      if (String(this.editingAnnotationId) === String(annotationId)) this.resetComposer();

      this.annotationsValue = this.annotationsValue.filter(
        (entry) => String(entry.id) !== String(annotationId)
      );
      this.renderAnnotations();
    } catch (_error) {
      window.alert("Could not delete annotation.");
    }
  }

  resetComposer() {
    this.pendingSelection = null;
    this.editingAnnotationId = null;
    this.clearPendingHighlight();
    this.selectedPreviewTarget.textContent = "";
    this.commentInputTarget.value = "";
    this.categoryInputTarget.value = "";
    this.hideError();
    this.setComposerHeading("New annotation");
    this.composerTarget.classList.add("aa-annotations-composer-hidden");
  }

  composerIsOpen() {
    return !this.composerTarget.classList.contains("aa-annotations-composer-hidden");
  }

  cancelComposer() {
    this.resetComposer();
    window.getSelection()?.removeAllRanges();
  }

  ensurePendingHighlight() {
    if (!this.pendingSelection) return;

    this.applyPendingHighlight(this.pendingSelection);
  }

  async submitComposer() {
    if (!this.pendingSelection) return;

    const comment = this.commentInputTarget.value.trim();
    if (!comment) {
      this.showError("Comment is required.");
      return;
    }

    if (this.editingAnnotationId) {
      await this.updateAnnotation(comment);
      return;
    }

    await this.createAnnotation(comment);
  }

  async createAnnotation(comment) {
    const payload = {
      annotation: {
        annotation_review_id: this.reviewIdValue,
        field_name: this.fieldValue,
        selected_text: this.pendingSelection.selectedText,
        start_offset: this.pendingSelection.startOffset,
        end_offset: this.pendingSelection.endOffset,
        comment: comment,
        category: this.categoryInputTarget.value || null,
        context_paths_json: [],
      },
    };

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken(),
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        this.showError("Could not save annotation.");
        return;
      }

      const annotation = await response.json();
      this.resetComposer();
      this.annotationsValue = [...this.annotationsValue, this.normalizeAnnotation(annotation)];
      this.renderAnnotations();
      window.getSelection()?.removeAllRanges();
    } catch (_error) {
      this.showError("Could not save annotation.");
    }
  }

  async updateAnnotation(comment) {
    const payload = {
      annotation: {
        comment: comment,
        category: this.categoryInputTarget.value || null,
      },
    };

    try {
      const response = await fetch(this.annotationUrl(this.editingAnnotationId), {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken(),
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        this.showError("Could not update annotation.");
        return;
      }

      const annotation = await response.json();
      this.resetComposer();
      this.annotationsValue = this.annotationsValue.map((entry) =>
        String(entry.id) === String(annotation.id) ? this.normalizeAnnotation(annotation) : entry
      );
      this.renderAnnotations();
    } catch (_error) {
      this.showError("Could not update annotation.");
    }
  }

  handleDocumentKeydown = (event) => {
    if (event.key !== "Escape") return;
    if (!this.composerIsOpen()) return;

    this.cancelComposer();
  };

  currentSelection() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return null;

    const range = selection.getRangeAt(0);
    if (!this.selectionInsideAnnotatable(range)) return null;

    const selectedText = selection.toString().trim();
    if (!selectedText) return null;

    const startOffset = this.offsetWithinAnnotatable(range.startContainer, range.startOffset);
    const endOffset = this.offsetWithinAnnotatable(range.endContainer, range.endOffset);
    if (startOffset === null || endOffset === null || endOffset <= startOffset) return null;

    return { selectedText, startOffset, endOffset };
  }

  selectionInsideAnnotatable(range) {
    const startElement = this.elementForNode(range.startContainer);
    const endElement = this.elementForNode(range.endContainer);
    return this.annotatableTarget.contains(startElement) && this.annotatableTarget.contains(endElement);
  }

  elementForNode(node) {
    return node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
  }

  offsetWithinAnnotatable(node, offset) {
    const walker = document.createTreeWalker(this.annotatableTarget, NodeFilter.SHOW_TEXT);
    let position = 0;

    while (walker.nextNode()) {
      const current = walker.currentNode;
      if (current === node) return position + offset;
      position += current.textContent.length;
    }

    return null;
  }

  renderAnnotations() {
    if (!this.composerIsOpen()) this.clearPendingHighlight();
    this.renderSavedHighlights();
    this.annotationListTarget.innerHTML = "";

    if (this.annotationsValue.length === 0) {
      this.annotationListTarget.appendChild(this.emptyAnnotationListItem());
      return;
    }

    this.annotationsValue.forEach((annotation) => {
      this.annotationListTarget.appendChild(this.annotationListItem(annotation));
    });
  }

  applyPendingHighlight(selection) {
    const range = this.rangeForOffsets(selection.startOffset, selection.endOffset);
    if (!range) return;

    this.setHighlight(PENDING_HIGHLIGHT_NAME, [range]);
  }

  renderSavedHighlights() {
    const ranges = this.annotationsValue
      .map((annotation) => {
        if (this.editingAnnotationId && String(annotation.id) === String(this.editingAnnotationId)) return null;

        const startOffset = Number(annotation.start_offset);
        const endOffset = Number(annotation.end_offset);
        if (!Number.isFinite(startOffset) || !Number.isFinite(endOffset) || endOffset <= startOffset) return null;

        return this.rangeForOffsets(startOffset, endOffset);
      })
      .filter((range) => range !== null);

    this.setHighlight(SAVED_HIGHLIGHT_NAME, ranges);
  }

  setHighlight(name, ranges) {
    if (!this.highlightsSupported) return;

    this.clearHighlight(name);
    if (ranges.length === 0) return;

    const highlight = new Highlight();
    ranges.forEach((range) => highlight.add(range));
    CSS.highlights.set(name, highlight);
  }

  clearPendingHighlight() {
    this.clearHighlight(PENDING_HIGHLIGHT_NAME);
  }

  clearSavedHighlights() {
    this.clearHighlight(SAVED_HIGHLIGHT_NAME);
  }

  clearHighlight(name) {
    if (!this.highlightsSupported) return;

    CSS.highlights.delete(name);
  }

  rangeForOffsets(startOffset, endOffset) {
    const walker = document.createTreeWalker(this.annotatableTarget, NodeFilter.SHOW_TEXT);
    let position = 0;
    let startNode = null;
    let startPosition = 0;
    let endNode = null;
    let endPosition = 0;

    while (walker.nextNode()) {
      const node = walker.currentNode;
      const length = node.textContent.length;
      const nextPosition = position + length;

      if (!startNode && startOffset <= nextPosition) {
        startNode = node;
        startPosition = startOffset - position;
      }

      if (!endNode && endOffset <= nextPosition) {
        endNode = node;
        endPosition = endOffset - position;
        break;
      }

      position = nextPosition;
    }

    if (!startNode || !endNode) return null;

    const range = document.createRange();
    range.setStart(startNode, startPosition);
    range.setEnd(endNode, endPosition);
    return range;
  }

  emptyAnnotationListItem() {
    const item = document.createElement("p");
    item.className = "aa-annotations-empty";
    item.textContent = "No annotations yet.";
    return item;
  }

  annotationListItem(annotation) {
    const item = document.createElement("article");
    item.className = "aa-annotations-annotation-item";
    const categoryLabel = this.categoryLabelFor(annotation.category);
    item.innerHTML = `
      <blockquote>${this.escapeHtml(annotation.selected_text)}</blockquote>
      <p>${this.escapeHtml(annotation.comment)}</p>
      ${annotation.category ? `<p><strong>${this.escapeHtml(this.categoryLabelValue)}:</strong> ${this.escapeHtml(categoryLabel)}</p>` : ""}
      <div class="aa-annotations-annotation-actions">
        <button type="button" class="action-item-button" data-annotation-id="${this.escapeHtml(String(annotation.id))}" data-action="activeadmin-annotations--annotator#editAnnotation">Edit</button>
        <button type="button" class="action-item-button aa-annotations-delete-button" data-annotation-id="${this.escapeHtml(String(annotation.id))}" data-action="activeadmin-annotations--annotator#deleteAnnotation">Delete</button>
      </div>
    `;
    return item;
  }

  setComposerHeading(title) {
    if (this.hasComposerHeadingTarget) this.composerHeadingTarget.textContent = title;
  }

  categoryLabelFor(value) {
    if (!value) return "";
    return this.categoriesValue[value] || value;
  }

  annotationUrl(annotationId) {
    return this.updateUrlTemplateValue.replace(":id", annotationId);
  }

  normalizeAnnotation(annotation) {
    return {
      id: annotation.id,
      field_name: annotation.field_name,
      selected_text: annotation.selected_text,
      start_offset: annotation.start_offset,
      end_offset: annotation.end_offset,
      comment: annotation.comment,
      category: annotation.category,
    };
  }

  showError(message) {
    this.errorMessageTarget.textContent = message;
    this.errorMessageTarget.classList.remove("aa-annotations-hidden");
  }

  hideError() {
    this.errorMessageTarget.textContent = "";
    this.errorMessageTarget.classList.add("aa-annotations-hidden");
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']");
    return meta ? meta.getAttribute("content") : "";
  }

  escapeHtml(value) {
    return value
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }
}
