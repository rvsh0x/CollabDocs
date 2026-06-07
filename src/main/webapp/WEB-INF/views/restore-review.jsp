<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Revue de restauration — ${doc.title}" />
<%@ include file="layout/header.jsp" %>

<style>
/* ── Panels de comparaison ── */
.review-panel {
  height: 600px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  padding: 0;
}
.review-panel-head {
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}
.review-panel-body {
  flex: 1;
  overflow: auto;
  position: relative;
}

/* CODE */
.review-code-wrap {
  height: 100%;
  overflow: auto;
  background: #0d1117;
}
.review-code-wrap pre {
  margin: 0;
  padding: 16px;
  height: 100%;
  box-sizing: border-box;
  font-size: 13px;
  line-height: 1.55;
}

/* RICHTEXT — Quill readonly */
.ql-container.ql-snow.ql-readonly-wrap {
  border: none !important;
  height: 100%;
  font-size: 14px;
}
.ql-editor { padding: 20px; }

/* SPREADSHEET */
.review-spreadsheet {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}
.review-spreadsheet th,
.review-spreadsheet td {
  border: 1px solid #d1d5db;
  padding: 4px 8px;
  white-space: nowrap;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
}
.review-spreadsheet th {
  background: #f3f4f6;
  font-weight: 600;
  text-align: center;
  position: sticky;
  top: 0;
  z-index: 1;
}
.review-spreadsheet td:first-child {
  background: #f9fafb;
  font-weight: 600;
  text-align: center;
  position: sticky;
  left: 0;
}

/* PRESENTATION */
.review-presentation {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.review-slide-thumb {
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  overflow: hidden;
  background: #fff;
}
.review-slide-label {
  font-size: 11px;
  color: #6b7280;
  padding: 4px 10px;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}
.review-slide-inner {
  position: relative;
  width: 100%;
  padding-top: 56.25%;
  background: #fff;
}
.review-slide-inner-content {
  position: absolute;
  inset: 0;
  overflow: hidden;
}

/* PLANNING */
.review-planning {
  padding: 12px;
  font-size: 13px;
}
.review-planning-task {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  border-radius: 6px;
  margin-bottom: 6px;
  background: #f1f5f9;
  border-left: 4px solid #4f7ef8;
}
.review-planning-task .task-title { font-weight: 600; flex: 1; }
.review-planning-task .task-dates { font-size: 11px; color: #6b7280; }
.review-planning-task .task-badge {
  font-size: 10px;
  padding: 2px 7px;
  border-radius: 12px;
  background: #e0e7ff;
  color: #3730a3;
}

/* MINDMAP */
.review-mindmap-wrap {
  width: 100%;
  height: 100%;
  overflow: auto;
  background: #fafafa;
}
.review-mindmap-wrap svg { display: block; }

/* DIAGRAM */
.review-diagram-wrap {
  width: 100%;
  height: 100%;
  overflow: auto;
  background: #f8fafc;
  display: flex;
  align-items: flex-start;
  justify-content: flex-start;
  padding: 12px;
}

/* PIXELART */
.review-pixelart-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  background: #f1f5f9;
}
.review-pixelart-wrap canvas {
  image-rendering: pixelated;
  image-rendering: crisp-edges;
  box-shadow: 0 2px 12px rgba(0,0,0,.15);
}

/* JSON fallback */
.review-json-raw {
  margin: 0;
  padding: 16px;
  font-size: 12px;
  font-family: 'Courier New', monospace;
  white-space: pre-wrap;
  word-break: break-all;
  color: #374151;
  line-height: 1.5;
}

/* Loading state */
.review-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #9ca3af;
  font-size: 14px;
}
</style>

<%-- Dépendances conditionnelles --%>
<c:if test="${doc.docType == 'RICHTEXT'}">
  <link rel="stylesheet" href="https://cdn.quilljs.com/1.3.7/quill.snow.css">
  <script src="https://cdn.quilljs.com/1.3.7/quill.min.js"></script>
</c:if>
<c:if test="${doc.docType == 'CODE'}">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
</c:if>

