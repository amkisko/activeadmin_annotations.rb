import test from "node:test"
import assert from "node:assert/strict"
import {
  categoryLabelFor,
  createAnnotationPayload,
  escapeHtml,
  highlightsSupported,
  normalizeAnnotation,
  savedHighlightOffsetPairs,
} from "../../app/assets/javascripts/activeadmin_annotations/annotator_logic.mjs"

test("escapeHtml encodes markup in annotation list HTML", () => {
  assert.equal(
    escapeHtml('<b class="x">&copy;</b>'),
    "&lt;b class=&quot;x&quot;&gt;&amp;copy;&lt;/b&gt;",
  )
})

test("categoryLabelFor uses the catalog label or the raw value", () => {
  assert.equal(categoryLabelFor("typo", { typo: "Typo" }), "Typo")
  assert.equal(categoryLabelFor("unknown", { typo: "Typo" }), "unknown")
  assert.equal(categoryLabelFor("", { typo: "Typo" }), "")
})

test("createAnnotationPayload attaches the review when one exists", () => {
  const payload = createAnnotationPayload(
    {
      fieldValue: "body",
      pendingSelection: { selectedText: "Hello", startOffset: 0, endOffset: 5 },
      categoryInputTarget: { value: "typo" },
      reviewIdValue: "12",
      hasContentRevisionVersionValue: false,
    },
    "Fix this.",
  )

  assert.deepEqual(payload, {
    annotation: {
      field_name: "body",
      selected_text: "Hello",
      start_offset: 0,
      end_offset: 5,
      comment: "Fix this.",
      category: "typo",
      context_paths_json: [],
      annotation_review_id: "12",
    },
  })
})

test("createAnnotationPayload includes the subject on the first save", () => {
  const payload = createAnnotationPayload(
    {
      fieldValue: "body",
      pendingSelection: { selectedText: "Hello", startOffset: 0, endOffset: 5 },
      categoryInputTarget: { value: "" },
      reviewIdValue: "",
      subjectTypeValue: "Post",
      subjectIdValue: "3",
      contextValue: { locale: "en" },
      contextDigestValue: "abc",
      hasContentRevisionVersionValue: true,
      contentRevisionVersionValue: 4,
    },
    "Note",
  )

  assert.equal(payload.annotation.category, null)
  assert.equal(payload.annotation.subject_type, "Post")
  assert.equal(payload.annotation.subject_id, "3")
  assert.deepEqual(payload.annotation.context_json, { locale: "en" })
  assert.equal(payload.annotation.context_digest, "abc")
  assert.equal(payload.annotation.displayed_content_revision_version, 4)
  assert.equal("annotation_review_id" in payload.annotation, false)
})

test("normalizeAnnotation keeps the fields the list paints", () => {
  assert.deepEqual(
    normalizeAnnotation({
      id: 9,
      field_name: "body",
      selected_text: "Hello",
      start_offset: 0,
      end_offset: 5,
      comment: "Note",
      category: "typo",
      extra: "drop",
    }),
    {
      id: 9,
      field_name: "body",
      selected_text: "Hello",
      start_offset: 0,
      end_offset: 5,
      comment: "Note",
      category: "typo",
    },
  )
})

test("savedHighlightOffsetPairs omits the span being edited and invalid ranges", () => {
  const pairs = savedHighlightOffsetPairs(
    [
      { id: 1, start_offset: 0, end_offset: 4 },
      { id: 2, start_offset: 8, end_offset: 12 },
      { id: 3, start_offset: 5, end_offset: 5 },
    ],
    2,
  )

  assert.deepEqual(pairs, [[0, 4]])
})

test("highlightsSupported follows CSS.highlights", () => {
  const originalCss = globalThis.CSS
  try {
    globalThis.CSS = undefined
    assert.equal(highlightsSupported(), false)

    globalThis.CSS = { highlights: new Map() }
    assert.equal(highlightsSupported(), true)
  } finally {
    globalThis.CSS = originalCss
  }
})
