import { Controller } from "@hotwired/stimulus"
import Trix from "trix"
import Rails from "@rails/ujs"

const MAX_PARENT_SEARCH_DEPTH = 5;


// Make table cells editable (Trix strips contenteditable attribute)
function makeTableCellsEditable() {
  document.querySelectorAll('td.table-cell:not([contenteditable])').forEach(td => {
    td.setAttribute('contenteditable', 'true');
  });
  // Also handle old format with inputs
  document.querySelectorAll('.table-editor td:not([contenteditable]), figure[data-trix-attachment] td:not([contenteditable])').forEach(td => {
    td.setAttribute('contenteditable', 'true');
  });
}

// Run on page load and Turbo navigation
document.addEventListener('DOMContentLoaded', makeTableCellsEditable);
document.addEventListener('turbo:load', makeTableCellsEditable);
document.addEventListener('trix-attachment-add', makeTableCellsEditable);

// Click on cell to make it editable (use capture phase to get event before Trix)
document.addEventListener('click', function(event) {
  const td = event.target.closest('td');
  if (td && (td.classList.contains('table-cell') || td.closest('figure[data-trix-attachment]'))) {
    event.stopPropagation();
    event.preventDefault();
    td.setAttribute('contenteditable', 'true');
    // Use setTimeout to ensure focus happens after Trix processing
    setTimeout(() => {
      td.focus();
      // Place cursor at end of content
      const range = document.createRange();
      const sel = window.getSelection();
      if (td.childNodes.length > 0) {
        range.selectNodeContents(td);
        range.collapse(false);
        sel.removeAllRanges();
        sel.addRange(range);
      }
    }, 10);
  }
}, true);

// Mousedown to prepare cell
document.addEventListener('mousedown', function(event) {
  const td = event.target.closest('td');
  if (td && (td.classList.contains('table-cell') || td.closest('figure[data-trix-attachment]'))) {
    td.setAttribute('contenteditable', 'true');
  }
}, true);

// Prevent Trix from intercepting keyboard events in table cells
document.addEventListener('keydown', function(event) {
  const td = event.target.closest('td[contenteditable="true"]');
  if (!td) return;

  const inTableAttachment = td.classList.contains('table-cell') || td.closest('figure[data-trix-attachment]');
  if (!inTableAttachment) return;

  // Always stop propagation to prevent Trix interference
  event.stopPropagation();
  event.stopImmediatePropagation();

  // Prevent backspace/delete from triggering attachment deletion
  if (event.key === 'Backspace' || event.key === 'Delete') {
    const content = td.textContent || '';
    // Prevent if cell is empty or has only 1 character (would become empty)
    if (content.length <= 1) {
      event.preventDefault();
      // Clear the cell content manually if there's 1 char
      if (content.length === 1) {
        td.textContent = '';
      }
    }
  }
}, true);

document.addEventListener('keyup', function(event) {
  const td = event.target.closest('td[contenteditable="true"]');
  if (td && (td.classList.contains('table-cell') || td.closest('figure[data-trix-attachment]'))) {
    event.stopPropagation();
    event.stopImmediatePropagation();
  }
}, true);

document.addEventListener('keypress', function(event) {
  const td = event.target.closest('td[contenteditable="true"]');
  if (td && (td.classList.contains('table-cell') || td.closest('figure[data-trix-attachment]'))) {
    event.stopPropagation();
    event.stopImmediatePropagation();
  }
}, true);

// Find table editor container (supports old and new format)
function findTableEditor(element) {
  // New format: .table-editor
  let editor = element.closest('.table-editor');
  if (editor) return editor;

  // Old format: [data-controller="table-editor"]
  editor = element.closest('[data-controller="table-editor"]');
  if (editor) return editor;

  // Fallback: find the div inside a figure with data-trix-attachment
  const figure = element.closest('figure[data-trix-attachment]');
  if (figure) {
    // The first div inside the figure is our table editor
    editor = figure.querySelector('div');
    if (editor) return editor;
  }

  // Last resort: find parent div containing the table
  const table = element.closest('table');
  if (table) {
    return table.parentElement;
  }

  return null;
}

// Event delegation for table editors inside Trix attachments
document.addEventListener('click', function(event) {
  const target = event.target;

  // Handle Add Row button (new class or old text content)
  if (target.classList.contains('table-add-row') ||
      (target.tagName === 'BUTTON' && target.textContent.includes('Ajouter 1 Ligne')) ||
      target.closest('.table-add-row')) {
    event.preventDefault();
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      if (sgid) {
        tableAction(tableEditor, sgid, 'addRow');
      }
    }
  }

  // Handle Add Column button (new class or old text content)
  if (target.classList.contains('table-add-column') ||
      (target.tagName === 'BUTTON' && target.textContent.includes('Ajouter 1 Colonne')) ||
      target.closest('.table-add-column')) {
    event.preventDefault();
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      if (sgid) {
        tableAction(tableEditor, sgid, 'addColumn');
      }
    }
  }

  // Handle Remove Row button
  if (target.classList.contains('table-remove-row') || target.closest('.table-remove-row')) {
    event.preventDefault();
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      if (sgid) {
        tableAction(tableEditor, sgid, 'removeRow');
      }
    }
  }

  // Handle Remove Column button
  if (target.classList.contains('table-remove-column') || target.closest('.table-remove-column')) {
    event.preventDefault();
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      if (sgid) {
        tableAction(tableEditor, sgid, 'removeColumn');
      }
    }
  }

});