<section class="section">
  <div class="container is-fluid">

    <div class="level mb-3">
      <div class="level-left">
        <h1 class="title is-4">
          Demande de restauration —
          <span class="has-text-info"><c:out value="${doc.title}"/></span>
        </h1>
      </div>
      <div class="level-right">
        <a href="${pageContext.request.contextPath}/editor/${doc.id}"
           class="button is-light is-small">← Retour à l'éditeur</a>
      </div>
    </div>

    <div class="notification is-info is-light">
      <strong><c:out value="${restoreReq[6]}"/></strong> demande la restauration
      vers la version du
      <strong><fmt:formatDate value="${restoreReq[8]}" pattern="dd/MM/yyyy à HH:mm"/></strong>.
      Cette action est irréversible si vous l'approuvez.
    </div>

    <%-- Comparaison côte à côte --%>
    <div class="columns">

      <%-- GAUCHE : version actuelle --%>
      <div class="column">
        <div class="box review-panel">
          <div class="review-panel-head">
            <h2 class="subtitle is-5 has-text-grey-dark mb-1">
              Version actuelle
              <span class="tag is-light ml-2">
                <fmt:formatDate value="${doc.updatedAt}" pattern="dd/MM/yyyy HH:mm"/>
              </span>
            </h2>
          </div>
          <div class="review-panel-body" id="panelCurrent">
            <div class="review-loading">Chargement...</div>
          </div>
        </div>
      </div>

      <%-- DROITE : version demandée --%>
      <div class="column">
        <div class="box review-panel review-panel-target">
          <div class="review-panel-head">
            <h2 class="subtitle is-5 has-text-primary mb-1">
              Version demandée
              <span class="tag is-primary is-light ml-2">
                <fmt:formatDate value="${restoreReq[8]}" pattern="dd/MM/yyyy HH:mm"/>
              </span>
            </h2>
          </div>
          <div class="review-panel-body" id="panelTarget">
            <div class="review-loading">Chargement...</div>
          </div>
        </div>
      </div>

    </div>

    <%-- Boutons d'action --%>
    <div class="level mt-4">
      <div class="level-left"></div>
      <div class="level-right">
        <div class="buttons">
          <form method="post"
                action="${pageContext.request.contextPath}/document/restore/reject"
                onsubmit="return confirm('Rejeter cette demande ?');"
                style="display:inline;">
            <input type="hidden" name="requestId" value="${restoreReq[0]}">
            <button type="submit" class="button is-danger">Rejeter la demande</button>
          </form>
          <form method="post"
                action="${pageContext.request.contextPath}/document/restore/approve"
                onsubmit="return confirm('Approuver la restauration ? Le contenu actuel sera remplacé.');"
                style="display:inline;">
            <input type="hidden" name="requestId" value="${restoreReq[0]}">
            <button type="submit" class="button is-success ml-2">Approuver et restaurer</button>
          </form>
        </div>
      </div>
    </div>

  </div>
</section>

<%-- ═══════════════════════════════════════════════════════════
     DONNÉES & RENDU — injectées depuis le serveur
══════════════════════════════════════════════════════════ --%>
<%-- Injection securisee via balises JSON cachees --%>
<%-- Le contenu JSON est lu en textContent, jamais interprete comme JS --%>
<script type="application/json" id="reviewDocType"><c:out value="${doc.docType}" escapeXml="false"/></script>
<script type="application/json" id="reviewCurrentRaw"><c:out value="${doc.content}" escapeXml="false"/></script>
<script type="application/json" id="reviewTargetRaw"><c:out value="${restoreReq[7]}" escapeXml="false"/></script>

<script>
var REVIEW_DOC_TYPE    = document.getElementById('reviewDocType').textContent.trim();
var REVIEW_CURRENT_RAW = (function() {
  try { return JSON.parse(document.getElementById('reviewCurrentRaw').textContent); }
  catch(e) { return document.getElementById('reviewCurrentRaw').textContent || null; }
})();
var REVIEW_TARGET_RAW = (function() {
  try { return JSON.parse(document.getElementById('reviewTargetRaw').textContent); }
  catch(e) { return document.getElementById('reviewTargetRaw').textContent || null; }
})();

/* ── Parseur sécurisé ── */
function safeParse(raw) {
  if (raw === null || raw === undefined) return null;
  if (typeof raw === 'object') return raw;
  try { return JSON.parse(raw); } catch(e) { return null; }
}

