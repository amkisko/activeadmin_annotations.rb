import { createAnnotationPayload, normalizeAnnotation } from "activeadmin_annotations/annotator_logic";

export class Composer {
  constructor(controller) {
    this.controller = controller;
  }

  activate(selection) {
    const panel = this.controller;
    panel.editingAnnotationId = null;

    const selectionChanged =
      !panel.pendingSelection ||
      panel.pendingSelection.startOffset !== selection.startOffset ||
      panel.pendingSelection.endOffset !== selection.endOffset ||
      panel.pendingSelection.selectedText !== selection.selectedText;

    panel.pendingSelection = selection;
    panel.selectedPreviewTarget.textContent = selection.selectedText;

    if (selectionChanged) {
      panel.commentInputTarget.value = "";
      panel.categoryInputTarget.value = "";
    }

    this.hideError();
    this.setHeading("New annotation");
    panel.composerTarget.classList.remove("aa-annotations-composer-hidden");
    panel.applyPendingHighlight(selection);
    window.getSelection()?.removeAllRanges();
  }

  edit(annotation) {
    const panel = this.controller;
    panel.editingAnnotationId = annotation.id;
    panel.pendingSelection = {
      selectedText: annotation.selected_text,
      startOffset: Number(annotation.start_offset),
      endOffset: Number(annotation.end_offset),
    };
    panel.selectedPreviewTarget.textContent = annotation.selected_text;
    panel.commentInputTarget.value = annotation.comment;
    panel.categoryInputTarget.value = annotation.category || "";
    this.hideError();
    this.setHeading("Edit annotation");
    panel.composerTarget.classList.remove("aa-annotations-composer-hidden");
    panel.applyPendingHighlight(panel.pendingSelection);
    window.getSelection()?.removeAllRanges();
    panel.commentInputTarget.focus();
  }

  reset() {
    const panel = this.controller;
    panel.pendingSelection = null;
    panel.editingAnnotationId = null;
    panel.clearPendingHighlight();
    panel.selectedPreviewTarget.textContent = "";
    panel.commentInputTarget.value = "";
    panel.categoryInputTarget.value = "";
    this.hideError();
    this.setHeading("New annotation");
    panel.composerTarget.classList.add("aa-annotations-composer-hidden");
  }

  cancel() {
    this.reset();
    window.getSelection()?.removeAllRanges();
  }

  isOpen() {
    return !this.controller.composerTarget.classList.contains("aa-annotations-composer-hidden");
  }

  ensurePendingHighlight() {
    if (!this.controller.pendingSelection) return;
    this.controller.applyPendingHighlight(this.controller.pendingSelection);
  }

  async submit() {
    const panel = this.controller;
    if (panel.readonlyValue) return;
    if (!panel.pendingSelection) return;

    const comment = panel.commentInputTarget.value.trim();
    if (!comment) {
      this.showError("Comment is required.");
      return;
    }

    if (panel.editingAnnotationId) {
      await this.update(comment);
      return;
    }

    await this.create(comment);
  }

  async create(comment) {
    const panel = this.controller;

    try {
      const annotation = await panel.annotationClient.create(
        panel.createUrlValue,
        this.createPayload(comment)
      );
      if (annotation.annotation_review_id) panel.reviewIdValue = annotation.annotation_review_id;
      this.reset();
      panel.annotationsValue = [...panel.annotationsValue, this.normalize(annotation)];
      panel.renderAnnotations();
      window.getSelection()?.removeAllRanges();
    } catch (_error) {
      this.showError("Could not save annotation.");
    }
  }

  async update(comment) {
    const panel = this.controller;
    const payload = {
      annotation: {
        comment: comment,
        category: panel.categoryInputTarget.value || null,
      },
    };

    try {
      const annotation = await panel.annotationClient.update(
        panel.annotationUrl(panel.editingAnnotationId),
        payload
      );
      this.reset();
      panel.annotationsValue = panel.annotationsValue.map((entry) =>
        String(entry.id) === String(annotation.id) ? this.normalize(annotation) : entry
      );
      panel.renderAnnotations();
    } catch (_error) {
      this.showError("Could not update annotation.");
    }
  }

  async destroy(annotationId) {
    const panel = this.controller;

    try {
      await panel.annotationClient.destroy(panel.annotationUrl(annotationId));
      if (String(panel.editingAnnotationId) === String(annotationId)) this.reset();
      panel.annotationsValue = panel.annotationsValue.filter(
        (entry) => String(entry.id) !== String(annotationId)
      );
      panel.renderAnnotations();
    } catch (_error) {
      window.alert("Could not delete annotation.");
    }
  }

  createPayload(comment) {
    return createAnnotationPayload(this.controller, comment);
  }

  normalize(annotation) {
    return normalizeAnnotation(annotation);
  }

  setHeading(title) {
    const panel = this.controller;
    if (panel.hasComposerHeadingTarget) panel.composerHeadingTarget.textContent = title;
  }

  showError(message) {
    const panel = this.controller;
    panel.errorMessageTarget.textContent = message;
    panel.errorMessageTarget.classList.remove("aa-annotations-hidden");
  }

  hideError() {
    const panel = this.controller;
    panel.errorMessageTarget.textContent = "";
    panel.errorMessageTarget.classList.add("aa-annotations-hidden");
  }
}