// Calculate cell key from DOM position
function getCellKey(element) {
  // First try data-key attribute
  const dataKey = element.dataset?.key || element.getAttribute('data-key');
  if (dataKey) return dataKey;

  // Calculate from DOM position
  const td = element.tagName === 'TD' ? element : element.closest('td');
  const tr = td?.closest('tr');
  const table = tr?.closest('table');

  if (td && tr && table) {
    const rows = Array.from(table.querySelectorAll('tr'));
    const rowIndex = rows.indexOf(tr);
    const cells = Array.from(tr.querySelectorAll('td'));
    const colIndex = cells.indexOf(td);

    if (rowIndex >= 0 && colIndex >= 0) {
      return `${rowIndex}-${colIndex}`;
    }
  }

  return null;
}

// Get cell value (works for both input and contenteditable)
function getCellValue(element) {
  if (element.tagName === 'INPUT') {
    return element.value;
  }
  return element.textContent || '';
}

// Event delegation for cell updates (input elements)
document.addEventListener('change', function(event) {
  const target = event.target;

  // Handle input elements (old format)
  if (target.tagName === 'INPUT' && target.classList.contains('table-input')) {
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      const key = getCellKey(target);
      if (sgid && key) {
        cellAction(tableEditor, sgid, key, target.value);
      }
    }
  }
});

// Event delegation for contenteditable cells (new format)
document.addEventListener('blur', function(event) {
  const target = event.target;

  // Handle contenteditable td cells
  if (target.tagName === 'TD' && target.hasAttribute('contenteditable')) {
    const tableEditor = findTableEditor(target);
    if (tableEditor) {
      const sgid = getSgidFromElement(tableEditor);
      const key = getCellKey(target);
      if (sgid && key) {
        cellAction(tableEditor, sgid, key, getCellValue(target));
      }
    }
  }
}, true); // Use capture phase for blur event

function getSgidFromElement(tableEditor) {
  // New format: id="table-SGID"
  const id = tableEditor.id || tableEditor.getAttribute('id');
  if (id && id.startsWith('table-')) {
    return id.substring(6);
  }

  // Old format: data-table-editor-id="SGID"
  const oldId = tableEditor.dataset?.tableEditorId || tableEditor.getAttribute('data-table-editor-id');
  if (oldId) {
    return oldId;
  }

  // Fallback: look for sgid in parent figure's data-trix-attachment
  const figure = tableEditor.closest('figure[data-trix-attachment]');
  if (figure) {
    try {
      const attachmentData = JSON.parse(figure.getAttribute('data-trix-attachment'));
      return attachmentData.sgid;
    } catch (e) {
      console.error('Error parsing trix attachment data', e);
    }
  }

  return null;
}

function findTrixEditor(element) {
  let parent = element.parentNode;
  for (let i = 0; i < MAX_PARENT_SEARCH_DEPTH; i++) {
    const editorNode = parent.querySelector('trix-editor');
    if (editorNode != null) {
      return editorNode;
    }
    parent = parent.parentNode;
    if (!parent) break;
  }
  return null;
}

function findTrixAttachment(element, sgid) {
  const trixEditor = findTrixEditor(element);
  if (!trixEditor || !trixEditor.editor) return null;

  const attachments = trixEditor.editor.composition.attachments;
  return attachments.find(a => a.attributes.values.sgid === sgid);
}

function updateTrixAndDom(tableEditor, sgid, tableAttachment) {
  // Update Trix internal state (for saving)
  const attachment = findTrixAttachment(tableEditor, sgid);
  if (attachment) {
    attachment.setAttributes({
      content: tableAttachment.content,
      sgid: tableAttachment.sgid
    });
  }

  // Update visible DOM (for display)
  const parser = new DOMParser();
  const doc = parser.parseFromString(tableAttachment.content, 'text/html');
  const newTable = doc.querySelector('table');
  const currentTable = tableEditor.querySelector('table');
  if (newTable && currentTable) {
    currentTable.innerHTML = newTable.innerHTML;
    // Re-add contenteditable after DOM update
    makeTableCellsEditable();
  }
}

function tableAction(tableEditor, sgid, method) {
  Rails.ajax({
    url: `/tables/${sgid}`,
    data: `method=${method}`,
    type: 'patch',
    success: function(response) {
      updateTrixAndDom(tableEditor, sgid, response);
    }
  });
}

function cellAction(tableEditor, sgid, key, value) {
  Rails.ajax({
    url: `/tables/${sgid}`,
    data: `method=updateCell&cell=${encodeURIComponent(key)}&value=${encodeURIComponent(value)}`,
    type: 'patch',
    success: function(response) {
      updateTrixAndDom(tableEditor, sgid, response);
    }
  });
}

// Keep the Stimulus controller for backwards compatibility (outside Trix)
export default class extends Controller {

  addRow(event) {
    const sgid = this.getID();
    tableAction(this.element, sgid, 'addRow');
  }

  addColumn(event) {
    const sgid = this.getID();
    tableAction(this.element, sgid, 'addColumn');
  }

  updateCell(event) {
    const sgid = this.getID();
    const key = event.target.dataset.key;
    cellAction(this.element, sgid, key, event.target.value);
  }

  getID() {
    return this.data.get('id');
  }

  attachTable(tableAttachment) {
    let attachment = new Trix.Attachment(tableAttachment)
    let parent = this.element.parentNode;
    let editorNode = null;
    for (let i = 0; i < MAX_PARENT_SEARCH_DEPTH; i++) {
      editorNode = parent.querySelector('trix-editor');
      if (editorNode != null) {
        break;
      }
      parent = parent.parentNode;
    }
    if (editorNode) {
      editorNode.editor.insertAttachment(attachment);
    }
  }
}