/* ══════════════════════════════════════════
   DISPATCHER principal
══════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', function() {
  var panelC = document.getElementById('panelCurrent');
  var panelT = document.getElementById('panelTarget');

  if (!panelC || !panelT) return;

  /* Les donnees sont deja parsees dans REVIEW_CURRENT_RAW / REVIEW_TARGET_RAW */
  var currentData = REVIEW_CURRENT_RAW;
  var targetData  = REVIEW_TARGET_RAW;

  if (currentData === null || currentData === undefined || currentData === '') {
    panelC.innerHTML = '<p style="padding:20px;color:#9ca3af;font-size:13px;">Aucun contenu disponible pour cette version.</p>';
  }
  if (targetData === null || targetData === undefined || targetData === '') {
    panelT.innerHTML = '<p style="padding:20px;color:#9ca3af;font-size:13px;">Aucun contenu disponible pour cette version.</p>';
  }

  switch (REVIEW_DOC_TYPE) {
    case 'CODE':
      renderCode(panelC, currentData);
      renderCode(panelT, targetData);
      break;
    case 'RICHTEXT':
      renderRichtext(panelC, currentData);
      renderRichtext(panelT, targetData);
      break;
    case 'SPREADSHEET':
      renderSpreadsheet(panelC, currentData);
      renderSpreadsheet(panelT, targetData);
      break;
    case 'PRESENTATION':
      renderPresentation(panelC, currentData);
      renderPresentation(panelT, targetData);
      break;
    case 'PLANNING':
      renderPlanning(panelC, currentData);
      renderPlanning(panelT, targetData);
      break;
    case 'MINDMAP':
      renderMindmap(panelC, currentData);
      renderMindmap(panelT, targetData);
      break;
    case 'DIAGRAM':
      renderDiagram(panelC, currentData);
      renderDiagram(panelT, targetData);
      break;
    case 'PIXELART':
      renderPixelart(panelC, currentData);
      renderPixelart(panelT, targetData);
      break;
    default:
      renderFallback(panelC, REVIEW_CURRENT_RAW);
      renderFallback(panelT, REVIEW_TARGET_RAW);
  }
});

/* ══════════════════════════════════════════
   CODE
══════════════════════════════════════════ */
function renderCode(panel, data) {
  var lang = 'plaintext';
  var text = '';
  if (data && typeof data === 'object') {
    lang = data.language || 'plaintext';
    text = data.text || JSON.stringify(data, null, 2);
  } else {
    text = String(data || '');
  }

  var wrap = document.createElement('div');
  wrap.className = 'review-code-wrap';
  var pre  = document.createElement('pre');
  var code = document.createElement('code');
  code.className = 'language-' + lang;
  code.textContent = text;
  pre.appendChild(code);
  wrap.appendChild(pre);
  panel.innerHTML = '';
  panel.appendChild(wrap);

  if (window.hljs) hljs.highlightElement(code);
}

/* ══════════════════════════════════════════
   RICHTEXT (Quill delta)
══════════════════════════════════════════ */
function renderRichtext(panel, data) {
  var delta = null;
  if (data && data.delta) delta = data.delta;
  else if (data && data.ops) delta = data;

  var container = document.createElement('div');
  container.style.height = '100%';
  panel.innerHTML = '';
  panel.appendChild(container);

  if (!window.Quill) { panel.innerHTML = '<pre class="review-json-raw">' + escHtml(JSON.stringify(data, null, 2)) + '</pre>'; return; }

  var q = new Quill(container, {
    theme: 'snow',
    readOnly: true,
    modules: { toolbar: false }
  });
  // Masquer bordure Quill
  container.querySelector('.ql-toolbar') && (container.querySelector('.ql-toolbar').style.display = 'none');
  var qlContainer = container.querySelector('.ql-container');
  if (qlContainer) { qlContainer.style.border = 'none'; qlContainer.style.height = '100%'; }

  if (delta) {
    try { q.setContents(delta); } catch(e) {}
  } else if (typeof data === 'string') {
    q.setText(data);
  }
}

