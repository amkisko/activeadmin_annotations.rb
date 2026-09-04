import { Controller } from "@hotwired/stimulus";
import { currentSelection } from "activeadmin_annotations/selection";
import { savedHighlightOffsetPairs } from "activeadmin_annotations/annotator_logic";
import {
  HighlightLayer,
  PENDING_HIGHLIGHT_NAME,
  SAVED_HIGHLIGHT_NAME,
} from "activeadmin_annotations/highlights";
import { emptyAnnotationListItem, annotationListItem } from "activeadmin_annotations/annotation_list";
import { AnnotationClient, csrfToken } from "activeadmin_annotations/annotation_client";
import { Composer } from "activeadmin_annotations/composer";

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
    subjectType: String,
    subjectId: String,
    context: { type: Object, default: {} },
    contextDigest: String,
    contentRevisionVersion: Number,
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
    this.highlightLayer = new HighlightLayer(this.annotatableTarget);
    this.annotationClient = new AnnotationClient({ csrfToken: csrfToken() });
    this.composer = new Composer(this);
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
    this.highlightLayer.disconnect();
  }

  commitAnnotatableSelection = () => {
    if (this.readonlyValue) return;

    requestAnimationFrame(() => {
      const selection = this.currentSelection();
      if (selection) this.composer.activate(selection);
    });
  };

  handleSelectionChange = () => {
    if (this.readonlyValue) return;
    if (this.composer.isOpen()) this.composer.ensurePendingHighlight();
  };

  editAnnotation(event) {
    if (this.readonlyValue) return;

    const annotationId = event.currentTarget.dataset.annotationId;
    const annotation = this.annotationsValue.find((entry) => String(entry.id) === String(annotationId));
    if (!annotation) return;

    this.composer.edit(annotation);
  }

  async deleteAnnotation(event) {
    if (this.readonlyValue) return;

    const annotationId = event.currentTarget.dataset.annotationId;
    const annotation = this.annotationsValue.find((entry) => String(entry.id) === String(annotationId));
    if (!annotation) return;
    if (!window.confirm("Delete this annotation?")) return;

    await this.composer.destroy(annotationId);
  }

  cancelComposer() {
    this.composer.cancel();
  }

  async submitComposer() {
    await this.composer.submit();
  }

  handleDocumentKeydown = (event) => {
    if (event.key !== "Escape") return;
    if (!this.composer.isOpen()) return;

    this.composer.cancel();
  };

  currentSelection() {
    return currentSelection(window.getSelection(), this.annotatableTarget);
  }

  renderAnnotations() {
    if (!this.composer.isOpen()) this.clearPendingHighlight();
    this.renderSavedHighlights();
    this.annotationListTarget.innerHTML = "";

    if (this.annotationsValue.length === 0) {
      this.annotationListTarget.appendChild(emptyAnnotationListItem());
      return;
    }

    this.annotationsValue.forEach((annotation) => {
      this.annotationListTarget.appendChild(
        annotationListItem(annotation, {
          readonly: this.readonlyValue,
          categoryLabel: this.categoryLabelValue,
          categories: this.categoriesValue,
        })
      );
    });
  }

  applyPendingHighlight(selection) {
    this.highlightLayer.set(PENDING_HIGHLIGHT_NAME, [
      [selection.startOffset, selection.endOffset],
    ]);
  }

  renderSavedHighlights() {
    this.highlightLayer.set(
      SAVED_HIGHLIGHT_NAME,
      savedHighlightOffsetPairs(this.annotationsValue, this.editingAnnotationId)
    );
  }

  clearPendingHighlight() {
    this.highlightLayer.clear(PENDING_HIGHLIGHT_NAME);
  }

  annotationUrl(annotationId) {
    return this.updateUrlTemplateValue.replace(":id", annotationId);
  }
}
