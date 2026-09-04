import { categoryLabelFor, escapeHtml } from "activeadmin_annotations/annotator_logic";

export function emptyAnnotationListItem() {
  const item = document.createElement("p");
  item.className = "aa-annotations-empty";
  item.textContent = "No annotations yet.";
  return item;
}

export function annotationListItem(annotation, { readonly, categoryLabel, categories }) {
  const item = document.createElement("article");
  item.className = "aa-annotations-annotation-item";
  const resolvedCategory = categoryLabelFor(annotation.category, categories);
  const actions = readonly
    ? ""
    : `
      <div class="aa-annotations-annotation-actions">
        <button type="button" class="action-item-button" data-annotation-id="${escapeHtml(String(annotation.id))}" data-action="activeadmin-annotations--annotator#editAnnotation">Edit</button>
        <button type="button" class="action-item-button aa-annotations-delete-button" data-annotation-id="${escapeHtml(String(annotation.id))}" data-action="activeadmin-annotations--annotator#deleteAnnotation">Delete</button>
      </div>
    `;
  item.innerHTML = `
      <blockquote>${escapeHtml(annotation.selected_text)}</blockquote>
      <p>${escapeHtml(annotation.comment)}</p>
      ${annotation.category ? `<p><strong>${escapeHtml(categoryLabel)}:</strong> ${escapeHtml(resolvedCategory)}</p>` : ""}
      ${actions}
    `;
  return item;
}