/* ══════════════════════════════════════════
   SPREADSHEET
   Format attendu : { sheets:[{ name, rows:[[cell,...],...]  }] }
   ou { rows:[[...]] } ou tableau 2D direct
══════════════════════════════════════════ */
function renderSpreadsheet(panel, data) {
  var rows = [];
  var sheetName = '';

  if (Array.isArray(data)) {
    rows = data;
  } else if (data && data.rows) {
    rows = data.rows;
    sheetName = data.name || '';
  } else if (data && data.sheets && data.sheets.length) {
    rows = data.sheets[0].rows || [];
    sheetName = data.sheets[0].name || '';
  } else if (data && data.cells) {
    // Format editeur : { rows, cols, cells:{ "r:c": {value, bold, italic} } }
    var maxR = (typeof data.rows === 'number') ? data.rows : 20;
    var maxC = (typeof data.cols === 'number') ? data.cols : 10;
    rows = [];
    for (var r = 0; r < maxR; r++) {
      var row = [];
      for (var c = 0; c < maxC; c++) {
        // Supporter "r:c" (nouveau) et "r,c" (ancien)
        var cell = data.cells[r + ':' + c] || data.cells[r + ',' + c] || '';
        // La cellule peut etre un objet {value, bold, italic} ou une string directe
        if (cell && typeof cell === 'object') cell = cell.value || '';
        row.push(cell);
      }
      rows.push(row);
    }
  } else {
    renderFallback(panel, data);
    return;
  }

  if (!rows.length) { panel.innerHTML = '<p style="padding:16px;color:#9ca3af;">Feuille vide</p>'; return; }

  var maxCols = 0;
  rows.forEach(function(r){ if ((r||[]).length > maxCols) maxCols = r.length; });

  // En-têtes colonnes A B C ...
  var colHeaders = [''];
  for (var ci = 0; ci < maxCols; ci++) {
    colHeaders.push(String.fromCharCode(65 + ci));
  }

  var html = '<div style="overflow:auto;height:100%;">';
  if (sheetName) html += '<div style="padding:6px 10px;font-size:11px;color:#6b7280;border-bottom:1px solid #e5e7eb;background:#f9fafb;">' + escHtml(sheetName) + '</div>';
  html += '<table class="review-spreadsheet"><thead><tr>';
  colHeaders.forEach(function(h) { html += '<th>' + escHtml(h) + '</th>'; });
  html += '</tr></thead><tbody>';

  rows.forEach(function(row, ri) {
    html += '<tr><td>' + (ri + 1) + '</td>';
    for (var ci2 = 0; ci2 < maxCols; ci2++) {
      var cell = (row && row[ci2] !== undefined && row[ci2] !== null) ? row[ci2] : '';
      var cellVal = typeof cell === 'object' ? (cell.v !== undefined ? cell.v : JSON.stringify(cell)) : cell;
      html += '<td title="' + escAttr(String(cellVal)) + '">' + escHtml(String(cellVal)) + '</td>';
    }
    html += '</tr>';
  });

  html += '</tbody></table></div>';
  panel.innerHTML = html;
}

/* ══════════════════════════════════════════
   PRESENTATION
   Format : { slides:[{ id, title, bg, elements:[...] }] }
══════════════════════════════════════════ */
function renderPresentation(panel, data) {
  var slides = [];
  if (data && data.slides) slides = data.slides;
  else if (Array.isArray(data)) slides = data;

  if (!slides.length) { panel.innerHTML = '<p style="padding:16px;color:#9ca3af;">Aucune slide</p>'; return; }

  var SLIDE_W = 960, SLIDE_H = 540;

  var wrap = document.createElement('div');
  wrap.className = 'review-presentation';
  panel.innerHTML = '';
  panel.appendChild(wrap);

  slides.forEach(function(sl, si) {
    var card = document.createElement('div');
    card.className = 'review-slide-thumb';

    var label = document.createElement('div');
    label.className = 'review-slide-label';
    label.textContent = (si + 1) + '. ' + (sl.title || 'Slide ' + (si + 1));
    card.appendChild(label);

    var inner = document.createElement('div');
    inner.className = 'review-slide-inner';
    var content = document.createElement('div');
    content.className = 'review-slide-inner-content';
    content.style.background = sl.bg || '#ffffff';
    inner.appendChild(content);
    card.appendChild(inner);
    wrap.appendChild(card);

    // Rendu inline des éléments (miniature CSS)
    var containerW = wrap.clientWidth - 24 || 300;
    var z = containerW / SLIDE_W;

    var elems = (sl.elements || []).slice().sort(function(a,b){ return (a.z||0)-(b.z||0); });
    elems.forEach(function(elem) {
      var d = document.createElement('div');
      d.style.cssText = 'position:absolute;box-sizing:border-box;overflow:hidden;'
        + 'left:'   + (elem.x * z) + 'px;'
        + 'top:'    + (elem.y * z) + 'px;'
        + 'width:'  + (elem.w * z) + 'px;'
        + 'height:' + (elem.h * z) + 'px;'
        + 'z-index:' + (elem.z || 1) + ';'
        + 'opacity:' + (elem.opacity !== undefined ? elem.opacity : 1) + ';'
        + 'border-radius:' + ((elem.radius||0)*z) + 'px;';

      if (elem.borderW) d.style.border = (elem.borderW*z) + 'px solid ' + (elem.borderColor||'#000');

      if (elem.type === 'text') {
        d.style.background    = elem.fill || 'transparent';
        d.style.color         = elem.color || '#000';
        d.style.fontSize      = (elem.fontSize * z) + 'px';
        d.style.fontFamily    = elem.fontFamily || 'Arial';
        d.style.fontWeight    = elem.bold ? '700' : '400';
        d.style.fontStyle     = elem.italic ? 'italic' : 'normal';
        d.style.textDecoration= elem.underline ? 'underline' : 'none';
        d.style.textAlign     = elem.align || 'left';
        d.style.lineHeight    = '1.35';
        d.style.padding       = (3*z) + 'px';
        d.style.whiteSpace    = 'pre-wrap';
        d.style.wordBreak     = 'break-word';
        d.textContent         = elem.text || '';
      } else if (elem.type === 'image' && elem.src) {
        var img = document.createElement('img');
        img.src = elem.src;
        img.style.cssText = 'width:100%;height:100%;object-fit:contain;';
        img.draggable = false;
        d.appendChild(img);
      } else {
        d.style.background = elem.fill || '#e2e8f0';
      }
      content.appendChild(d);
    });
  });
}

