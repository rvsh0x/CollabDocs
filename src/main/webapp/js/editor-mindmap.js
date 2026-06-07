/**
 * editor-mindmap.js — Editeur MINDMAP SVG interactif
 *
 * Fonctionnalites :
 *   - Ajout de noeuds (racine + enfants)
 *   - Drag & drop des noeuds
 *   - Pan et zoom (molette + boutons)
 *   - Renommage rapide (double-clic) ou via panneau
 *   - Panneau proprietes : taille, couleur de fond, couleur texte, couleur bordure
 *   - Suppression avec cascade sur descendants
 *   - Sauvegarde / restauration via EDITOR_getContent / EDITOR_setContent
 */

(function () {
    'use strict';
    
    /* ══════════════════════════════════════════════════════
       GUARD
    ══════════════════════════════════════════════════════ */
    var READONLY = (typeof MINDMAP_READONLY !== 'undefined') ? MINDMAP_READONLY : true;
    
    /* ══════════════════════════════════════════════════════
       DOM
    ══════════════════════════════════════════════════════ */
    var svg          = document.getElementById('mindmapSvg');
    var group        = document.getElementById('mindmapGroup');
    var nodeInput    = document.getElementById('mmNodeInput');
    var addRootBtn   = document.getElementById('mmAddRootBtn');
    var addChildBtn  = document.getElementById('mmAddChildBtn');
    var deleteBtn    = document.getElementById('mmDeleteBtn');
    var zoomFitBtn   = document.getElementById('mmZoomFit');
    var zoomInBtn    = document.getElementById('mmZoomIn');
    var zoomOutBtn   = document.getElementById('mmZoomOut');
    var exportSvgBtn = document.getElementById('mmExportSvgBtn');
    
    /* Panneau proprietes */
    var propsPanel   = document.getElementById('mmPropsPanel');
    var propLabel    = document.getElementById('mmPropLabel');
    var propSize     = document.getElementById('mmPropSize');
    var propSizeVal  = document.getElementById('mmPropSizeVal');
    var propFill     = document.getElementById('mmPropFill');
    var propFillLbl  = document.getElementById('mmPropFillLbl');
    var propText     = document.getElementById('mmPropText');
    var propTextLbl  = document.getElementById('mmPropTextLbl');
    var propStroke   = document.getElementById('mmPropStroke');
    var propStrokeLbl= document.getElementById('mmPropStrokeLbl');
    
    if (!svg || !group) return;
    
    /* ══════════════════════════════════════════════════════
       ETAT
    ══════════════════════════════════════════════════════ */
    var state = { nodes: [], edges: [] };
    var selectedId   = null;
    var dragging     = null;   /* { id, startX, startY, origX, origY } */
    var pan          = { x: 0, y: 0, active: false, startX: 0, startY: 0 };
    var scale        = 1;
    var idSeq        = 0;
    var debounceTimer= null;
    
    /* Defaults visuels */
    var DEFAULTS = {
        rootFill:   '#89b4fa',
        rootText:   '#1e1e2e',
        rootStroke: '#74c7ec',
        rootSize:   44,
        nodeFill:   '#313244',
        nodeText:   '#cdd6f4',
        nodeStroke: '#45475a',
        nodeSize:   34,
    };
    
    function genId() { return 'n' + (++idSeq) + '_' + Date.now(); }
    
    /* ══════════════════════════════════════════════════════
       RENDU
    ══════════════════════════════════════════════════════ */
    function applyTransform() {
        group.setAttribute('transform',
            'translate(' + pan.x + ',' + pan.y + ') scale(' + scale + ')');
    }
    
    function render() {
        group.innerHTML = '';
        applyTransform();
    
        /* Aretes (dessous) */
        state.edges.forEach(function (edge) {
            var from = nodeById(edge.from);
            var to   = nodeById(edge.to);
            if (!from || !to) return;
    
            /* Courbe de bezier entre les deux noeuds */
            var fx = from.x, fy = from.y;
            var tx = to.x,   ty = to.y;
            var cx = (fx + tx) / 2;
    
            var path = mkSvg('path', {
                d: 'M ' + fx + ' ' + fy + ' C ' + cx + ' ' + fy + ', ' + cx + ' ' + ty + ', ' + tx + ' ' + ty,
                stroke: '#89b4fa',
                'stroke-width': '1.5',
                'stroke-opacity': '0.6',
                fill: 'none',
            });
            group.appendChild(path);
        });
    
        /* Noeuds (dessus) */
        state.nodes.forEach(renderNode);
    }
    
    function renderNode(node) {
        var isRoot  = !node.parent;
        var size    = node.size   || (isRoot ? DEFAULTS.rootSize  : DEFAULTS.nodeSize);
        var fill    = node.fill   || (isRoot ? DEFAULTS.rootFill  : DEFAULTS.nodeFill);
        var textCol = node.textColor || (isRoot ? DEFAULTS.rootText  : DEFAULTS.nodeText);
        var stroke  = node.stroke || (isRoot ? DEFAULTS.rootStroke : DEFAULTS.nodeStroke);
        var selected= (node.id === selectedId);
    
        var g = mkSvg('g', {
            transform: 'translate(' + node.x + ',' + node.y + ')',
            'data-id': node.id,
            'class': 'mm-node',
        });
    
        /* Ellipse (rx = size, ry = size * 0.6) */
        var rx = size;
        var ry = Math.round(size * 0.6);
        var ellipse = mkSvg('ellipse', {
            cx: 0, cy: 0,
            rx: rx, ry: ry,
            fill: fill,
            stroke: selected ? '#f38ba8' : stroke,
            'stroke-width': selected ? '2.5' : '1.5',
        });
    
        /* Texte */
        var fontSize = Math.max(9, Math.min(15, Math.round(size * 0.32)));
        var text = mkSvg('text', {
            'text-anchor': 'middle',
            'dominant-baseline': 'middle',
            'font-size': fontSize,
            'font-family': "'Segoe UI', system-ui, sans-serif",
            fill: textCol,
            style: 'user-select:none; pointer-events:none;',
        });
    
        /* Truncate le label si trop long */
        var label = node.label || '';
        var maxChars = Math.floor(rx * 1.6 / (fontSize * 0.6));
        text.textContent = label.length > maxChars ? label.slice(0, maxChars - 1) + '…' : label;
    
        g.appendChild(ellipse);
        g.appendChild(text);
    
        /* Interaction */
        if (!READONLY) {
            g.addEventListener('mousedown', function (e) {
                e.stopPropagation();
                selectNode(node.id);
                dragging = {
                    id: node.id,
                    startX: e.clientX, startY: e.clientY,
                    origX: node.x,     origY: node.y,
                };
            });
            g.addEventListener('dblclick', function (e) {
                e.stopPropagation();
                openInlineEdit(node);
            });
        } else {
            g.addEventListener('mousedown', function (e) {
                e.stopPropagation();
                selectNode(node.id);
            });
        }
    
        group.appendChild(g);
    }
    
    /* ══════════════════════════════════════════════════════
       SELECTION + PANNEAU PROPRIETES
    ══════════════════════════════════════════════════════ */
    function selectNode(id) {
        selectedId = id;
        render();
        if (!READONLY) updatePropsPanel();
    }
    
    function deselectAll() {
        selectedId = null;
        render();
        if (propsPanel) propsPanel.classList.remove('visible');
    }
    
    function updatePropsPanel() {
        if (!propsPanel) return;
        var node = nodeById(selectedId);
        if (!node) {
            propsPanel.classList.remove('visible');
            return;
        }
        propsPanel.classList.add('visible');
    
        var isRoot = !node.parent;
        var defFill   = isRoot ? DEFAULTS.rootFill   : DEFAULTS.nodeFill;
        var defText   = isRoot ? DEFAULTS.rootText   : DEFAULTS.nodeText;
        var defStroke = isRoot ? DEFAULTS.rootStroke : DEFAULTS.nodeStroke;
        var defSize   = isRoot ? DEFAULTS.rootSize   : DEFAULTS.nodeSize;
    
        if (propLabel)  propLabel.value = node.label || '';
        if (propSize) {
            var sz = node.size || defSize;
            propSize.value = sz;
            if (propSizeVal) propSizeVal.textContent = sz;
        }
        if (propFill) {
            var f = node.fill || defFill;
            propFill.value = f;
            if (propFillLbl) propFillLbl.textContent = f;
        }
        if (propText) {
            var t = node.textColor || defText;
            propText.value = t;
            if (propTextLbl) propTextLbl.textContent = t;
        }
        if (propStroke) {
            var s = node.stroke || defStroke;
            propStroke.value = s;
            if (propStrokeLbl) propStrokeLbl.textContent = s;
        }
    }
    
    /* ── Bindings panneau proprietes ── */
    function bindProps() {
        if (!propsPanel) return;
    
        /* Nom : mise a jour live */
        if (propLabel) {
            propLabel.addEventListener('input', function () {
                var node = nodeById(selectedId);
                if (!node) return;
                node.label = propLabel.value;
                render();
                sendUpdate();
            });
            propLabel.addEventListener('keydown', function (e) {
                if (e.key === 'Enter') propLabel.blur();
                e.stopPropagation();
            });
        }
    
        /* Taille */
        if (propSize) {
            propSize.addEventListener('input', function () {
                var node = nodeById(selectedId);
                if (!node) return;
                node.size = parseInt(propSize.value);
                if (propSizeVal) propSizeVal.textContent = propSize.value;
                render();
                sendUpdate();
            });
        }
    
        /* Couleur fond */
        if (propFill) {
            propFill.addEventListener('input', function () {
                var node = nodeById(selectedId);
                if (!node) return;
                node.fill = propFill.value;
                if (propFillLbl) propFillLbl.textContent = propFill.value;
                render();
                sendUpdate();
            });
        }
    
        /* Couleur texte */
        if (propText) {
            propText.addEventListener('input', function () {
                var node = nodeById(selectedId);
                if (!node) return;
                node.textColor = propText.value;
                if (propTextLbl) propTextLbl.textContent = propText.value;
                render();
                sendUpdate();
            });
        }
    
        /* Couleur bordure */
        if (propStroke) {
            propStroke.addEventListener('input', function () {
                var node = nodeById(selectedId);
                if (!node) return;
                node.stroke = propStroke.value;
                if (propStrokeLbl) propStrokeLbl.textContent = propStroke.value;
                render();
                sendUpdate();
            });
        }
    }
    
    /* ══════════════════════════════════════════════════════
       EDITION INLINE (double-clic)
    ══════════════════════════════════════════════════════ */
    function openInlineEdit(node) {
        if (!nodeInput) return;
        var rect  = svg.getBoundingClientRect();
        var nx    = node.x * scale + pan.x + rect.left;
        var ny    = node.y * scale + pan.y + rect.top;
        var sz    = node.size || DEFAULTS.nodeSize;
        var w     = Math.max(100, sz * scale * 2);
    
        nodeInput.style.left    = (nx - w / 2) + 'px';
        nodeInput.style.top     = (ny - 14) + 'px';
        nodeInput.style.width   = w + 'px';
        nodeInput.style.display = 'block';
        nodeInput.value         = node.label || '';
        nodeInput.focus();
        nodeInput.select();
    
        var commit = function () {
            var val = nodeInput.value.trim();
            if (val) node.label = val;
            nodeInput.style.display = 'none';
            nodeInput.onkeydown = null;
            nodeInput.onblur    = null;
            /* Synchroniser panneau */
            if (propLabel && selectedId === node.id) propLabel.value = node.label;
            render();
            sendUpdate();
        };
    
        nodeInput.onkeydown = function (ev) {
            if (ev.key === 'Enter' || ev.key === 'Escape') commit();
            ev.stopPropagation();
        };
        nodeInput.onblur = commit;
    }
    
    /* ══════════════════════════════════════════════════════
       INTERACTIONS SVG
    ══════════════════════════════════════════════════════ */
    
    /* Drag */
    svg.addEventListener('mousemove', function (e) {
        if (dragging && !READONLY) {
            var node = nodeById(dragging.id);
            if (!node) return;
            node.x = dragging.origX + (e.clientX - dragging.startX) / scale;
            node.y = dragging.origY + (e.clientY - dragging.startY) / scale;
            render();
        } else if (pan.active) {
            pan.x += e.clientX - pan.startX;
            pan.y += e.clientY - pan.startY;
            pan.startX = e.clientX;
            pan.startY = e.clientY;
            applyTransform();
        }
    });
    
    svg.addEventListener('mouseup', function () {
        if (dragging) { dragging = null; sendUpdate(); }
        pan.active = false;
    });
    
    svg.addEventListener('mouseleave', function () {
        if (dragging) { dragging = null; sendUpdate(); }
        pan.active = false;
    });
    
    /* Pan (clic sur fond) */
    svg.addEventListener('mousedown', function (e) {
        if (e.target === svg || e.target === group) {
            pan.active  = true;
            pan.startX  = e.clientX;
            pan.startY  = e.clientY;
            deselectAll();
        }
    });
    
    /* Double-clic sur fond = nouveau noeud racine */
    if (!READONLY) {
        svg.addEventListener('dblclick', function (e) {
            if (e.target !== svg && e.target !== group) return;
            var rect = svg.getBoundingClientRect();
            var x    = (e.clientX - rect.left - pan.x) / scale;
            var y    = (e.clientY - rect.top  - pan.y) / scale;
            var node = makeNode({ x: x, y: y, parent: null });
            state.nodes.push(node);
            selectNode(node.id);
            render();
            openInlineEdit(node);
            sendUpdate();
        });
    
        /* Zoom molette */
        svg.addEventListener('wheel', function (e) {
            e.preventDefault();
            var factor = e.deltaY < 0 ? 1.12 : 0.9;
            scale = Math.min(4, Math.max(0.15, scale * factor));
            applyTransform();
        }, { passive: false });
    }
    
    /* ══════════════════════════════════════════════════════
       BOUTONS TOOLBAR
    ══════════════════════════════════════════════════════ */
    if (addRootBtn) {
        addRootBtn.addEventListener('click', function () {
            /* Placer le nouveau noeud au centre du SVG visible */
            var cx = (svg.clientWidth  / 2 - pan.x) / scale;
            var cy = (svg.clientHeight / 2 - pan.y) / scale;
            var node = makeNode({ x: cx, y: cy, parent: null });
            state.nodes.push(node);
            selectNode(node.id);
            render();
            openInlineEdit(node);
            sendUpdate();
        });
    }
    
    if (addChildBtn) {
        addChildBtn.addEventListener('click', function () {
            if (!selectedId) return;
            var parent = nodeById(selectedId);
            if (!parent) return;
    
            /* Calculer la position : a droite du parent, decale selon nb d'enfants */
            var childCount = state.edges.filter(function (e) { return e.from === selectedId; }).length;
            var node = makeNode({
                x: parent.x + (parent.size || DEFAULTS.nodeSize) * 4,
                y: parent.y + childCount * ((parent.size || DEFAULTS.nodeSize) * 1.5),
                parent: selectedId,
            });
            state.nodes.push(node);
            state.edges.push({ from: selectedId, to: node.id });
            selectNode(node.id);
            render();
            openInlineEdit(node);
            sendUpdate();
        });
    }
    
    if (deleteBtn) {
        deleteBtn.addEventListener('click', deleteSelected);
    }
    
    function deleteSelected() {
        if (!selectedId) return;
        /* Collecter le noeud et tous ses descendants */
        var toDelete = [];
        (function collect(id) {
            toDelete.push(id);
            state.edges.forEach(function (e) { if (e.from === id) collect(e.to); });
        }(selectedId));
    
        state.nodes = state.nodes.filter(function (n) { return toDelete.indexOf(n.id) < 0; });
        state.edges = state.edges.filter(function (e) {
            return toDelete.indexOf(e.from) < 0 && toDelete.indexOf(e.to) < 0;
        });
        selectedId = null;
        if (propsPanel) propsPanel.classList.remove('visible');
        render();
        sendUpdate();
    }
    
    /* Zoom boutons */
    if (zoomInBtn)  zoomInBtn.addEventListener('click',  function () { scale = Math.min(4, scale * 1.2); applyTransform(); });
    if (zoomOutBtn) zoomOutBtn.addEventListener('click', function () { scale = Math.max(0.15, scale * 0.8); applyTransform(); });
    
    if (exportSvgBtn) {
        exportSvgBtn.addEventListener('click', function () {
            exportAsSVG();
            exportSvgBtn.textContent = 'Téléchargé !';
            setTimeout(function () { exportSvgBtn.textContent = '↓ SVG'; }, 1800);
        });
    }
    
    /* ══════════════════════════════════════════════════════
       EXPORT SVG
       Genere un SVG autonome (standalone) avec tous les styles
       embarques, independant du DOM de la page.
    ══════════════════════════════════════════════════════ */
    function exportAsSVG() {
        if (state.nodes.length === 0) {
            alert('La carte est vide, rien à exporter.');
            return;
        }
    
        /* Calculer la bounding box de tous les noeuds */
        var pad = 60;
        var sizes = state.nodes.map(function (n) { return n.size || 40; });
        var xs = state.nodes.map(function (n, i) { return n.x; });
        var ys = state.nodes.map(function (n, i) { return n.y; });
        var minX = Math.min.apply(null, xs) - Math.max.apply(null, sizes) - pad;
        var minY = Math.min.apply(null, ys) - Math.max.apply(null, sizes) - pad;
        var maxX = Math.max.apply(null, xs) + Math.max.apply(null, sizes) + pad;
        var maxY = Math.max.apply(null, ys) + Math.max.apply(null, sizes) + pad;
        var W = maxX - minX;
        var H = maxY - minY;
    
        /* Construire le SVG standalone */
        var lines = [];
        lines.push('<?xml version="1.0" encoding="UTF-8"?>');
        lines.push('<svg xmlns="http://www.w3.org/2000/svg"');
        lines.push('     width="' + Math.round(W) + '" height="' + Math.round(H) + '"');
        lines.push('     viewBox="' + minX + ' ' + minY + ' ' + W + ' ' + H + '"');
        lines.push('     style="background:#1e1e2e;">');
    
        /* Style embarque */
        lines.push('<style>');
        lines.push("text { font-family: 'Segoe UI', system-ui, sans-serif; }");
        lines.push('</style>');
    
        /* Aretes (courbes de Bezier) */
        state.edges.forEach(function (edge) {
            var from = nodeById(edge.from);
            var to   = nodeById(edge.to);
            if (!from || !to) return;
            var cx = (from.x + to.x) / 2;
            lines.push('<path d="M ' + from.x + ' ' + from.y +
                       ' C ' + cx + ' ' + from.y + ', ' + cx + ' ' + to.y +
                       ', ' + to.x + ' ' + to.y + '"' +
                       ' stroke="#89b4fa" stroke-width="1.5" stroke-opacity="0.6" fill="none"/>');
        });
    
        /* Noeuds */
        state.nodes.forEach(function (node) {
            var isRoot  = !node.parent;
            var size    = node.size      || (isRoot ? DEFAULTS.rootSize   : DEFAULTS.nodeSize);
            var fill    = node.fill      || (isRoot ? DEFAULTS.rootFill   : DEFAULTS.nodeFill);
            var textCol = node.textColor || (isRoot ? DEFAULTS.rootText   : DEFAULTS.nodeText);
            var stroke  = node.stroke    || (isRoot ? DEFAULTS.rootStroke : DEFAULTS.nodeStroke);
            var rx      = size;
            var ry      = Math.round(size * 0.6);
            var fs      = Math.max(9, Math.min(15, Math.round(size * 0.32)));
            var label   = xmlEsc(node.label || '');
            var maxChars= Math.floor(rx * 1.6 / (fs * 0.6));
            if (label.length > maxChars) label = label.slice(0, maxChars - 1) + '...';
    
            lines.push('<g transform="translate(' + node.x + ',' + node.y + ')">');
            lines.push('  <ellipse cx="0" cy="0" rx="' + rx + '" ry="' + ry + '"' +
                       ' fill="' + xmlEsc(fill) + '"' +
                       ' stroke="' + xmlEsc(stroke) + '" stroke-width="1.5"/>');
            lines.push('  <text text-anchor="middle" dominant-baseline="middle"' +
                       ' font-size="' + fs + '" fill="' + xmlEsc(textCol) + '">' +
                       label + '</text>');
            lines.push('</g>');
        });
    
        lines.push('</svg>');
        var svgStr = lines.join('\n');
    
        /* Telecharger */
        var blob = new Blob([svgStr], { type: 'image/svg+xml;charset=utf-8' });
        var url  = URL.createObjectURL(blob);
        var a    = document.createElement('a');
        a.href     = url;
        a.download = 'mindmap.svg';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(function () { URL.revokeObjectURL(url); }, 8000);
    }
    
    function xmlEsc(s) {
        return String(s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }
    
    if (zoomFitBtn) {
        zoomFitBtn.addEventListener('click', function () {
            if (state.nodes.length === 0) { pan.x = 0; pan.y = 0; scale = 1; applyTransform(); return; }
            /* Calculer la bounding box de tous les noeuds */
            var xs = state.nodes.map(function (n) { return n.x; });
            var ys = state.nodes.map(function (n) { return n.y; });
            var minX = Math.min.apply(null, xs), maxX = Math.max.apply(null, xs);
            var minY = Math.min.apply(null, ys), maxY = Math.max.apply(null, ys);
            var W = svg.clientWidth  || 800;
            var H = svg.clientHeight || 500;
            var cw = maxX - minX || 1, ch = maxY - minY || 1;
            var pad = 80;
            scale = Math.min(4, Math.max(0.15, Math.min((W - pad * 2) / cw, (H - pad * 2) / ch)));
            pan.x = W / 2 - ((minX + maxX) / 2) * scale;
            pan.y = H / 2 - ((minY + maxY) / 2) * scale;
            applyTransform();
        });
    }
    
    /* Clavier */
    document.addEventListener('keydown', function (e) {
        if (READONLY) return;
        /* Ne pas intercepter si focus dans un input */
        var tag = document.activeElement ? document.activeElement.tagName : '';
        if (tag === 'INPUT' || tag === 'TEXTAREA') return;
    
        if ((e.key === 'Delete' || e.key === 'Backspace') && selectedId) {
            deleteSelected();
        }
        if (e.key === 'Escape') deselectAll();
    });
    
    /* ══════════════════════════════════════════════════════
       HELPERS
    ══════════════════════════════════════════════════════ */
    function makeNode(opts) {
        var isRoot = !opts.parent;
        return {
            id:        genId(),
            label:     isRoot ? 'Nœud' : 'Enfant',
            x:         opts.x || 0,
            y:         opts.y || 0,
            parent:    opts.parent || null,
            size:      isRoot ? DEFAULTS.rootSize  : DEFAULTS.nodeSize,
            fill:      isRoot ? DEFAULTS.rootFill  : DEFAULTS.nodeFill,
            textColor: isRoot ? DEFAULTS.rootText  : DEFAULTS.nodeText,
            stroke:    isRoot ? DEFAULTS.rootStroke : DEFAULTS.nodeStroke,
        };
    }
    
    function nodeById(id) {
        for (var i = 0; i < state.nodes.length; i++) {
            if (state.nodes[i].id === id) return state.nodes[i];
        }
        return null;
    }
    
    function mkSvg(tag, attrs) {
        var el = document.createElementNS('http://www.w3.org/2000/svg', tag);
        if (attrs) Object.keys(attrs).forEach(function (k) { el.setAttribute(k, attrs[k]); });
        return el;
    }
    
    function fitSvg() {
        var pane = document.getElementById('editorPane');
        if (svg) {
            var w = (pane && pane.clientWidth  > 0) ? pane.clientWidth  : (svg.parentElement ? svg.parentElement.clientWidth  : 800);
            var h = (pane && pane.clientHeight > 0) ? pane.clientHeight : (svg.parentElement ? svg.parentElement.clientHeight : 500);
            /* Fallback absolu si tout est a 0 (ex: premier rendu avant layout) */
            if (w < 10) w = 800;
            if (h < 10) h = 500;
            svg.setAttribute('width',  w);
            svg.setAttribute('height', Math.max(300, h - 50));
        }
    }
    
    /* ══════════════════════════════════════════════════════
       SAVE / LOAD
    ══════════════════════════════════════════════════════ */
    function sendUpdate() {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(function () {
            window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
        }, 300);
    }
    
    window.EDITOR_getContent = function () {
        return JSON.stringify({ nodes: state.nodes, edges: state.edges });
    };
    
    window.EDITOR_setContent = function (jsonStr) {
        if (!jsonStr) return;
        try {
            var obj = JSON.parse(jsonStr);
            if (obj && Array.isArray(obj.nodes)) {
                state.nodes = obj.nodes;
                state.edges = obj.edges || [];
                /* Recalculer idSeq pour eviter les collisions */
                state.nodes.forEach(function (n) {
                    var num = parseInt(String(n.id).replace(/\D/g, ''), 10);
                    if (!isNaN(num) && num > idSeq) idSeq = num;
                });
                selectedId = null;
                if (propsPanel) propsPanel.classList.remove('visible');
                render();
            }
        } catch (e) { /* ignore */ }
    };
    
    /* ══════════════════════════════════════════════════════
       INIT
    ══════════════════════════════════════════════════════ */
    /* Lancer fitSvg apres le layout initial du navigateur */
    if (typeof requestAnimationFrame !== 'undefined') {
        requestAnimationFrame(function () {
            fitSvg();
            render();
        });
    } else {
        fitSvg();
        render();
    }
    bindProps();
    window.addEventListener('resize', fitSvg);
    
    }());