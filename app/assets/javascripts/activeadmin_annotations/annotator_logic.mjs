export function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
}

export function categoryLabelFor(value, categories) {
  if (!value) return ""
  return categories[value] || value
}

export function createAnnotationPayload(panel, comment) {
  const payload = {
    annotation: {
      field_name: panel.fieldValue,
      selected_text: panel.pendingSelection.selectedText,
      start_offset: panel.pendingSelection.startOffset,
      end_offset: panel.pendingSelection.endOffset,
      comment: comment,
      category: panel.categoryInputTarget.value || null,
      context_paths_json: [],
    },
  }

  if (panel.reviewIdValue) {
    payload.annotation.annotation_review_id = panel.reviewIdValue
  } else {
    payload.annotation.subject_type = panel.subjectTypeValue
    payload.annotation.subject_id = panel.subjectIdValue
    payload.annotation.context_json = panel.contextValue
    payload.annotation.context_digest = panel.contextDigestValue
  }

  if (panel.hasContentRevisionVersionValue) {
    payload.annotation.displayed_content_revision_version = panel.contentRevisionVersionValue
  }

  return payload
}

export function normalizeAnnotation(annotation) {
  return {
    id: annotation.id,
    field_name: annotation.field_name,
    selected_text: annotation.selected_text,
    start_offset: annotation.start_offset,
    end_offset: annotation.end_offset,
    comment: annotation.comment,
    category: annotation.category,
  }
}

export function savedHighlightOffsetPairs(annotations, editingAnnotationId) {
  return annotations.flatMap((annotation) => {
    if (editingAnnotationId && String(annotation.id) === String(editingAnnotationId)) {
      return []
    }

    const startOffset = Number(annotation.start_offset)
    const endOffset = Number(annotation.end_offset)
    if (!Number.isFinite(startOffset) || !Number.isFinite(endOffset) || endOffset <= startOffset) {
      return []
    }

    return [[startOffset, endOffset]]
  })
}

export function highlightsSupported() {
  return typeof CSS !== "undefined" && Boolean(CSS.highlights)
}