/* ══════════════════════════════════════════
   PLANNING
   Format : { tasks:[{ id, title, start, end, color, assignee, status, progress }] }
══════════════════════════════════════════ */
function renderPlanning(panel, data) {
  var tasks = [];
  if (data && data.tasks) tasks = data.tasks;
  else if (Array.isArray(data)) tasks = data;

  if (!tasks.length) { panel.innerHTML = '<p style="padding:16px;color:#9ca3af;">Aucune tâche</p>'; return; }

  // Déterminer plage de dates
  var minDate = null, maxDate = null;
  tasks.forEach(function(t) {
    var s = t.start ? new Date(t.start) : null;
    var e = t.end   ? new Date(t.end)   : null;
    if (s && (!minDate || s < minDate)) minDate = s;
    if (e && (!maxDate || e > maxDate)) maxDate = e;
  });

  var html = '<div class="review-planning">';

  // Mini Gantt si dates disponibles
  if (minDate && maxDate) {
    var totalMs = maxDate - minDate || 1;
    html += '<div style="margin-bottom:12px;font-size:11px;color:#6b7280;">'
          + fmtDate(minDate) + ' — ' + fmtDate(maxDate) + '</div>';

    tasks.forEach(function(t) {
      var s = t.start ? new Date(t.start) : minDate;
      var e = t.end   ? new Date(t.end)   : maxDate;
      var left  = Math.max(0, (s - minDate) / totalMs * 100);
      var width = Math.max(2, (e - s) / totalMs * 100);
      var color = t.color || '#4f7ef8';
      var pct   = t.progress !== undefined ? t.progress : 100;
      var status= t.status || '';

      html += '<div style="margin-bottom:10px;">'
            + '<div style="display:flex;justify-content:space-between;font-size:12px;margin-bottom:3px;">'
            + '<span style="font-weight:600;color:#1e293b;">' + escHtml(t.title || '') + '</span>'
            + '<span style="color:#6b7280;font-size:11px;">'
            + (t.assignee ? escHtml(t.assignee) + ' · ' : '')
            + fmtDate(s) + ' → ' + fmtDate(e)
            + (status ? ' · <em>' + escHtml(status) + '</em>' : '')
            + '</span></div>'
            + '<div style="position:relative;background:#f1f5f9;border-radius:4px;height:18px;overflow:hidden;">'
            + '<div style="position:absolute;left:' + left.toFixed(1) + '%;width:' + width.toFixed(1) + '%;height:100%;background:' + color + ';border-radius:4px;opacity:.85;"></div>'
            + (pct < 100 ? '<div style="position:absolute;left:' + left.toFixed(1) + '%;width:' + (width * pct / 100).toFixed(1) + '%;height:100%;background:' + color + ';border-radius:4px;"></div>' : '')
            + '</div>'
            + '</div>';
    });
  } else {
    // Liste simple sans dates
    tasks.forEach(function(t) {
      html += '<div class="review-planning-task">'
            + '<span class="task-title">' + escHtml(t.title || '') + '</span>'
            + (t.assignee ? '<span class="task-badge">' + escHtml(t.assignee) + '</span>' : '')
            + (t.status   ? '<span class="task-badge">' + escHtml(t.status)   + '</span>' : '')
            + '</div>';
    });
  }

  html += '</div>';
  panel.innerHTML = html;
}

