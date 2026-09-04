import { rangeForOffsets } from "activeadmin_annotations/selection";

export const PENDING_HIGHLIGHT_NAME = "aa-annotations-pending";
export const SAVED_HIGHLIGHT_NAME = "aa-annotations-saved";

const MARK_CLASS_BY_NAME = {
  [PENDING_HIGHLIGHT_NAME]: "aa-annotations-mark aa-annotations-mark--pending",
  [SAVED_HIGHLIGHT_NAME]: "aa-annotations-mark aa-annotations-mark--saved",
};

export function highlightsSupported() {
  return typeof CSS !== "undefined" && Boolean(CSS.highlights);
}

export class HighlightLayer {
  constructor(root) {
    this.root = root;
    this.supported = highlightsSupported();
  }

  set(name, offsetPairs) {
    this.clear(name);
    if (offsetPairs.length === 0) return;

    if (this.supported) {
      const highlight = new Highlight();
      offsetPairs.forEach(([startOffset, endOffset]) => {
        const range = rangeForOffsets(this.root, startOffset, endOffset);
        if (range) highlight.add(range);
      });
      CSS.highlights.set(name, highlight);
      return;
    }

    offsetPairs.forEach(([startOffset, endOffset]) => {
      const range = rangeForOffsets(this.root, startOffset, endOffset);
      if (range) this.wrapRange(range, name);
    });
  }

  clear(name) {
    if (this.supported) {
      CSS.highlights.delete(name);
      return;
    }

    this.root.querySelectorAll(`mark[data-aa-highlight="${name}"]`).forEach((mark) => {
      const parent = mark.parentNode;
      if (!parent) return;

      while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
      parent.removeChild(mark);
      parent.normalize();
    });
  }

  disconnect() {
    this.clear(PENDING_HIGHLIGHT_NAME);
    this.clear(SAVED_HIGHLIGHT_NAME);
  }

  wrapRange(range, name) {
    if (range.collapsed) return;

    const mark = document.createElement("mark");
    mark.dataset.aaHighlight = name;
    mark.className = MARK_CLASS_BY_NAME[name] || "aa-annotations-mark";

    try {
      range.surroundContents(mark);
    } catch {
      const contents = range.extractContents();
      mark.appendChild(contents);
      range.insertNode(mark);
    }
  }
}
