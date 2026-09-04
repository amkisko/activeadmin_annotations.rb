export function currentSelection(selection, annotatable) {
  if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return null;

  const range = selection.getRangeAt(0);
  if (!selectionInsideAnnotatable(range, annotatable)) return null;

  const selectedText = selection.toString().trim();
  if (!selectedText) return null;

  const startOffset = offsetWithinAnnotatable(annotatable, range.startContainer, range.startOffset);
  const endOffset = offsetWithinAnnotatable(annotatable, range.endContainer, range.endOffset);
  if (startOffset === null || endOffset === null || endOffset <= startOffset) return null;

  return { selectedText, startOffset, endOffset };
}

export function rangeForOffsets(annotatable, startOffset, endOffset) {
  const walker = document.createTreeWalker(annotatable, NodeFilter.SHOW_TEXT);
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

function selectionInsideAnnotatable(range, annotatable) {
  const startElement = elementForNode(range.startContainer);
  const endElement = elementForNode(range.endContainer);
  return annotatable.contains(startElement) && annotatable.contains(endElement);
}

function elementForNode(node) {
  return node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
}

function offsetWithinAnnotatable(annotatable, node, offset) {
  const walker = document.createTreeWalker(annotatable, NodeFilter.SHOW_TEXT);
  let position = 0;

  while (walker.nextNode()) {
    const current = walker.currentNode;
    if (current === node) return position + offset;
    position += current.textContent.length;
  }

  return null;
}