function fmtDate(d) {
  if (!d) return '';
  var dt = (d instanceof Date) ? d : new Date(d);
  return dt.toLocaleDateString('fr-FR', { day:'2-digit', month:'2-digit', year:'2-digit' });
}

/* ══════════════════════════════════════════
   MINDMAP
   Format : { root:{ text, children:[...] } }
   ou { nodes:[{id,text,parent}] }
══════════════════════════════════════════ */
function renderMindmap(panel, data) {
  var root = null;

  if (data && data.root) {
    root = data.root;
  } else if (data && data.nodes) {
    // Reconstruire l'arbre depuis liste plate
    var nodeMap = {};
    data.nodes.forEach(function(n){ nodeMap[n.id] = { text: n.text || n.label || n.id, children: [] }; });
    data.nodes.forEach(function(n){
      if (n.parent && nodeMap[n.parent]) nodeMap[n.parent].children.push(nodeMap[n.id]);
    });
    var roots = data.nodes.filter(function(n){ return !n.parent; });
    root = roots.length ? nodeMap[roots[0].id] : null;
  }

  if (!root) { renderFallback(panel, data); return; }

  // Rendu SVG simplifié
  var SVG_W = 700;
  var nodes = [];
  var edges = [];
  var yPos  = [20];

  function layout(node, depth, parentIdx) {
    var idx = nodes.length;
    var x   = depth * 150 + 20;
    var y   = yPos[0];
    yPos[0] += 36;
    nodes.push({ text: node.text || '', x: x, y: y, depth: depth });
    if (parentIdx >= 0) {
      edges.push({ from: parentIdx, to: idx });
    }
    (node.children || []).forEach(function(child) {
      layout(child, depth + 1, idx);
    });
    return idx;
  }

  layout(root, 0, -1);

  var svgH = Math.max(300, yPos[0] + 20);
  var colors = ['#1e40af','#4f7ef8','#7c9ef9','#a5b8fb','#c7d2fc'];

  var svgParts = ['<svg xmlns="http://www.w3.org/2000/svg" width="' + SVG_W + '" height="' + svgH + '" style="font-family:Arial,sans-serif;">'];
  svgParts.push('<rect width="' + SVG_W + '" height="' + svgH + '" fill="#f8fafc"/>');

  // Arêtes
  edges.forEach(function(e) {
    var f = nodes[e.from], t = nodes[e.to];
    var fx = f.x + 100, fy = f.y + 13;
    var tx = t.x,       ty = t.y + 13;
    svgParts.push('<path d="M' + fx + ',' + fy + ' C' + ((fx+tx)/2) + ',' + fy + ' ' + ((fx+tx)/2) + ',' + ty + ' ' + tx + ',' + ty + '" fill="none" stroke="#cbd5e1" stroke-width="1.5"/>');
  });

  // Noeuds
  nodes.forEach(function(n) {
    var col   = colors[Math.min(n.depth, colors.length - 1)];
    var label = n.text.length > 22 ? n.text.slice(0, 20) + '…' : n.text;
    var rectW = Math.max(80, label.length * 7 + 16);
    var rectH = 26;
    svgParts.push('<rect x="' + n.x + '" y="' + (n.y) + '" width="' + rectW + '" height="' + rectH + '" rx="5" fill="' + col + '" opacity="0.9"/>');
    svgParts.push('<text x="' + (n.x + rectW/2) + '" y="' + (n.y + 17) + '" text-anchor="middle" fill="#fff" font-size="12" font-weight="' + (n.depth===0?'700':'400') + '">' + escSvg(label) + '</text>');
  });

  svgParts.push('</svg>');

  var wrap = document.createElement('div');
  wrap.className = 'review-mindmap-wrap';
  wrap.innerHTML = svgParts.join('');
  panel.innerHTML = '';
  panel.appendChild(wrap);
}

/* ══════════════════════════════════════════
   DIAGRAM
   Format : { nodes:[{id,label,x,y,w,h,type}], edges:[{from,to,label}] }
   ou SVG raw string
══════════════════════════════════════════ */
function renderDiagram(panel, data) {
  // Si c'est du SVG brut
  if (typeof data === 'string' && data.trim().startsWith('<svg')) {
    var wrap = document.createElement('div');
    wrap.className = 'review-diagram-wrap';
    wrap.innerHTML = data;
    panel.innerHTML = '';
    panel.appendChild(wrap);
    return;
  }

  var nodes = (data && data.nodes) ? data.nodes : [];
  var edges = (data && data.edges) ? data.edges : [];

  if (!nodes.length) { renderFallback(panel, data); return; }

  // Calcul bounding box
  var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  nodes.forEach(function(n) {
    minX = Math.min(minX, n.x || 0);
    minY = Math.min(minY, n.y || 0);
    maxX = Math.max(maxX, (n.x || 0) + (n.w || 120));
    maxY = Math.max(maxY, (n.y || 0) + (n.h || 50));
  });
  var pad  = 20;
  var SVG_W = maxX - minX + pad * 2;
  var SVG_H = maxY - minY + pad * 2;

  var svgParts = ['<svg xmlns="http://www.w3.org/2000/svg" width="' + SVG_W + '" height="' + SVG_H + '" style="font-family:Arial,sans-serif;">'];
  svgParts.push('<rect width="' + SVG_W + '" height="' + SVG_H + '" fill="#f8fafc"/>');

  // Edges
  var nodeMap2 = {};
  nodes.forEach(function(n){ nodeMap2[n.id] = n; });

  edges.forEach(function(e) {
    var fn = nodeMap2[e.from], tn = nodeMap2[e.to];
    if (!fn || !tn) return;
    var fx = (fn.x||0) - minX + pad + (fn.w||120)/2;
    var fy = (fn.y||0) - minY + pad + (fn.h||50)/2;
    var tx2 = (tn.x||0) - minX + pad + (tn.w||120)/2;
    var ty2 = (tn.y||0) - minY + pad + (tn.h||50)/2;
    svgParts.push('<line x1="' + fx + '" y1="' + fy + '" x2="' + tx2 + '" y2="' + ty2 + '" stroke="#94a3b8" stroke-width="1.5" marker-end="url(#arr)"/>');
    if (e.label) {
      svgParts.push('<text x="' + ((fx+tx2)/2) + '" y="' + ((fy+ty2)/2 - 4) + '" text-anchor="middle" fill="#64748b" font-size="10">' + escSvg(e.label) + '</text>');
    }
  });

  // Arrow marker
  svgParts.unshift('<defs><marker id="arr" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#94a3b8"/></marker></defs>');

  // Nodes
  nodes.forEach(function(n) {
    var nx = (n.x||0) - minX + pad;
    var ny = (n.y||0) - minY + pad;
    var nw = n.w || 120;
    var nh = n.h || 50;
    var fill   = n.color  || '#e0e7ff';
    var stroke = n.border || '#818cf8';
    var type   = n.type   || 'rect';

    if (type === 'diamond') {
      var cx = nx + nw/2, cy = ny + nh/2;
      svgParts.push('<polygon points="' + cx + ',' + ny + ' ' + (nx+nw) + ',' + cy + ' ' + cx + ',' + (ny+nh) + ' ' + nx + ',' + cy + '" fill="' + fill + '" stroke="' + stroke + '" stroke-width="1.5"/>');
    } else if (type === 'circle' || type === 'ellipse') {
      svgParts.push('<ellipse cx="' + (nx+nw/2) + '" cy="' + (ny+nh/2) + '" rx="' + nw/2 + '" ry="' + nh/2 + '" fill="' + fill + '" stroke="' + stroke + '" stroke-width="1.5"/>');
    } else {
      var rx = n.radius || 6;
      svgParts.push('<rect x="' + nx + '" y="' + ny + '" width="' + nw + '" height="' + nh + '" rx="' + rx + '" fill="' + fill + '" stroke="' + stroke + '" stroke-width="1.5"/>');
    }

    var label2 = (n.label || n.text || '');
    if (label2.length > 20) label2 = label2.slice(0, 18) + '…';
    svgParts.push('<text x="' + (nx+nw/2) + '" y="' + (ny+nh/2+5) + '" text-anchor="middle" fill="#1e293b" font-size="12">' + escSvg(label2) + '</text>');
  });

  svgParts.push('</svg>');

  var wrap2 = document.createElement('div');
  wrap2.className = 'review-diagram-wrap';
  wrap2.innerHTML = svgParts.join('');
  panel.innerHTML = '';
  panel.appendChild(wrap2);
}

/* ══════════════════════════════════════════
   PIXELART
   Format : { width, height, pixels:[[r,g,b,a],...] }
   ou { width, height, data:"base64png" }
   ou { width, height, grid:[[colorHex,...]] }
══════════════════════════════════════════ */
function renderPixelart(panel, data) {
  if (!data) { renderFallback(panel, data); return; }

  var wrap = document.createElement('div');
  wrap.className = 'review-pixelart-wrap';
  panel.innerHTML = '';
  panel.appendChild(wrap);

  // Si on a déjà une image base64
  if (data.data && typeof data.data === 'string') {
    var img = document.createElement('img');
    img.src = data.data.startsWith('data:') ? data.data : 'data:image/png;base64,' + data.data;
    img.style.cssText = 'max-width:90%;max-height:90%;image-rendering:pixelated;box-shadow:0 2px 12px rgba(0,0,0,.15);';
    wrap.appendChild(img);
    return;
  }

  var pw = data.width  || data.w || 32;
  var ph = data.height || data.h || 32;
  var CELL = Math.min(Math.floor(460 / pw), Math.floor(500 / ph), 16);
  CELL = Math.max(CELL, 1);

  var canvas = document.createElement('canvas');
  canvas.width  = pw * CELL;
  canvas.height = ph * CELL;
  canvas.style.cssText = 'image-rendering:pixelated;box-shadow:0 2px 12px rgba(0,0,0,.15);';
  var ctx = canvas.getContext('2d');

  // Fond damier
  for (var cy = 0; cy < ph; cy++) {
    for (var cx = 0; cx < pw; cx++) {
      ctx.fillStyle = (cx + cy) % 2 === 0 ? '#ffffff' : '#e5e7eb';
      ctx.fillRect(cx*CELL, cy*CELL, CELL, CELL);
    }
  }

  // Format 1 : pixels = tableau 2D d'indices de palette (format editor-pixelart.js)
  // Format 2 : pixels = tableau plat de [r,g,b,a]
  if (data.pixels && Array.isArray(data.pixels)) {
    var palette = data.palette || ['#ffffff','#000000'];
    data.pixels.forEach(function(row, ry) {
      if (Array.isArray(row)) {
        // Tableau 2D : row est un tableau d'indices
        row.forEach(function(colorIdx, rx) {
          var color = palette[colorIdx] || '#ffffff';
          ctx.fillStyle = color;
          ctx.fillRect(rx*CELL, ry*CELL, CELL, CELL);
        });
      } else if (typeof row === 'number') {
        // Tableau plat d'indices
        var x = ry % pw, y2 = Math.floor(ry / pw);
        ctx.fillStyle = palette[row] || '#ffffff';
        ctx.fillRect(x*CELL, y2*CELL, CELL, CELL);
      } else if (Array.isArray(row) === false && typeof row === 'object' && row !== null) {
        // [r,g,b,a]
        var x2 = ry % pw, y3 = Math.floor(ry / pw);
        ctx.fillStyle = 'rgba('+row[0]+','+row[1]+','+row[2]+','+(row[3]!==undefined?row[3]/255:1)+')';
        ctx.fillRect(x2*CELL, y3*CELL, CELL, CELL);
      }
    });
  }

  // Grid : tableau 2D de couleurs hex
  if (data.grid && Array.isArray(data.grid)) {
    data.grid.forEach(function(row, ry) {
      (row || []).forEach(function(color, rx) {
        if (!color || color === 'transparent') return;
        ctx.fillStyle = color;
        ctx.fillRect(rx*CELL, ry*CELL, CELL, CELL);
      });
    });
  }

  // Cells : { "x,y": "#color" }
  if (data.cells && typeof data.cells === 'object') {
    Object.keys(data.cells).forEach(function(key) {
      var parts = key.split(',');
      var cx2 = parseInt(parts[0]), cy2 = parseInt(parts[1]);
      if (isNaN(cx2) || isNaN(cy2)) return;
      ctx.fillStyle = data.cells[key];
      ctx.fillRect(cx2*CELL, cy2*CELL, CELL, CELL);
    });
  }

  wrap.appendChild(canvas);
}

/* ══════════════════════════════════════════
   FALLBACK (JSON brut formaté)
══════════════════════════════════════════ */
function renderFallback(panel, data) {
  var text = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
  var pre = document.createElement('pre');
  pre.className = 'review-json-raw';
  pre.textContent = text;
  panel.innerHTML = '';
  panel.appendChild(pre);
}

/* ── Helpers XSS ── */
function escHtml(s) {
  return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function escAttr(s) { return escHtml(s); }
function escSvg(s)  { return escHtml(s); }
</script>

<%@ include file="layout/footer.jsp" %>
