<%-- Fragment éditeur DIAGRAM — inclus par editor.jsp --%>
<%-- JS : inline (aucune dépendance externe) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<%-- ═══════════════════════════════════════════════════════════
     STYLES
     ═══════════════════════════════════════════════════════════ --%>
<style>
/* ── Conteneur principal ── */
.diagram-editor {
    position: relative;
    display: flex;
    flex-direction: column;
    width: 100%;
    height: 100%;
    min-height: 520px;
    background: #f8f8f6;
    border: 1px solid #ddd;
    border-radius: 6px;
    overflow: hidden;
    font-family: 'Segoe UI', system-ui, sans-serif;
    user-select: none;
}

/* ── Toolbar principale ── */
.diagram-toolbar {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 2px;
    padding: 6px 10px;
    background: #fff;
    border-bottom: 1px solid #e0e0e0;
    z-index: 20;
    min-height: 40px;
}

.diagram-toolbar .sep {
    width: 1px;
    height: 20px;
    background: #ddd;
    margin: 0 4px;
}

.diagram-toolbar .spacer { flex: 1; }

/* ── Boutons toolbar ── */
.diag-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 4px 8px;
    height: 28px;
    font-size: 12px;
    font-family: inherit;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: #fff;
    color: #333;
    cursor: pointer;
    white-space: nowrap;
    transition: background .12s, border-color .12s, color .12s;
}
.diag-btn:hover  { background: #f0f0f0; border-color: #aaa; }
.diag-btn:active { background: #e4e4e4; }
.diag-btn.active { background: #1a73e8; border-color: #1a73e8; color: #fff; }
.diag-btn.danger { border-color: #d93025; color: #d93025; }
.diag-btn.danger:hover { background: #fce8e6; }
.diag-btn svg { pointer-events: none; }

/* ── Section outils nœuds ── */
.diag-shape-btn {
    width: 32px;
    height: 28px;
    padding: 0;
}

/* ── Barre secondaire (propriétés) ── */
.diagram-props-bar {
    display: none;
    align-items: center;
    flex-wrap: wrap;
    gap: 6px;
    padding: 4px 10px;
    background: #f5f5f5;
    border-bottom: 1px solid #e8e8e8;
    font-size: 12px;
    color: #555;
    z-index: 19;
}
.diagram-props-bar.visible { display: flex; }
.diagram-props-bar label { display: flex; align-items: center; gap: 4px; }
.diagram-props-bar input[type=text],
.diagram-props-bar input[type=number] {
    height: 22px;
    padding: 0 5px;
    font-size: 12px;
    border: 1px solid #ccc;
    border-radius: 3px;
    background: #fff;
    width: 80px;
}
.diagram-props-bar input[type=color] {
    width: 28px;
    height: 22px;
    padding: 1px;
    border: 1px solid #ccc;
    border-radius: 3px;
    cursor: pointer;
}
.diagram-props-bar select {
    height: 22px;
    padding: 0 4px;
    font-size: 12px;
    border: 1px solid #ccc;
    border-radius: 3px;
    background: #fff;
}

/* ── Canvas SVG ── */
.diagram-canvas-wrap {
    flex: 1;
    position: relative;
    overflow: hidden;
    cursor: default;
}

.diagram-svg {
    width: 100%;
    height: 100%;
    display: block;
    touch-action: none;
}

/* ── Curseurs ── */
.diagram-svg.tool-rect,
.diagram-svg.tool-circle,
.diagram-svg.tool-diamond,
.diagram-svg.tool-text   { cursor: crosshair; }
.diagram-svg.tool-connect { cursor: cell; }
.diagram-svg.panning      { cursor: grabbing; }
.diagram-svg.tool-pan     { cursor: grab; }

/* ── Nœuds SVG ── */
.diag-node { cursor: move; }
.diag-node:hover .diag-shape { filter: brightness(.95); }
.diag-node.selected .diag-shape {
    stroke: #1a73e8 !important;
    stroke-width: 2px !important;
}

/* ── Handles de sélection ── */
.sel-handle {
    fill: #fff;
    stroke: #1a73e8;
    stroke-width: 1.5;
    cursor: se-resize;
    pointer-events: all;
}

/* ── Connecteurs ── */
.diag-edge {
    cursor: pointer;
    fill: none;
}
.diag-edge:hover path,
.diag-edge:hover line { stroke-width: 3 !important; }
.diag-edge.selected path,
.diag-edge.selected line { stroke: #1a73e8 !important; stroke-width: 2.5 !important; }
.diag-edge-label { cursor: text; pointer-events: all; }

/* ── Fantôme de connexion ── */
#diag-conn-preview {
    pointer-events: none;
    stroke: #1a73e8;
    stroke-width: 2;
    stroke-dasharray: 6 4;
    fill: none;
}

/* ── Port de connexion (hover sur nœud en mode connect) ── */
.conn-port {
    fill: #1a73e8;
    stroke: #fff;
    stroke-width: 1.5;
    r: 5;
    pointer-events: none;
    opacity: 0;
    transition: opacity .15s;
}
.diag-node.conn-hover .conn-port { opacity: 1; }

/* ── Sélection rectangle ── */
#diag-sel-rect {
    fill: rgba(26,115,232,.08);
    stroke: #1a73e8;
    stroke-width: 1;
    stroke-dasharray: 4 3;
    pointer-events: none;
}

/* ── Input label inline ── */
#diagNodeInput {
    position: absolute;
    z-index: 100;
    border: 2px solid #1a73e8;
    border-radius: 3px;
    background: rgba(255,255,255,.95);
    padding: 2px 6px;
    font-size: 13px;
    font-family: inherit;
    outline: none;
    min-width: 60px;
    max-width: 260px;
    box-shadow: 0 2px 8px rgba(0,0,0,.12);
}

/* ── Grid ── */
.diag-grid { pointer-events: none; }

/* ── Minimap ── */
#diag-minimap {
    position: absolute;
    bottom: 10px;
    right: 10px;
    width: 140px;
    height: 90px;
    background: rgba(255,255,255,.92);
    border: 1px solid #ccc;
    border-radius: 4px;
    overflow: hidden;
    box-shadow: 0 2px 6px rgba(0,0,0,.12);
    z-index: 15;
}
#diag-minimap svg { width: 100%; height: 100%; }
#diag-minimap-viewport {
    fill: rgba(26,115,232,.12);
    stroke: #1a73e8;
    stroke-width: 1;
}

/* ── Tooltip info ── */
#diag-info {
    position: absolute;
    bottom: 10px;
    left: 10px;
    font-size: 11px;
    color: #888;
    pointer-events: none;
    z-index: 15;
}

/* ── Mode lecture seule ── */
.diagram-editor.readonly .diagram-toolbar { background: #fafafa; }
.diagram-editor.readonly .diag-node { cursor: default; }

/* ── Contextmenu ── */
#diag-ctx-menu {
    position: fixed;
    z-index: 999;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 6px;
    box-shadow: 0 4px 16px rgba(0,0,0,.15);
    padding: 4px 0;
    min-width: 170px;
    font-size: 13px;
    display: none;
}
#diag-ctx-menu.open { display: block; }
.ctx-item {
    padding: 6px 16px;
    cursor: pointer;
    color: #333;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: background .1s;
}
.ctx-item:hover   { background: #f0f0f0; }
.ctx-item.danger  { color: #d93025; }
.ctx-item.sep-top { border-top: 1px solid #eee; margin-top: 3px; padding-top: 7px; }
.ctx-item svg     { flex-shrink: 0; }

/* ── Toast notifications ── */
#diag-toast {
    position: absolute;
    top: 50px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(0,0,0,.75);
    color: #fff;
    padding: 6px 14px;
    border-radius: 4px;
    font-size: 12px;
    pointer-events: none;
    z-index: 200;
    opacity: 0;
    transition: opacity .2s;
}
#diag-toast.show { opacity: 1; }

/* ── Scrollbars ── */
.diagram-canvas-wrap::-webkit-scrollbar { display: none; }
</style>

<%-- ═══════════════════════════════════════════════════════════
     HTML
     ═══════════════════════════════════════════════════════════ --%>
<div class="diagram-editor<c:if test="${!canEdit}"> readonly</c:if>" id="diagramEditor">

    <%-- ── Toolbar principale ── --%>
    <div class="diagram-toolbar" id="diagToolbar">
        <c:if test="${canEdit}">
            <%-- Outils formes --%>
            <button class="diag-btn diag-shape-btn diag-tool" data-shape="rect"    title="Rectangle (R)" id="toolRect">
                <svg width="16" height="16" viewBox="0 0 16 16"><rect x="2" y="4" width="12" height="8" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn diag-shape-btn diag-tool" data-shape="circle"  title="Ellipse (E)" id="toolCircle">
                <svg width="16" height="16" viewBox="0 0 16 16"><ellipse cx="8" cy="8" rx="6" ry="5" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn diag-shape-btn diag-tool" data-shape="diamond" title="Losange (D)" id="toolDiamond">
                <svg width="16" height="16" viewBox="0 0 16 16"><polygon points="8,2 14,8 8,14 2,8" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn diag-shape-btn diag-tool" data-shape="text"    title="Texte (T)" id="toolText">
                <svg width="16" height="16" viewBox="0 0 16 16"><text x="3" y="13" font-size="13" font-weight="700" fill="currentColor" font-family="serif">T</text></svg>
            </button>

            <div class="sep"></div>

            <%-- Connecteur --%>
            <button class="diag-btn diag-tool" data-shape="connect" title="Connecteur fléché (C)" id="toolConnect">
                <svg width="16" height="16" viewBox="0 0 16 16"><line x1="3" y1="13" x2="13" y2="3" stroke="currentColor" stroke-width="1.5"/><polyline points="7,3 13,3 13,9" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>
                Connecteur
            </button>

            <div class="sep"></div>

            <%-- Sélection / Pan --%>
            <button class="diag-btn diag-tool active" data-shape="select" title="Sélection (S)" id="toolSelect">
                <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 2 L3 13 L6.5 10 L9 14 L10.5 13 L8 9 L12 9 Z" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/></svg>
            </button>
            <button class="diag-btn diag-tool" data-shape="pan" title="Déplacer la vue (H)" id="toolPan">
                <svg width="16" height="16" viewBox="0 0 16 16"><path d="M8 2v2M8 12v2M2 8h2M12 8h2M4.93 4.93l1.41 1.41M9.66 9.66l1.41 1.41M4.93 11.07l1.41-1.41M9.66 6.34l1.41-1.41" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><circle cx="8" cy="8" r="2" fill="none" stroke="currentColor" stroke-width="1.4"/></svg>
            </button>

            <div class="sep"></div>

            <%-- Édition --%>
            <button class="diag-btn" id="diagUndoBtn" title="Annuler (Ctrl+Z)" disabled>
                <svg width="14" height="14" viewBox="0 0 16 16"><path d="M3 8a5 5 0 1 1 1.5 3.5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><polyline points="1,5 3,8 6,6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>
            </button>
            <button class="diag-btn" id="diagRedoBtn" title="Rétablir (Ctrl+Y)" disabled>
                <svg width="14" height="14" viewBox="0 0 16 16"><path d="M13 8a5 5 0 1 0-1.5 3.5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><polyline points="15,5 13,8 10,6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>
            </button>

            <div class="sep"></div>

            <%-- Alignement --%>
            <button class="diag-btn" id="diagAlignLeft"   title="Aligner à gauche">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="1" y="2" width="9" height="3" rx="1" fill="currentColor"/><rect x="1" y="6.5" width="14" height="3" rx="1" fill="currentColor"/><rect x="1" y="11" width="7" height="3" rx="1" fill="currentColor"/><line x1="0" y1="1" x2="0" y2="15" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn" id="diagAlignCenterH" title="Centrer horizontalement">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="3.5" y="2" width="9" height="3" rx="1" fill="currentColor"/><rect x="1" y="6.5" width="14" height="3" rx="1" fill="currentColor"/><rect x="4.5" y="11" width="7" height="3" rx="1" fill="currentColor"/><line x1="8" y1="1" x2="8" y2="15" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn" id="diagAlignTop"    title="Aligner en haut">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="2" y="3" width="3" height="9" rx="1" fill="currentColor"/><rect x="6.5" y="3" width="3" height="11" rx="1" fill="currentColor"/><rect x="11" y="3" width="3" height="6" rx="1" fill="currentColor"/><line x1="1" y1="2" x2="15" y2="2" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
            <button class="diag-btn" id="diagDistribH"    title="Distribuer horizontalement">
                <svg width="14" height="14" viewBox="0 0 16 16"><line x1="0" y1="8" x2="16" y2="8" stroke="currentColor" stroke-width="1.5"/><rect x="1" y="5" width="4" height="6" rx="1" fill="none" stroke="currentColor" stroke-width="1.4"/><rect x="11" y="5" width="4" height="6" rx="1" fill="none" stroke="currentColor" stroke-width="1.4"/><rect x="6" y="5" width="4" height="6" rx="1" fill="none" stroke="currentColor" stroke-width="1.4"/></svg>
            </button>

            <div class="sep"></div>

            <%-- Ordre Z --%>
            <button class="diag-btn" id="diagBringFront" title="Mettre au premier plan">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="1" y="4" width="9" height="9" rx="1" fill="none" stroke="currentColor" stroke-width="1.4" opacity=".5"/><rect x="6" y="1" width="9" height="9" rx="1" fill="#fff" stroke="currentColor" stroke-width="1.4"/></svg>
            </button>
            <button class="diag-btn" id="diagSendBack" title="Envoyer à l'arrière-plan">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="6" y="6" width="9" height="9" rx="1" fill="none" stroke="currentColor" stroke-width="1.4" opacity=".5"/><rect x="1" y="1" width="9" height="9" rx="1" fill="#fff" stroke="currentColor" stroke-width="1.4"/></svg>
            </button>

            <div class="sep"></div>

            <%-- Supprimer --%>
            <button class="diag-btn danger" id="diagDeleteBtn" title="Supprimer la sélection (Suppr)">
                <svg width="14" height="14" viewBox="0 0 16 16"><polyline points="2,4 14,4" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><path d="M5 4V2h6v2" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><path d="M3 4l1 10h8l1-10" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><line x1="6" y1="7" x2="6" y2="11" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><line x1="10" y1="7" x2="10" y2="11" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>
                Supprimer
            </button>
        </c:if>
        <c:if test="${!canEdit}">
            <span style="font-size:12px;color:#888;">Mode lecture seule</span>
        </c:if>

        <div class="spacer"></div>

        <c:if test="${canEdit}">
            <button class="diag-btn" id="diagNewBtn" title="Nouveau diagramme (vider le canvas)">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="2" y="2" width="12" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.4"/><line x1="8" y1="5" x2="8" y2="11" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><line x1="5" y1="8" x2="11" y2="8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>
                Nouveau
            </button>
            <div class="sep"></div>
        </c:if>

        <%-- Zoom / Ajuster / Export ── --%>
        <button class="diag-btn" id="diagZoomOut" title="Zoom arrière (-)">
            <svg width="14" height="14" viewBox="0 0 16 16"><circle cx="6.5" cy="6.5" r="4.5" fill="none" stroke="currentColor" stroke-width="1.5"/><line x1="10" y1="10" x2="14" y2="14" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><line x1="4.5" y1="6.5" x2="8.5" y2="6.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
        </button>
        <span id="diagZoomLabel" style="font-size:12px;color:#666;min-width:38px;text-align:center;">100%</span>
        <button class="diag-btn" id="diagZoomIn"  title="Zoom avant (+)">
            <svg width="14" height="14" viewBox="0 0 16 16"><circle cx="6.5" cy="6.5" r="4.5" fill="none" stroke="currentColor" stroke-width="1.5"/><line x1="10" y1="10" x2="14" y2="14" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><line x1="6.5" y1="4.5" x2="6.5" y2="8.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><line x1="4.5" y1="6.5" x2="8.5" y2="6.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
        </button>
        <button class="diag-btn" id="diagZoomFit" title="Ajuster la vue (F)">
            <svg width="14" height="14" viewBox="0 0 16 16"><polyline points="1,5 1,1 5,1" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><polyline points="11,1 15,1 15,5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><polyline points="15,11 15,15 11,15" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><polyline points="5,15 1,15 1,11" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
            Ajuster
        </button>

        <div class="sep"></div>

        <button class="diag-btn" id="diagToggleGrid" title="Afficher/masquer la grille (G)">
            <svg width="14" height="14" viewBox="0 0 16 16"><line x1="0" y1="5.3" x2="16" y2="5.3" stroke="currentColor" stroke-width=".9"/><line x1="0" y1="10.6" x2="16" y2="10.6" stroke="currentColor" stroke-width=".9"/><line x1="5.3" y1="0" x2="5.3" y2="16" stroke="currentColor" stroke-width=".9"/><line x1="10.6" y1="0" x2="10.6" y2="16" stroke="currentColor" stroke-width=".9"/></svg>
        </button>
        <button class="diag-btn" id="diagToggleSnap"  title="Magnétisme grille">
            <svg width="14" height="14" viewBox="0 0 16 16"><circle cx="8" cy="8" r="3" fill="none" stroke="currentColor" stroke-width="1.5"/><line x1="8" y1="1" x2="8" y2="4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><line x1="8" y1="12" x2="8" y2="15" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><line x1="1" y1="8" x2="4" y2="8" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/><line x1="12" y1="8" x2="15" y2="8" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"/></svg>
        </button>

        <div class="sep"></div>

        <button class="diag-btn" id="diagImportBtn" title="Importer JSON">
            <svg width="14" height="14" viewBox="0 0 16 16"><polyline points="8,3 8,11" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><polyline points="5,8 8,11 11,8" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><polyline points="2,12 2,15 14,15 14,12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
        <button class="diag-btn" id="diagExportJSON" title="Exporter JSON">
            <svg width="14" height="14" viewBox="0 0 16 16"><polyline points="8,12 8,4" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/><polyline points="5,7 8,4 11,7" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><polyline points="2,12 2,15 14,15 14,12" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
        <button class="diag-btn" id="diagExportSVG" title="Exporter SVG">
            SVG
        </button>
        <button class="diag-btn" id="diagExportPNG" title="Exporter PNG">
            PNG
        </button>

        <div class="sep"></div>

        <c:if test="${canEdit}">
            <button class="diag-btn" id="diagSelectAll" title="Tout sélectionner (Ctrl+A)">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="1" y="1" width="14" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.4" stroke-dasharray="3 2"/></svg>
            </button>
            <button class="diag-btn" id="diagDuplicateBtn" title="Dupliquer (Ctrl+D)">
                <svg width="14" height="14" viewBox="0 0 16 16"><rect x="5" y="5" width="9" height="9" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M2 11V2h9" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </button>
        </c:if>
    </div>

    <%-- ── Barre de propriétés (sélection active) ── --%>
    <div class="diagram-props-bar" id="diagPropsBar">
        <label>Label <input type="text" id="propLabel" placeholder="texte…" style="width:120px"></label>
        <span class="sep" style="height:16px;"></span>
        <label>Fond <input type="color" id="propFill" value="#e8f4fd"></label>
        <label>Contour <input type="color" id="propStroke" value="#4a90d9"></label>
        <label>Épaisseur
            <select id="propStrokeW">
                <option value="1">1px</option>
                <option value="1.5" selected>1.5px</option>
                <option value="2">2px</option>
                <option value="3">3px</option>
            </select>
        </label>
        <label>Trait
            <select id="propStrokeDash">
                <option value="">─── Plein</option>
                <option value="8,4">╌╌╌ Tirets</option>
                <option value="3,4">··· Pointillés</option>
                <option value="12,4">━━━ Long</option>
                <option value="8,4,3,4">─·─ Mixte</option>
            </select>
        </label>
        <label>Texte <input type="color" id="propTextColor" value="#1a1a2e"></label>
        <label>Taille
            <select id="propFontSize">
                <option value="10">10</option>
                <option value="12" selected>12</option>
                <option value="13">13</option>
                <option value="14">14</option>
                <option value="16">16</option>
                <option value="18">18</option>
            </select>
        </label>
        <label>Gras <input type="checkbox" id="propBold"></label>
        <span class="sep" style="height:16px;"></span>
        <label>W <input type="number" id="propW" min="30" max="800" step="5" style="width:55px"></label>
        <label>H <input type="number" id="propH" min="20" max="600" step="5" style="width:55px"></label>
        <label>X <input type="number" id="propX" step="1" style="width:55px"></label>
        <label>Y <input type="number" id="propY" step="1" style="width:55px"></label>
        <label>Arrondi <input type="number" id="propRx" min="0" max="80" value="6" style="width:48px"></label>
        <span class="sep" style="height:16px;"></span>
        <label>Flèche début
            <select id="propMarkerStart">
                <option value="none">Aucune</option>
                <option value="arrow">Flèche ◀</option>
                <option value="openArrow">Ouvert ◁</option>
                <option value="circle">Cercle ●</option>
                <option value="diamond">Losange ◆</option>
            </select>
        </label>
        <label>Flèche fin
            <select id="propMarkerEnd">
                <option value="arrow" selected>Flèche ▶</option>
                <option value="openArrow">Ouvert ▷</option>
                <option value="circle">Cercle ●</option>
                <option value="diamond">Losange ◆</option>
                <option value="none">Aucune</option>
            </select>
        </label>
        <label>Ligne
            <select id="propEdgeStyle">
                <option value="straight">Droite</option>
                <option value="curved" selected>Courbée</option>
                <option value="elbow">Coudée</option>
                <option value="step">Escalier</option>
            </select>
        </label>
    </div>

    <%-- ── Canvas SVG ── --%>
    <div class="diagram-canvas-wrap" id="diagCanvasWrap">
        <svg id="diagramSvg" class="diagram-svg" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <%-- Marqueurs fléchés --%>
                <marker id="diag-arrow-end" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
                    <polygon points="0 0,10 3.5,0 7" fill="#4a90d9"/>
                </marker>
                <marker id="diag-arrow-start" markerWidth="10" markerHeight="7" refX="1" refY="3.5" orient="auto-start-reverse">
                    <polygon points="0 0,10 3.5,0 7" fill="#4a90d9"/>
                </marker>
                <marker id="diag-open-end" markerWidth="10" markerHeight="7" refX="8" refY="3.5" orient="auto">
                    <polyline points="1,1 9,3.5 1,6" fill="none" stroke="#4a90d9" stroke-width="1.5"/>
                </marker>
                <marker id="diag-circle-end" markerWidth="8" markerHeight="8" refX="4" refY="4" orient="auto">
                    <circle cx="4" cy="4" r="3" fill="#fff" stroke="#4a90d9" stroke-width="1.5"/>
                </marker>
                <marker id="diag-circle-start" markerWidth="8" markerHeight="8" refX="4" refY="4" orient="auto-start-reverse">
                    <circle cx="4" cy="4" r="3" fill="#fff" stroke="#4a90d9" stroke-width="1.5"/>
                </marker>
                <marker id="diag-diamond-end" markerWidth="12" markerHeight="7" refX="11" refY="3.5" orient="auto">
                    <polygon points="0,3.5 5.5,0 11,3.5 5.5,7" fill="#fff" stroke="#4a90d9" stroke-width="1.2"/>
                </marker>
                <marker id="diag-diamond-start" markerWidth="12" markerHeight="7" refX="1" refY="3.5" orient="auto-start-reverse">
                    <polygon points="0,3.5 5.5,0 11,3.5 5.5,7" fill="#fff" stroke="#4a90d9" stroke-width="1.2"/>
                </marker>
                <%-- Grille --%>
                <pattern id="diag-grid-small" width="20" height="20" patternUnits="userSpaceOnUse">
                    <path d="M20 0H0V20" fill="none" stroke="#e0e0e0" stroke-width="0.5"/>
                </pattern>
                <pattern id="diag-grid-large" width="100" height="100" patternUnits="userSpaceOnUse">
                    <rect width="100" height="100" fill="url(#diag-grid-small)"/>
                    <path d="M100 0H0V100" fill="none" stroke="#ccc" stroke-width="1"/>
                </pattern>
            </defs>

            <%-- Groupe transformable (zoom/pan) --%>
            <g id="diagramGroup">
                <%-- Grille (fond) --%>
                <rect id="diag-grid-rect" x="-5000" y="-5000" width="10000" height="10000"
                      fill="url(#diag-grid-large)" style="display:none;" class="diag-grid"/>

                <%-- Connecteurs (sous les nœuds) --%>
                <g id="edgesGroup"></g>

                <%-- Nœuds --%>
                <g id="nodesGroup"></g>

                <%-- Rectangle de sélection ── --%>
                <rect id="diag-sel-rect" style="display:none;"/>

                <%-- Prévisualisation connexion --%>
                <path id="diag-conn-preview" style="display:none;"/>
            </g>
        </svg>

        <%-- Minimap --%>
        <div id="diag-minimap">
            <svg id="diagMinimapSvg" xmlns="http://www.w3.org/2000/svg">
                <g id="diagMinimapGroup"></g>
                <rect id="diag-minimap-viewport" x="0" y="0" width="100" height="60"/>
            </svg>
        </div>

        <%-- Info zoom --%>
        <div id="diag-info">0, 0</div>
    </div>

    <%-- Input label inline --%>
    <input type="text" id="diagNodeInput" placeholder="Label" autocomplete="off" style="display:none;"/>

    <%-- Import JSON (file input caché) --%>
    <input type="file" id="diagImportFile" accept=".json" style="display:none"/>

    <%-- Context menu --%>
    <div id="diag-ctx-menu">
        <div class="ctx-item" id="ctx-edit">
            <svg width="14" height="14" viewBox="0 0 16 16"><path d="M11 2L14 5L5 14H2V11Z" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/></svg>
            Éditer le label
        </div>
        <div class="ctx-item" id="ctx-dup">
            <svg width="14" height="14" viewBox="0 0 16 16"><rect x="5" y="5" width="9" height="9" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M2 11V2h9" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
            Dupliquer
        </div>
        <div class="ctx-item" id="ctx-front">
            <svg width="14" height="14" viewBox="0 0 16 16"><rect x="1" y="4" width="9" height="9" rx="1" fill="none" stroke="currentColor" stroke-width="1.4" opacity=".4"/><rect x="6" y="1" width="9" height="9" rx="1" fill="#fff" stroke="currentColor" stroke-width="1.4"/></svg>
            Premier plan
        </div>
        <div class="ctx-item" id="ctx-back">
            <svg width="14" height="14" viewBox="0 0 16 16"><rect x="6" y="6" width="9" height="9" rx="1" fill="none" stroke="currentColor" stroke-width="1.4" opacity=".4"/><rect x="1" y="1" width="9" height="9" rx="1" fill="#fff" stroke="currentColor" stroke-width="1.4"/></svg>
            Arrière-plan
        </div>
        <div class="ctx-item sep-top" id="ctx-props">
            <svg width="14" height="14" viewBox="0 0 16 16"><circle cx="8" cy="8" r="5.5" fill="none" stroke="currentColor" stroke-width="1.4"/><line x1="8" y1="8" x2="8" y2="11" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><circle cx="8" cy="5.5" r=".9" fill="currentColor"/></svg>
            Propriétés
        </div>
        <div class="ctx-item danger sep-top" id="ctx-del">
            <svg width="14" height="14" viewBox="0 0 16 16"><polyline points="2,4 14,4" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><path d="M5 4V2h6v2M3 4l1 10h8l1-10" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>
            Supprimer
        </div>
    </div>

    <%-- Toast --%>
    <div id="diag-toast"></div>
</div>

<%-- ═══════════════════════════════════════════════════════════
     JAVASCRIPT
     ═══════════════════════════════════════════════════════════ --%>
<script>
(function () {
'use strict';

/* -- Configuration -------------------------------------- */
var READONLY   = ${!canEdit};
var SNAP       = 20;        // Taille grille magnetisme
var MIN_ZOOM   = .1;
var MAX_ZOOM   = 8;
var HIST_LIMIT = 60;        // Taille historique undo

/* -- État global ---------------------------------------- */
var state = {
    nodes : [],   // { id, type, x,y,w,h, label, fill,stroke,strokeW,strokeDash,textColor,fontSize,fontBold,rx }
    edges : [],   // { id, src,dst, label, markerStart,markerEnd, style, stroke,strokeW,strokeDash }
    zoom  : 1,
    panX  : 0,
    panY  : 0
};

var idSeq      = 1;
var uid        = function() { return 'n' + (idSeq++); };

var selection  = [];  // ids selectionnes
var activeTool = 'select';
var gridVisible = false;
var snapEnabled = false;

// Historique
var history   = [];
var histIdx   = -1;

// Drag / interaction
var drag      = null;
var pan       = null;
var selBox    = null;
var connSrc   = null;  // { nodeId, port }

/* -- Élements DOM --------------------------------------- */
var editorEl  = document.getElementById('diagramEditor');
var svgEl     = document.getElementById('diagramSvg');
var groupEl   = document.getElementById('diagramGroup');
var edgesGrp  = document.getElementById('edgesGroup');
var nodesGrp  = document.getElementById('nodesGroup');
var canvasWrap= document.getElementById('diagCanvasWrap');
var gridRect  = document.getElementById('diag-grid-rect');
var selRectEl = document.getElementById('diag-sel-rect');
var connPrev  = document.getElementById('diag-conn-preview');
var labelInput= document.getElementById('diagNodeInput');
var propsBar  = document.getElementById('diagPropsBar');
var zoomLabel = document.getElementById('diagZoomLabel');
var infoEl    = document.getElementById('diag-info');
var ctxMenu   = document.getElementById('diag-ctx-menu');
var toastEl   = document.getElementById('diag-toast');
var mmGrp     = document.getElementById('diagMinimapGroup');
var mmVP      = document.getElementById('diag-minimap-viewport');

/* ======================================================
   UTILS
   ====================================================== */
function snap(v) { return snapEnabled ? Math.round(v / SNAP) * SNAP : v; }
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

function svgPoint(e) {
    var rect = svgEl.getBoundingClientRect();
    var cx = (e.clientX !== undefined ? e.clientX : e.touches[0].clientX);
    var cy = (e.clientY !== undefined ? e.clientY : e.touches[0].clientY);
    return {
        x: (cx - rect.left - state.panX) / state.zoom,
        y: (cy - rect.top  - state.panY) / state.zoom
    };
}

function toast(msg, dur) {
    toastEl.textContent = msg;
    toastEl.classList.add('show');
    clearTimeout(toastEl._t);
    toastEl._t = setTimeout(function() { toastEl.classList.remove('show'); }, dur || 1600);
}

function copyObj(o) { return JSON.parse(JSON.stringify(o)); }

/* ======================================================
   HISTORIQUE (UNDO/REDO)
   ====================================================== */
function pushHistory() {
    history.splice(histIdx + 1);
    history.push(copyObj({nodes: state.nodes, edges: state.edges}));
    if (history.length > HIST_LIMIT) history.shift();
    histIdx = history.length - 1;
    updateUndoRedo();
}

function updateUndoRedo() {
    var _ub=document.getElementById('diagUndoBtn'); if(_ub) _ub.disabled = histIdx <= 0;
    var _rb=document.getElementById('diagRedoBtn'); if(_rb) _rb.disabled = histIdx >= history.length - 1;
}

function undo() {
    if (histIdx <= 0) return;
    histIdx--;
    var snap2 = history[histIdx];
    state.nodes = copyObj(snap2.nodes);
    state.edges = copyObj(snap2.edges);
    selection = [];
    render();
    updateUndoRedo();
}

function redo() {
    if (histIdx >= history.length - 1) return;
    histIdx++;
    var snap2 = history[histIdx];
    state.nodes = copyObj(snap2.nodes);
    state.edges = copyObj(snap2.edges);
    selection = [];
    render();
    updateUndoRedo();
}

/* ======================================================
   RENDU SVG
   ====================================================== */
function applyTransform() {
    groupEl.setAttribute('transform',
        'translate(' + state.panX + ',' + state.panY + ') scale(' + state.zoom + ')');
    zoomLabel.textContent = Math.round(state.zoom * 100) + '%';
}

function nodeCenter(n) {
    return { x: n.x + n.w / 2, y: n.y + n.h / 2 };
}

function nodePort(n, side) {
    switch(side) {
        case 'top':    return { x: n.x + n.w/2, y: n.y };
        case 'bottom': return { x: n.x + n.w/2, y: n.y + n.h };
        case 'left':   return { x: n.x,          y: n.y + n.h/2 };
        case 'right':  return { x: n.x + n.w,    y: n.y + n.h/2 };
        default:       return nodeCenter(n);
    }
}

function bestPorts(src, dst) {
    var sc = nodeCenter(src), dc = nodeCenter(dst);
    var dx = dc.x - sc.x, dy = dc.y - sc.y;
    var sp, dp;
    if (Math.abs(dx) > Math.abs(dy)) {
        sp = dx > 0 ? 'right' : 'left';
        dp = dx > 0 ? 'left'  : 'right';
    } else {
        sp = dy > 0 ? 'bottom' : 'top';
        dp = dy > 0 ? 'top'    : 'bottom';
    }
    return { sp: nodePort(src, sp), dp: nodePort(dst, dp), sSide: sp, dSide: dp };
}

function edgePath(e) {
    var src = state.nodes.find(function(n){ return n.id === e.src; });
    var dst = state.nodes.find(function(n){ return n.id === e.dst; });
    if (!src || !dst) return '';
    var p = bestPorts(src, dst);
    var x1 = p.sp.x, y1 = p.sp.y, x2 = p.dp.x, y2 = p.dp.y;
    var style = e.style || 'curved';

    if (style === 'straight') {
        return 'M' + x1 + ',' + y1 + 'L' + x2 + ',' + y2;
    }
    if (style === 'curved') {
        var dx = x2 - x1, dy = y2 - y1;
        var cp1x, cp1y, cp2x, cp2y;
        if (Math.abs(dx) > Math.abs(dy)) {
            cp1x = x1 + dx * .4; cp1y = y1;
            cp2x = x2 - dx * .4; cp2y = y2;
        } else {
            cp1x = x1; cp1y = y1 + dy * .4;
            cp2x = x2; cp2y = y2 - dy * .4;
        }
        return 'M' + x1 + ',' + y1 + ' C' + cp1x + ',' + cp1y + ' ' + cp2x + ',' + cp2y + ' ' + x2 + ',' + y2;
    }
    if (style === 'elbow') {
        var mx = (x1 + x2) / 2;
        return 'M' + x1 + ',' + y1 + 'L' + mx + ',' + y1 + 'L' + mx + ',' + y2 + 'L' + x2 + ',' + y2;
    }
    if (style === 'step') {
        return 'M' + x1 + ',' + y1 + 'L' + x1 + ',' + y2 + 'L' + x2 + ',' + y2;
    }
    return 'M' + x1 + ',' + y1 + 'L' + x2 + ',' + y2;
}

/* Markers dynamiques : un marker unique par couleur, cree a la demande dans <defs> */
var _markerCache = {};

function ensureMarker(type, color, isStart) {
    if (type === 'none') return 'none';
    var safeColor = color.replace('#','').replace(/[^a-fA-F0-9]/g,'');
    var key = type + '_' + safeColor + (isStart ? '_s' : '_e');
    if (_markerCache[key]) return 'url(#' + key + ')';

    var defs = svgEl.querySelector('defs');
    if (!defs) return 'none';

    var marker = svgNS('marker');
    marker.setAttribute('id', key);
    marker.setAttribute('orient', isStart ? 'auto-start-reverse' : 'auto');

    var shape;
    switch(type) {
        case 'arrow':
            marker.setAttribute('markerWidth',  '10');
            marker.setAttribute('markerHeight', '7');
            marker.setAttribute('refX', isStart ? '1' : '9');
            marker.setAttribute('refY', '3.5');
            shape = svgNS('polygon');
            shape.setAttribute('points', '0 0,10 3.5,0 7');
            shape.setAttribute('fill', color);
            break;
        case 'openArrow':
            marker.setAttribute('markerWidth',  '10');
            marker.setAttribute('markerHeight', '7');
            marker.setAttribute('refX', isStart ? '2' : '8');
            marker.setAttribute('refY', '3.5');
            shape = svgNS('polyline');
            shape.setAttribute('points', '1,1 9,3.5 1,6');
            shape.setAttribute('fill',   'none');
            shape.setAttribute('stroke', color);
            shape.setAttribute('stroke-width', '1.5');
            break;
        case 'circle':
            marker.setAttribute('markerWidth',  '8');
            marker.setAttribute('markerHeight', '8');
            marker.setAttribute('refX', '4');
            marker.setAttribute('refY', '4');
            shape = svgNS('circle');
            shape.setAttribute('cx', '4'); shape.setAttribute('cy', '4'); shape.setAttribute('r', '3');
            shape.setAttribute('fill',   '#fff');
            shape.setAttribute('stroke', color);
            shape.setAttribute('stroke-width', '1.5');
            break;
        case 'diamond':
            marker.setAttribute('markerWidth',  '12');
            marker.setAttribute('markerHeight', '7');
            marker.setAttribute('refX', isStart ? '1' : '11');
            marker.setAttribute('refY', '3.5');
            shape = svgNS('polygon');
            shape.setAttribute('points', '0,3.5 5.5,0 11,3.5 5.5,7');
            shape.setAttribute('fill',   '#fff');
            shape.setAttribute('stroke', color);
            shape.setAttribute('stroke-width', '1.2');
            break;
        default:
            return 'none';
    }
    marker.appendChild(shape);
    defs.appendChild(marker);
    _markerCache[key] = true;
    return 'url(#' + key + ')';
}

function markerUrl(type, color)      { return ensureMarker(type, color || '#4a90d9', false); }
function markerUrlStart(type, color) { return ensureMarker(type, color || '#4a90d9', true);  }

function svgNS(tag) { return document.createElementNS('http://www.w3.org/2000/svg', tag); }

function renderEdge(e) {
    var g = svgNS('g');
    g.setAttribute('class', 'diag-edge' + (selection.indexOf(e.id) >= 0 ? ' selected' : ''));
    g.setAttribute('data-id', e.id);

    var path = svgNS('path');
    path.setAttribute('d', edgePath(e));
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', e.stroke || '#4a90d9');
    path.setAttribute('stroke-width', e.strokeW || 1.5);
    if (e.strokeDash) path.setAttribute('stroke-dasharray', e.strokeDash);
    var eColor = e.stroke || '#4a90d9';
    if ((e.markerEnd || 'arrow') !== 'none')
        path.setAttribute('marker-end',   markerUrl(e.markerEnd || 'arrow', eColor));
    if ((e.markerStart || 'none') !== 'none')
        path.setAttribute('marker-start', markerUrlStart(e.markerStart, eColor));
    g.appendChild(path);

    if (e.label) {
        var src = state.nodes.find(function(n){ return n.id === e.src; });
        var dst = state.nodes.find(function(n){ return n.id === e.dst; });
        if (src && dst) {
            var sc = nodeCenter(src), dc = nodeCenter(dst);
            var lx = (sc.x + dc.x) / 2, ly = (sc.y + dc.y) / 2 - 7;
            var bg = svgNS('rect');
            var txt = svgNS('text');
            txt.setAttribute('x', lx);
            txt.setAttribute('y', ly);
            txt.setAttribute('text-anchor', 'middle');
            txt.setAttribute('font-size', '11');
            txt.setAttribute('fill', '#555');
            txt.setAttribute('font-family', 'Segoe UI,system-ui,sans-serif');
            txt.setAttribute('class', 'diag-edge-label');
            txt.textContent = e.label;
            // Background
            var lblW = Math.max(40, (e.label.length * 7) + 12);
            bg.setAttribute('x', lx - lblW/2);
            bg.setAttribute('y', ly - 11);
            bg.setAttribute('width',  lblW);
            bg.setAttribute('height', 14);
            bg.setAttribute('rx', 3);
            bg.setAttribute('fill', 'rgba(255,255,255,.85)');
            bg.setAttribute('stroke', '#ddd');
            bg.setAttribute('stroke-width', '.5');
            g.appendChild(bg);
            g.appendChild(txt);
        }
    }

    if (!READONLY) {
        g.addEventListener('click',     function(ev) { ev.stopPropagation(); selectEl(e.id, ev); });
        g.addEventListener('dblclick',  function(ev) { ev.stopPropagation(); startEditLabel(e.id, g, true); });
        g.addEventListener('contextmenu', function(ev) { ev.preventDefault(); ev.stopPropagation(); showCtxMenu(ev, e.id); });
    }
    return g;
}

function renderNode(n) {
    var sel = selection.indexOf(n.id) >= 0;
    var g = svgNS('g');
    g.setAttribute('class', 'diag-node' + (sel ? ' selected' : ''));
    g.setAttribute('data-id', n.id);

    var fill   = n.fill   || '#e8f4fd';
    var stroke = n.stroke || '#4a90d9';
    var sw     = n.strokeW || 1.5;
    var rx     = (n.rx !== undefined) ? n.rx : 6;

    // Forme
    var shape;
    if (n.type === 'rect' || n.type === 'text') {
        shape = svgNS('rect');
        shape.setAttribute('x', n.x);
        shape.setAttribute('y', n.y);
        shape.setAttribute('width',  n.w);
        shape.setAttribute('height', n.h);
        shape.setAttribute('rx', n.type === 'text' ? 0 : rx);
        if (n.type === 'text') {
            shape.setAttribute('fill', 'none');
            shape.setAttribute('stroke', 'none');
        } else {
            shape.setAttribute('fill',   fill);
            shape.setAttribute('stroke', stroke);
            shape.setAttribute('stroke-width', sw);
            if (n.strokeDash) shape.setAttribute('stroke-dasharray', n.strokeDash);
        }
    } else if (n.type === 'circle') {
        shape = svgNS('ellipse');
        shape.setAttribute('cx', n.x + n.w / 2);
        shape.setAttribute('cy', n.y + n.h / 2);
        shape.setAttribute('rx', n.w / 2);
        shape.setAttribute('ry', n.h / 2);
        shape.setAttribute('fill',   fill);
        shape.setAttribute('stroke', stroke);
        shape.setAttribute('stroke-width', sw);
        if (n.strokeDash) shape.setAttribute('stroke-dasharray', n.strokeDash);
    } else if (n.type === 'diamond') {
        var cx = n.x + n.w/2, cy = n.y + n.h/2;
        shape = svgNS('polygon');
        shape.setAttribute('points',
            cx + ',' + n.y + ' ' +
            (n.x+n.w) + ',' + cy + ' ' +
            cx + ',' + (n.y+n.h) + ' ' +
            n.x + ',' + cy);
        shape.setAttribute('fill',   fill);
        shape.setAttribute('stroke', stroke);
        shape.setAttribute('stroke-width', sw);
        if (n.strokeDash) shape.setAttribute('stroke-dasharray', n.strokeDash);
    }
    shape.setAttribute('class', 'diag-shape');
    g.appendChild(shape);

    // Label
    if (n.label) {
        var lines = n.label.split('\n');
        var tx = n.x + n.w / 2;
        var totalH = lines.length * ((n.fontSize || 12) * 1.35);
        var ty = n.y + n.h / 2 - totalH / 2 + (n.fontSize || 12);
        lines.forEach(function(line, i) {
            var t = svgNS('text');
            t.setAttribute('x', tx);
            t.setAttribute('y', ty + i * (n.fontSize || 12) * 1.35);
            t.setAttribute('text-anchor', 'middle');
            t.setAttribute('font-size', n.fontSize || 12);
            t.setAttribute('fill', n.textColor || '#1a1a2e');
            t.setAttribute('font-family', 'Segoe UI,system-ui,sans-serif');
            if (n.fontBold) t.setAttribute('font-weight', '600');
            t.setAttribute('pointer-events', 'none');
            t.textContent = line;
            g.appendChild(t);
        });
    }

    // Ports de connexion (visibles en mode connect)
    ['top','right','bottom','left'].forEach(function(side) {
        var p = nodePort(n, side);
        var c = svgNS('circle');
        c.setAttribute('class', 'conn-port');
        c.setAttribute('cx', p.x);
        c.setAttribute('cy', p.y);
        c.setAttribute('r', 5);
        c.setAttribute('data-side', side);
        g.appendChild(c);
    });

    // Handles de redimensionnement (selection unique)
    if (sel && selection.length === 1 && !READONLY) {
        var handles = [
            {cx: n.x,          cy: n.y,          cursor:'nw-resize'},
            {cx: n.x+n.w/2,    cy: n.y,          cursor:'n-resize'},
            {cx: n.x+n.w,      cy: n.y,          cursor:'ne-resize'},
            {cx: n.x+n.w,      cy: n.y+n.h/2,    cursor:'e-resize'},
            {cx: n.x+n.w,      cy: n.y+n.h,      cursor:'se-resize'},
            {cx: n.x+n.w/2,    cy: n.y+n.h,      cursor:'s-resize'},
            {cx: n.x,          cy: n.y+n.h,      cursor:'sw-resize'},
            {cx: n.x,          cy: n.y+n.h/2,    cursor:'w-resize'}
        ];
        handles.forEach(function(h, idx) {
            var r = svgNS('rect');
            r.setAttribute('class','sel-handle');
            r.setAttribute('x', h.cx - 4);
            r.setAttribute('y', h.cy - 4);
            r.setAttribute('width',  8);
            r.setAttribute('height', 8);
            r.setAttribute('rx', 2);
            r.setAttribute('style', 'cursor:' + h.cursor);
            r.setAttribute('data-hndl', idx);
            r.addEventListener('mousedown', function(ev) {
                ev.stopPropagation();
                startResize(ev, n, idx);
            });
            g.appendChild(r);
        });
    }

    if (!READONLY) {
        g.addEventListener('mousedown',   function(ev) { onNodeMouseDown(ev, n); });
        g.addEventListener('dblclick',    function(ev) { ev.stopPropagation(); startEditLabel(n.id, g, false); });
        g.addEventListener('contextmenu', function(ev) { ev.preventDefault(); ev.stopPropagation(); showCtxMenu(ev, n.id); });
        g.addEventListener('mouseenter',  function()   { onNodeHover(n, true); });
        g.addEventListener('mouseleave',  function()   { onNodeHover(n, false); });
    }
    return g;
}

function render() {
    // Vider
    while (edgesGrp.firstChild) edgesGrp.removeChild(edgesGrp.firstChild);
    while (nodesGrp.firstChild) nodesGrp.removeChild(nodesGrp.firstChild);

    state.edges.forEach(function(e) { edgesGrp.appendChild(renderEdge(e)); });
    state.nodes.forEach(function(n) { nodesGrp.appendChild(renderNode(n)); });

    applyTransform();
    updatePropsBar();
    updateMinimap();
    emitChange();
}

/* ======================================================
   SÉLECTION
   ====================================================== */
function selectEl(id, ev) {
    if (!ev || (!ev.shiftKey && !ev.ctrlKey && !ev.metaKey)) {
        selection = [id];
    } else {
        var i = selection.indexOf(id);
        if (i >= 0) selection.splice(i, 1);
        else selection.push(id);
    }
    render();
}

function clearSelection() {
    selection = [];
    render();
}

function selectAll() {
    selection = state.nodes.map(function(n){ return n.id; })
               .concat(state.edges.map(function(e){ return e.id; }));
    render();
}

/* ======================================================
   OUTIL ACTIF
   ====================================================== */
function setTool(t) {
    activeTool = t;
    document.querySelectorAll('.diag-tool').forEach(function(btn) {
        btn.classList.toggle('active', btn.dataset.shape === t);
    });
    var cls = svgEl.className.baseVal.replace(/\btool-\S+\b/g, '').trim();
    if (t !== 'select') cls += ' tool-' + t;
    svgEl.setAttribute('class', 'diagram-svg ' + cls.trim());
    if (t === 'select' || t === 'connect') clearSelection();
}

/* ======================================================
   CRÉATION DE NŒUDS
   ====================================================== */
function defaultNode(type, x, y) {
    var w = type === 'text' ? 100 : (type === 'diamond' ? 120 : 140);
    var h = type === 'text' ? 30  : (type === 'diamond' ? 70  : 50);
    return {
        id: uid(), type: type,
        x: snap(x - w/2), y: snap(y - h/2),
        w: w, h: h,
        label: type === 'text' ? 'Texte' : 'Noeud',
        fill:   type === 'text' ? 'none' : '#e8f4fd',
        stroke: type === 'text' ? 'none' : '#4a90d9',
        strokeW: 1.5, strokeDash: '',
        textColor: '#1a1a2e',
        fontSize: 12, fontBold: false,
        rx: 6
    };
}

function addNode(type, x, y) {
    var n = defaultNode(type, x, y);
    state.nodes.push(n);
    pushHistory();
    selection = [n.id];
    render();
    startEditLabel(n.id, null, false);
    return n;
}

/* ======================================================
   DRAG & DROP NŒUDS
   ====================================================== */
function onNodeMouseDown(ev, n) {
    if (ev.button !== 0) return;
    ev.stopPropagation();

    if (activeTool === 'connect') {
        connSrc = n.id;
        connPrev.style.display = '';
        return;
    }

    if (activeTool !== 'select') return;

    if (selection.indexOf(n.id) < 0) {
        if (!ev.shiftKey && !ev.ctrlKey) selection = [n.id];
        else selection.push(n.id);
        render();
    }

    var startPos = svgPoint(ev);
    var origPositions = {};
    selection.forEach(function(id) {
        var nd = state.nodes.find(function(x){ return x.id === id; });
        if (nd) origPositions[id] = { x: nd.x, y: nd.y };
    });

    drag = { type: 'move', sx: startPos.x, sy: startPos.y, origins: origPositions };
    ev.preventDefault();
}

/* ======================================================
   REDIMENSIONNEMENT
   ====================================================== */
var HNDL_CURSORS = ['nw','n','ne','e','se','s','sw','w'];
function startResize(ev, n, hndlIdx) {
    if (ev.button !== 0) return;
    var orig = { x:n.x, y:n.y, w:n.w, h:n.h };
    var pt = svgPoint(ev);
    drag = { type: 'resize', nodeId: n.id, hndl: hndlIdx, orig: orig, sx: pt.x, sy: pt.y };
    ev.preventDefault();
}

/* ======================================================
   ÉVÉNEMENTS SOURIS GLOBAUX
   ====================================================== */
svgEl.addEventListener('mousedown', function(ev) {
    closeCtxMenu();
    if (ev.button === 1 || (ev.button === 0 && activeTool === 'pan') || (ev.button === 0 && ev.altKey)) {
        pan = { sx: ev.clientX - state.panX, sy: ev.clientY - state.panY };
        svgEl.classList.add('panning');
        ev.preventDefault();
        return;
    }
    if (ev.button !== 0) return;

    var pt = svgPoint(ev);

    if (activeTool === 'rect' || activeTool === 'circle' ||
        activeTool === 'diamond' || activeTool === 'text') {
        addNode(activeTool, pt.x, pt.y);
        setTool('select');
        return;
    }

    /* Reset de la connexion en cours si clic sur fond */
    if (connSrc) {
        connSrc = null;
        connPrev.style.display = 'none';
    }

    if (activeTool === 'select') {
        // Debut selection rectangulaire
        clearSelection();
        selBox = { x0: pt.x, y0: pt.y };
        selRectEl.style.display = '';
        selRectEl.setAttribute('x', pt.x);
        selRectEl.setAttribute('y', pt.y);
        selRectEl.setAttribute('width', 0);
        selRectEl.setAttribute('height', 0);
    }
});

svgEl.addEventListener('mousemove', function(ev) {
    var pt = svgPoint(ev);

    // Infos coordonnees
    infoEl.textContent = Math.round(pt.x) + ', ' + Math.round(pt.y);

    if (pan) {
        state.panX = ev.clientX - pan.sx;
        state.panY = ev.clientY - pan.sy;
        applyTransform();
        updateMinimap();
        return;
    }

    if (drag && drag.type === 'move') {
        var dx = pt.x - drag.sx, dy = pt.y - drag.sy;
        selection.forEach(function(id) {
            var nd = state.nodes.find(function(x){ return x.id === id; });
            if (nd && drag.origins[id]) {
                nd.x = snap(drag.origins[id].x + dx);
                nd.y = snap(drag.origins[id].y + dy);
            }
        });
        render();
        return;
    }

    if (drag && drag.type === 'resize') {
        var n = state.nodes.find(function(x){ return x.id === drag.nodeId; });
        if (!n) return;
        var ddx = pt.x - drag.sx, ddy = pt.y - drag.sy;
        var o = drag.orig;
        switch(drag.hndl) {
            case 0: n.x = snap(o.x+ddx); n.y = snap(o.y+ddy); n.w = Math.max(30,o.w-ddx); n.h = Math.max(20,o.h-ddy); break;
            case 1: n.y = snap(o.y+ddy); n.h = Math.max(20,o.h-ddy); break;
            case 2: n.y = snap(o.y+ddy); n.w = Math.max(30,o.w+ddx); n.h = Math.max(20,o.h-ddy); break;
            case 3: n.w = Math.max(30,o.w+ddx); break;
            case 4: n.w = Math.max(30,o.w+ddx); n.h = Math.max(20,o.h+ddy); break;
            case 5: n.h = Math.max(20,o.h+ddy); break;
            case 6: n.x = snap(o.x+ddx); n.w = Math.max(30,o.w-ddx); n.h = Math.max(20,o.h+ddy); break;
            case 7: n.x = snap(o.x+ddx); n.w = Math.max(30,o.w-ddx); break;
        }
        render();
        return;
    }

    if (selBox) {
        var x = Math.min(pt.x, selBox.x0), y = Math.min(pt.y, selBox.y0);
        var w2 = Math.abs(pt.x - selBox.x0), h2 = Math.abs(pt.y - selBox.y0);
        selRectEl.setAttribute('x', x);
        selRectEl.setAttribute('y', y);
        selRectEl.setAttribute('width',  w2);
        selRectEl.setAttribute('height', h2);
        return;
    }

    // Previsualisation connexion
    if (connSrc) {
        var srcNode = state.nodes.find(function(x){ return x.id === connSrc; });
        if (srcNode) {
            var sc = nodeCenter(srcNode);
            connPrev.setAttribute('d', 'M'+sc.x+','+sc.y+'L'+pt.x+','+pt.y);
        }
    }
});

svgEl.addEventListener('mouseup', function(ev) {
    svgEl.classList.remove('panning');
    if (pan) { pan = null; return; }

    if (drag) {
        if (drag.type === 'move') pushHistory();
        if (drag.type === 'resize') pushHistory();
        drag = null;
        return;
    }

    if (selBox) {
        var r = {
            x:  parseFloat(selRectEl.getAttribute('x')),
            y:  parseFloat(selRectEl.getAttribute('y')),
            w:  parseFloat(selRectEl.getAttribute('width')),
            h:  parseFloat(selRectEl.getAttribute('height'))
        };
        if (r.w > 5 || r.h > 5) {
            selection = state.nodes
                .filter(function(n){ return n.x >= r.x && n.y >= r.y && n.x+n.w <= r.x+r.w && n.y+n.h <= r.y+r.h; })
                .map(function(n){ return n.id; });
            render();
        }
        selBox = null;
        selRectEl.style.display = 'none';
        return;
    }

    if (connSrc) {
        connPrev.style.display = 'none';
        var pt2 = svgPoint(ev);
        var targetNode = null;
        state.nodes.forEach(function(n) {
            if (n.id !== connSrc && pt2.x >= n.x && pt2.x <= n.x+n.w && pt2.y >= n.y && pt2.y <= n.y+n.h) {
                targetNode = n;
            }
        });
        if (targetNode) {
            var e = {
                id: uid(), src: connSrc, dst: targetNode.id,
                label: '', markerStart: 'none', markerEnd: 'arrow',
                style: 'curved', stroke: '#4a90d9', strokeW: 1.5, strokeDash: ''
            };
            state.edges.push(e);
            pushHistory();
            selection = [e.id];
            render();
        }
        connSrc = null;
    }
});

// Hover noeud en mode connect
function onNodeHover(n, enter) {
    if (activeTool !== 'connect') return;
    var el = nodesGrp.querySelector('[data-id="' + n.id + '"]');
    if (el) el.classList.toggle('conn-hover', enter);
}

/* ======================================================
   ÉDITION INLINE LABEL
   ====================================================== */
var editingId = null;

function startEditLabel(id, groupEl2, isEdge) {
    var item = isEdge
        ? state.edges.find(function(e){ return e.id === id; })
        : state.nodes.find(function(n){ return n.id === id; });
    if (!item) return;

    editingId = id;
    labelInput.value = item.label || '';

    /* Positionner l'input par rapport a editorEl (position:relative) */
    var edRect = editorEl.getBoundingClientRect();

    if (!isEdge) {
        var n = item;
        var svgRect = svgEl.getBoundingClientRect();
        /* Coordonnees SVG -> ecran -> relatives a editorEl */
        var screenX = n.x * state.zoom + state.panX + svgRect.left;
        var screenY = (n.y + n.h / 2) * state.zoom + state.panY + svgRect.top;
        var x = screenX - edRect.left;
        var y = screenY - edRect.top;
        var w = Math.max(80, n.w * state.zoom);
        /* Centrer horizontalement sur le noeud */
        labelInput.style.left   = Math.max(0, x - w / 2) + 'px';
        labelInput.style.top    = Math.max(0, y - 13)    + 'px';
        labelInput.style.width  = w + 'px';
    } else {
        /* Pour un edge : centrer dans le canvas */
        labelInput.style.left  = (canvasWrap.clientWidth  / 2 - 80) + 'px';
        labelInput.style.top   = (canvasWrap.clientHeight / 2 - 13) + 'px';
        labelInput.style.width = '160px';
    }

    labelInput.style.display = 'block';
    labelInput.focus();
    labelInput.select();
}

labelInput.addEventListener('keydown', function(ev) {
    if (ev.key === 'Enter' && !ev.shiftKey) { commitLabel(); ev.preventDefault(); }
    if (ev.key === 'Escape') { cancelLabel(); }
});
labelInput.addEventListener('blur', commitLabel);

function commitLabel() {
    if (editingId === null) return;
    var id = editingId;
    editingId = null;
    labelInput.style.display = 'none';
    var node = state.nodes.find(function(n){ return n.id === id; });
    var edge = state.edges.find(function(e){ return e.id === id; });
    if (node) node.label = labelInput.value;
    if (edge) edge.label = labelInput.value;
    pushHistory();
    render();
}

function cancelLabel() {
    editingId = null;
    labelInput.style.display = 'none';
}

/* ======================================================
   BARRE DE PROPRIÉTÉS
   ====================================================== */
function updatePropsBar() {
    if (selection.length === 0 || READONLY) {
        propsBar.classList.remove('visible');
        return;
    }
    propsBar.classList.add('visible');

    var id = selection[selection.length - 1];
    var node = state.nodes.find(function(n){ return n.id === id; });
    var edge = state.edges.find(function(e){ return e.id === id; });
    var item = node || edge;
    if (!item) return;

    document.getElementById('propLabel').value      = item.label     || '';
    document.getElementById('propStroke').value     = item.stroke    || '#4a90d9';
    document.getElementById('propStrokeW').value    = item.strokeW   || 1.5;
    document.getElementById('propStrokeDash').value = item.strokeDash|| '';
    document.getElementById('propMarkerStart').value= item.markerStart|| 'none';
    document.getElementById('propMarkerEnd').value  = item.markerEnd  || 'arrow';
    document.getElementById('propEdgeStyle').value  = item.style      || 'curved';

    /* Champs specifiques aux noeuds */
    var nodeFields = ['propFill','propTextColor','propFontSize','propBold','propW','propH','propX','propY','propRx'];
    var edgeFields = ['propMarkerStart','propMarkerEnd','propEdgeStyle'];
    nodeFields.forEach(function(f){ var el=document.getElementById(f); if(el) el.closest('label') && (el.closest('label').style.display = node ? '' : 'none'); });
    edgeFields.forEach(function(f){ var el=document.getElementById(f); if(el) el.closest('label') && (el.closest('label').style.display = edge ? '' : 'none'); });

    if (node) {
        document.getElementById('propFill').value      = node.fill      || '#e8f4fd';
        document.getElementById('propTextColor').value = node.textColor || '#1a1a2e';
        document.getElementById('propFontSize').value  = node.fontSize  || 12;
        document.getElementById('propBold').checked    = node.fontBold  || false;
        document.getElementById('propW').value = Math.round(node.w);
        document.getElementById('propH').value = Math.round(node.h);
        document.getElementById('propX').value = Math.round(node.x);
        document.getElementById('propY').value = Math.round(node.y);
        document.getElementById('propRx').value= node.rx !== undefined ? node.rx : 6;
    }
}

function applyPropChange(field, value) {
    selection.forEach(function(id) {
        var node = state.nodes.find(function(n){ return n.id === id; });
        var edge = state.edges.find(function(e){ return e.id === id; });
        var item = node || edge;
        if (!item) return;
        switch(field) {
            case 'label':       item.label      = value; break;
            case 'fill':        if(node) node.fill      = value; break;
            case 'stroke':      item.stroke     = value; break;
            case 'strokeW':     item.strokeW    = parseFloat(value); break;
            case 'strokeDash':  item.strokeDash = value; break;
            case 'textColor':   if(node) node.textColor = value; break;
            case 'fontSize':    if(node) node.fontSize  = parseInt(value); break;
            case 'fontBold':    if(node) node.fontBold  = value; break;
            case 'markerStart': if(edge) edge.markerStart = value; break;
            case 'markerEnd':   if(edge) edge.markerEnd   = value; break;
            case 'edgeStyle':   if(edge) edge.style        = value; break;
            case 'w': if(node) node.w = Math.max(30, parseFloat(value)); break;
            case 'h': if(node) node.h = Math.max(20, parseFloat(value)); break;
            case 'x': if(node) node.x = parseFloat(value); break;
            case 'y': if(node) node.y = parseFloat(value); break;
            case 'rx': if(node) node.rx = parseInt(value); break;
        }
    });
    render();
}

function wireProps() {
    var fields = [
        ['propLabel','change','label'],['propFill','change','fill'],
        ['propStroke','input','stroke'],['propStrokeW','change','strokeW'],
        ['propStrokeDash','change','strokeDash'],['propTextColor','input','textColor'],
        ['propFontSize','change','fontSize'],['propBold','change','fontBold'],
        ['propMarkerStart','change','markerStart'],['propMarkerEnd','change','markerEnd'],
        ['propEdgeStyle','change','edgeStyle'],
        ['propW','change','w'],['propH','change','h'],
        ['propX','change','x'],['propY','change','y'],['propRx','change','rx']
    ];
    fields.forEach(function(f) {
        var el = document.getElementById(f[0]);
        if (!el) return;
        el.addEventListener(f[1], function() {
            var v = el.type === 'checkbox' ? el.checked : el.value;
            applyPropChange(f[2], v);
            if (f[1] === 'change') pushHistory();
        });
    });
}

/* ======================================================
   ZOOM / PAN
   ====================================================== */
svgEl.addEventListener('wheel', function(ev) {
    ev.preventDefault();
    var rect = svgEl.getBoundingClientRect();
    var mx = ev.clientX - rect.left, my = ev.clientY - rect.top;
    var delta = ev.deltaY < 0 ? 1.12 : 1/1.12;
    var newZoom = clamp(state.zoom * delta, MIN_ZOOM, MAX_ZOOM);
    state.panX = mx - (mx - state.panX) * (newZoom / state.zoom);
    state.panY = my - (my - state.panY) * (newZoom / state.zoom);
    state.zoom = newZoom;
    applyTransform();
    updateMinimap();
}, { passive: false });

function zoomFit() {
    if (state.nodes.length === 0) { state.zoom = 1; state.panX = 0; state.panY = 0; applyTransform(); return; }
    var xs = state.nodes.map(function(n){ return n.x; });
    var ys = state.nodes.map(function(n){ return n.y; });
    var xe = state.nodes.map(function(n){ return n.x+n.w; });
    var ye = state.nodes.map(function(n){ return n.y+n.h; });
    var minX = Math.min.apply(null,xs), minY = Math.min.apply(null,ys);
    var maxX = Math.max.apply(null,xe), maxY = Math.max.apply(null,ye);
    var pad = 40;
    var cw = canvasWrap.clientWidth  - pad*2;
    var ch = canvasWrap.clientHeight - pad*2;
    var bw = maxX - minX, bh = maxY - minY;
    if (bw < 1) bw = 200; if (bh < 1) bh = 200;
    var z = Math.min(cw/bw, ch/bh, MAX_ZOOM);
    state.zoom = z;
    state.panX = pad - minX * z;
    state.panY = pad - minY * z;
    applyTransform();
    updateMinimap();
}

document.getElementById('diagZoomFit').addEventListener('click', zoomFit);
document.getElementById('diagZoomIn').addEventListener('click',  function(){ state.zoom = clamp(state.zoom*1.25,MIN_ZOOM,MAX_ZOOM); applyTransform(); updateMinimap(); });
document.getElementById('diagZoomOut').addEventListener('click', function(){ state.zoom = clamp(state.zoom/1.25,MIN_ZOOM,MAX_ZOOM); applyTransform(); updateMinimap(); });

/* ======================================================
   GRILLE / MAGNÉTISME
   ====================================================== */
document.getElementById('diagToggleGrid').addEventListener('click', function() {
    gridVisible = !gridVisible;
    gridRect.style.display = gridVisible ? '' : 'none';
    this.classList.toggle('active', gridVisible);
});

document.getElementById('diagToggleSnap').addEventListener('click', function() {
    snapEnabled = !snapEnabled;
    this.classList.toggle('active', snapEnabled);
    toast(snapEnabled ? 'Magnetisme active' : 'Magnetisme desactive');
});

/* ======================================================
   ALIGNEMENT / DISTRIBUTION
   ====================================================== */
function alignSelected(mode) {
    var nodes = selection.map(function(id){ return state.nodes.find(function(n){ return n.id === id; }); }).filter(Boolean);
    if (nodes.length < 2) { toast('Selectionnez au moins 2 noeuds'); return; }
    switch(mode) {
        case 'left':    var lx = Math.min.apply(null,nodes.map(function(n){return n.x})); nodes.forEach(function(n){n.x=lx}); break;
        case 'centerH': var mx2 = (Math.min.apply(null,nodes.map(function(n){return n.x})) + Math.max.apply(null,nodes.map(function(n){return n.x+n.w})))/2; nodes.forEach(function(n){n.x=mx2-n.w/2}); break;
        case 'top':     var ty = Math.min.apply(null,nodes.map(function(n){return n.y})); nodes.forEach(function(n){n.y=ty}); break;
        case 'distribH':
            nodes.sort(function(a,b){return a.x-b.x});
            var totalW = nodes.reduce(function(s,n){return s+n.w},0);
            var span = nodes[nodes.length-1].x+nodes[nodes.length-1].w - nodes[0].x;
            var gap2 = (span-totalW)/(nodes.length-1);
            var cur = nodes[0].x;
            nodes.forEach(function(n){n.x=cur; cur+=n.w+gap2});
            break;
    }
    pushHistory(); render();
}

(document.getElementById('diagAlignLeft')||{addEventListener:function(){}}).addEventListener('click',   function(){ alignSelected('left'); });
(document.getElementById('diagAlignCenterH')||{addEventListener:function(){}}).addEventListener('click', function(){ alignSelected('centerH'); });
(document.getElementById('diagAlignTop')||{addEventListener:function(){}}).addEventListener('click',     function(){ alignSelected('top'); });
(document.getElementById('diagDistribH')||{addEventListener:function(){}}).addEventListener('click',     function(){ alignSelected('distribH'); });

/* ======================================================
   ORDRE Z
   ====================================================== */
(document.getElementById('diagBringFront')||{addEventListener:function(){}}).addEventListener('click', function(){
    selection.forEach(function(id){
        var i = state.nodes.findIndex(function(n){return n.id===id;});
        if (i >= 0) state.nodes.push(state.nodes.splice(i,1)[0]);
    });
    pushHistory(); render();
});
(document.getElementById('diagSendBack')||{addEventListener:function(){}}).addEventListener('click', function(){
    selection.forEach(function(id){
        var i = state.nodes.findIndex(function(n){return n.id===id;});
        if (i >= 0) state.nodes.unshift(state.nodes.splice(i,1)[0]);
    });
    pushHistory(); render();
});

/* ======================================================
   SUPPRESSION
   ====================================================== */
function deleteSelected() {
    if (selection.length === 0) return;
    state.nodes = state.nodes.filter(function(n){ return selection.indexOf(n.id) < 0; });
    state.edges = state.edges.filter(function(e){
        return selection.indexOf(e.id) < 0 &&
               selection.indexOf(e.src) < 0 &&
               selection.indexOf(e.dst) < 0;
    });
    selection = [];
    pushHistory(); render();
}
(document.getElementById('diagDeleteBtn')||{addEventListener:function(){}}).addEventListener('click', deleteSelected);

/* ======================================================
   DUPLICATION
   ====================================================== */
function duplicateSelected() {
    var newIds = [];
    selection.forEach(function(id) {
        var n = state.nodes.find(function(x){ return x.id === id; });
        if (n) {
            var copy = copyObj(n);
            copy.id = uid();
            copy.x += 20; copy.y += 20;
            state.nodes.push(copy);
            newIds.push(copy.id);
        }
    });
    if (newIds.length) {
        selection = newIds;
        pushHistory(); render();
    }
}
(document.getElementById('diagDuplicateBtn')||{addEventListener:function(){}}).addEventListener('click', duplicateSelected);
(document.getElementById('diagSelectAll')||{addEventListener:function(){}}).addEventListener('click', selectAll);

/* ======================================================
   CONTEXT MENU
   ====================================================== */
var ctxTargetId = null;

function showCtxMenu(ev, id) {
    if (selection.indexOf(id) < 0) selection = [id];
    ctxTargetId = id;
    render();
    ctxMenu.style.left = ev.clientX + 'px';
    ctxMenu.style.top  = ev.clientY + 'px';
    ctxMenu.classList.add('open');
}

function closeCtxMenu() { ctxMenu.classList.remove('open'); ctxTargetId = null; }

(document.getElementById('ctx-edit')||{addEventListener:function(){}}).addEventListener('click',  function(){ closeCtxMenu(); if(ctxTargetId) startEditLabel(ctxTargetId, null, !!state.edges.find(function(e){return e.id===ctxTargetId})); });
(document.getElementById('ctx-dup')||{addEventListener:function(){}}).addEventListener('click',   function(){ closeCtxMenu(); duplicateSelected(); });
(document.getElementById('ctx-front')||{addEventListener:function(){}}).addEventListener('click', function(){ closeCtxMenu(); document.getElementById('diagBringFront').click(); });
(document.getElementById('ctx-back')||{addEventListener:function(){}}).addEventListener('click',  function(){ closeCtxMenu(); document.getElementById('diagSendBack').click(); });
(document.getElementById('ctx-props')||{addEventListener:function(){}}).addEventListener('click', function(){ closeCtxMenu(); propsBar.classList.add('visible'); });
(document.getElementById('ctx-del')||{addEventListener:function(){}}).addEventListener('click',   function(){ closeCtxMenu(); deleteSelected(); });

document.addEventListener('click', function(ev) {
    if (!ctxMenu.contains(ev.target)) closeCtxMenu();
});

/* ======================================================
   RACCOURCIS CLAVIER
   ====================================================== */
document.addEventListener('keydown', function(ev) {
    if (document.activeElement === labelInput) return;
    if (ev.target.tagName === 'INPUT' || ev.target.tagName === 'SELECT' || ev.target.tagName === 'TEXTAREA') return;

    var ctrl = ev.ctrlKey || ev.metaKey;
    switch(ev.key) {
        case 'Delete':
        case 'Backspace': if(!READONLY) deleteSelected(); break;
        case 'z': if(ctrl && !ev.shiftKey && !READONLY) { ev.preventDefault(); undo(); } break;
        case 'y': if(ctrl && !READONLY) { ev.preventDefault(); redo(); } break;
        case 'Z': if(ctrl && ev.shiftKey && !READONLY) { ev.preventDefault(); redo(); } break;
        case 'd': if(ctrl && !READONLY) { ev.preventDefault(); duplicateSelected(); } break;
        case 'a': if(ctrl) { ev.preventDefault(); selectAll(); } break;
        case 'f': case 'F': ev.preventDefault(); zoomFit(); break;
        case 'n': case 'N': if(ctrl && !READONLY) { ev.preventDefault(); diagNewBtn && diagNewBtn.click(); } break;
        case '+': case '=': state.zoom = clamp(state.zoom*1.25,MIN_ZOOM,MAX_ZOOM); applyTransform(); break;
        case '-': case '_': state.zoom = clamp(state.zoom/1.25,MIN_ZOOM,MAX_ZOOM); applyTransform(); break;
        case 'Escape': clearSelection(); setTool('select'); break;
        case 'r': case 'R': if(!READONLY && !ctrl) setTool('rect'); break;
        case 'e': case 'E': if(!READONLY && !ctrl) setTool('circle'); break;
        case 'D': if(!READONLY && !ctrl) setTool('diamond'); break;
        case 't': case 'T': if(!READONLY && !ctrl) setTool('text'); break;
        case 'c': case 'C': if(!READONLY && !ctrl) setTool('connect'); break;
        case 's': case 'S': if(!ctrl) setTool('select'); break;
        case 'h': case 'H': if(!ctrl) setTool('pan'); break;
        case 'g': case 'G': document.getElementById('diagToggleGrid').click(); break;
        // Fleches (deplacement fin)
        case 'ArrowLeft':
        case 'ArrowRight':
        case 'ArrowUp':
        case 'ArrowDown':
            if (!READONLY && selection.length) {
                ev.preventDefault();
                var d = ev.shiftKey ? 10 : 2;
                var dx2 = ev.key==='ArrowLeft'?-d:ev.key==='ArrowRight'?d:0;
                var dy2 = ev.key==='ArrowUp'?-d:ev.key==='ArrowDown'?d:0;
                selection.forEach(function(id){
                    var n = state.nodes.find(function(x){return x.id===id;});
                    if(n){n.x+=dx2;n.y+=dy2;}
                });
                render();
            }
            break;
    }
});

document.addEventListener('keyup', function(ev) {
    if ((ev.key === 'ArrowLeft'||ev.key==='ArrowRight'||ev.key==='ArrowUp'||ev.key==='ArrowDown') && selection.length && !READONLY) {
        pushHistory();
    }
});

/* ======================================================
   OUTILS (boutons)
   ====================================================== */
document.querySelectorAll('.diag-tool').forEach(function(btn) {
    btn.addEventListener('click', function() { setTool(btn.dataset.shape); });
});

/* ======================================================
   MINIMAP
   ====================================================== */
function updateMinimap() {
    var MM_W = 140, MM_H = 90;
    while (mmGrp.firstChild) mmGrp.removeChild(mmGrp.firstChild);

    if (state.nodes.length === 0) { mmVP.setAttribute('width', MM_W); mmVP.setAttribute('height', MM_H); return; }

    var xs = state.nodes.map(function(n){return n.x});
    var ys = state.nodes.map(function(n){return n.y});
    var xe = state.nodes.map(function(n){return n.x+n.w});
    var ye = state.nodes.map(function(n){return n.y+n.h});
    var minX=Math.min.apply(null,xs), minY=Math.min.apply(null,ys);
    var maxX=Math.max.apply(null,xe), maxY=Math.max.apply(null,ye);
    var pad = 5;
    var bw = maxX-minX+pad*2, bh = maxY-minY+pad*2;
    var sc = Math.min(MM_W/bw, MM_H/bh);
    var offX = -minX+pad, offY = -minY+pad;

    state.nodes.forEach(function(n) {
        var r = svgNS('rect');
        r.setAttribute('x',  (n.x+offX)*sc);
        r.setAttribute('y',  (n.y+offY)*sc);
        r.setAttribute('width',  n.w*sc);
        r.setAttribute('height', n.h*sc);
        r.setAttribute('rx', 2);
        r.setAttribute('fill',   n.fill   || '#e8f4fd');
        r.setAttribute('stroke', n.stroke || '#4a90d9');
        r.setAttribute('stroke-width', .5);
        mmGrp.appendChild(r);
    });

    // Viewport courant
    var vx = (-state.panX/state.zoom + offX) * sc;
    var vy = (-state.panY/state.zoom + offY) * sc;
    var vw = (canvasWrap.clientWidth  / state.zoom) * sc;
    var vh = (canvasWrap.clientHeight / state.zoom) * sc;
    mmVP.setAttribute('x', vx); mmVP.setAttribute('y', vy);
    mmVP.setAttribute('width',  Math.min(vw, MM_W));
    mmVP.setAttribute('height', Math.min(vh, MM_H));
}

// Click minimap = se deplacer
document.getElementById('diag-minimap').addEventListener('click', function(ev) {
    var rect = this.getBoundingClientRect();
    var px = (ev.clientX - rect.left) / rect.width;
    var py = (ev.clientY - rect.top)  / rect.height;
    if (state.nodes.length === 0) return;
    var xs = state.nodes.map(function(n){return n.x});
    var ys = state.nodes.map(function(n){return n.y});
    var xe = state.nodes.map(function(n){return n.x+n.w});
    var ye = state.nodes.map(function(n){return n.y+n.h});
    var minX=Math.min.apply(null,xs), minY=Math.min.apply(null,ys);
    var maxX=Math.max.apply(null,xe), maxY=Math.max.apply(null,ye);
    var targetX = minX + (maxX-minX)*px;
    var targetY = minY + (maxY-minY)*py;
    state.panX = canvasWrap.clientWidth/2  - targetX * state.zoom;
    state.panY = canvasWrap.clientHeight/2 - targetY * state.zoom;
    applyTransform(); updateMinimap();
});

/* ======================================================
   EXPORT / IMPORT
   ====================================================== */
document.getElementById('diagExportJSON').addEventListener('click', function() {
    var data = JSON.stringify({ nodes: state.nodes, edges: state.edges }, null, 2);
    var blob = new Blob([data], { type: 'application/json' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'diagram.json';
    a.click();
    URL.revokeObjectURL(a.href);
    toast('JSON exporte');
});

document.getElementById('diagExportSVG').addEventListener('click', function() {
    var clone = svgEl.cloneNode(true);
    clone.removeAttribute('class');
    // Embed styles
    var style = document.createElementNS('http://www.w3.org/2000/svg','style');
    style.textContent = 'text{font-family:Segoe UI,system-ui,sans-serif}';
    clone.insertBefore(style, clone.firstChild);
    // Remove UI elements
    var toRemove = ['diag-sel-rect','diag-conn-preview'];
    toRemove.forEach(function(id){ var el = clone.querySelector('#'+id); if(el) el.remove(); });
    clone.querySelectorAll('.sel-handle,.conn-port').forEach(function(el){el.remove();});

    var xs = state.nodes.map(function(n){return n.x});
    var ys = state.nodes.map(function(n){return n.y});
    var xe = state.nodes.map(function(n){return n.x+n.w});
    var ye = state.nodes.map(function(n){return n.y+n.h});
    if (xs.length) {
        var minX=Math.min.apply(null,xs)-20, minY=Math.min.apply(null,ys)-20;
        var maxX=Math.max.apply(null,xe)+20, maxY=Math.max.apply(null,ye)+20;
        clone.setAttribute('viewBox', minX+' '+minY+' '+(maxX-minX)+' '+(maxY-minY));
        clone.setAttribute('width',  maxX-minX);
        clone.setAttribute('height', maxY-minY);
        var grp = clone.querySelector('#diagramGroup');
        if(grp) grp.removeAttribute('transform');
    }
    var blob = new Blob(['<?xml version="1.0"?>' + new XMLSerializer().serializeToString(clone)], { type: 'image/svg+xml' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'diagram.svg';
    a.click();
    URL.revokeObjectURL(a.href);
    toast('SVG exporte');
});

document.getElementById('diagExportPNG').addEventListener('click', function() {
    if (state.nodes.length === 0) { toast('Aucun noeud a exporter'); return; }
    var xs = state.nodes.map(function(n){return n.x});
    var ys = state.nodes.map(function(n){return n.y});
    var xe = state.nodes.map(function(n){return n.x+n.w});
    var ye = state.nodes.map(function(n){return n.y+n.h});
    var minX=Math.min.apply(null,xs)-20, minY=Math.min.apply(null,ys)-20;
    var maxX=Math.max.apply(null,xe)+20, maxY=Math.max.apply(null,ye)+20;
    var W = maxX-minX, H = maxY-minY;
    var scale = 2;

    var clone = svgEl.cloneNode(true);
    clone.querySelectorAll('.sel-handle,.conn-port,#diag-sel-rect,#diag-conn-preview').forEach(function(el){el.remove();});
    clone.setAttribute('viewBox', minX+' '+minY+' '+W+' '+H);
    clone.setAttribute('width',  W*scale);
    clone.setAttribute('height', H*scale);
    var grp = clone.querySelector('#diagramGroup');
    if (grp) grp.removeAttribute('transform');
    var bg = document.createElementNS('http://www.w3.org/2000/svg','rect');
    bg.setAttribute('x',minX); bg.setAttribute('y',minY);
    bg.setAttribute('width',W); bg.setAttribute('height',H);
    bg.setAttribute('fill','#ffffff');
    clone.insertBefore(bg, clone.querySelector('#diagramGroup'));

    var svgStr = new XMLSerializer().serializeToString(clone);
    var img = new Image();
    img.onload = function() {
        var cv = document.createElement('canvas');
        cv.width = W*scale; cv.height = H*scale;
        var ctx = cv.getContext('2d');
        ctx.drawImage(img, 0, 0);
        var a = document.createElement('a');
        a.href = cv.toDataURL('image/png');
        a.download = 'diagram.png';
        a.click();
        toast('PNG exporte');
    };
    img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svgStr);
});

document.getElementById('diagImportBtn').addEventListener('click', function() {
    document.getElementById('diagImportFile').click();
});
document.getElementById('diagImportFile').addEventListener('change', function(ev) {
    var f = ev.target.files[0];
    if (!f) return;
    var rd = new FileReader();
    rd.onload = function(e) {
        try {
            var d = JSON.parse(e.target.result);
            if (d.nodes) state.nodes = d.nodes;
            if (d.edges) state.edges = d.edges;
            // Recalcul idSeq
            var maxId = 0;
            state.nodes.concat(state.edges).forEach(function(x){
                var n = parseInt(x.id.replace(/\D/g,''));
                if(!isNaN(n) && n > maxId) maxId = n;
            });
            idSeq = maxId + 1;
            selection = [];
            pushHistory();
            render();
            zoomFit();
            toast('Diagramme importe OK');
        } catch(err) {
            toast('Erreur import JSON');
        }
    };
    rd.readAsText(f);
    ev.target.value = '';
});

/* ======================================================
   COMMUNICATION WebSocket / FORMULAIRE (integration)
   ====================================================== */
var _emitDebounceTimer = null;
function emitChange() {
    // Envoie le contenu via le canal WebSocket d'editor.js
    clearTimeout(_emitDebounceTimer);
    _emitDebounceTimer = setTimeout(function () {
        if (typeof window.EDITOR_send === 'function') {
            window.EDITOR_send({
                type:    'content_update',
                content: window.EDITOR_getContent()
            });
        }
    }, 300);
}

// API publique pour editor.js
window.DiagramEditor = {
    getState:   function()    { return copyObj({ nodes: state.nodes, edges: state.edges }); },
    setState:   function(d)   {
        if (d && d.nodes) state.nodes = d.nodes;
        if (d && d.edges) state.edges = d.edges;
        selection = [];
        render();
        setTimeout(zoomFit, 50);
    },
    clearAll:   function()    { state.nodes = []; state.edges = []; selection = []; pushHistory(); render(); },
    addNodeAPI: function(type, x, y) { return addNode(type || 'rect', x || 200, y || 200); }
};

/* ======================================================
   TOUCH (tablette)
   ====================================================== */
var lastTouchDist = null;
svgEl.addEventListener('touchstart', function(ev) {
    if (ev.touches.length === 2) {
        lastTouchDist = Math.hypot(
            ev.touches[0].clientX - ev.touches[1].clientX,
            ev.touches[0].clientY - ev.touches[1].clientY
        );
    }
}, { passive: true });

svgEl.addEventListener('touchmove', function(ev) {
    if (ev.touches.length === 2 && lastTouchDist) {
        var dist = Math.hypot(
            ev.touches[0].clientX - ev.touches[1].clientX,
            ev.touches[0].clientY - ev.touches[1].clientY
        );
        var cx = (ev.touches[0].clientX + ev.touches[1].clientX)/2;
        var cy = (ev.touches[0].clientY + ev.touches[1].clientY)/2;
        var rect2 = svgEl.getBoundingClientRect();
        var mx = cx - rect2.left, my = cy - rect2.top;
        var delta = dist / lastTouchDist;
        var newZoom = clamp(state.zoom * delta, MIN_ZOOM, MAX_ZOOM);
        state.panX = mx - (mx - state.panX) * (newZoom / state.zoom);
        state.panY = my - (my - state.panY) * (newZoom / state.zoom);
        state.zoom = newZoom;
        lastTouchDist = dist;
        applyTransform();
        ev.preventDefault();
    }
}, { passive: false });

svgEl.addEventListener('touchend', function() { lastTouchDist = null; });

/* ======================================================
   INITIALISATION
   ====================================================== */
if (READONLY) {
    // Masquer les elements d'edition
    document.getElementById('diagPropsBar') && (document.getElementById('diagPropsBar').style.display = 'none');
}

wireProps();

/* -- Bouton Nouveau -- */
var diagNewBtn = document.getElementById('diagNewBtn');
if (diagNewBtn) {
    diagNewBtn.addEventListener('click', function () {
        if (state.nodes.length > 0 || state.edges.length > 0) {
            if (!confirm('Vider le diagramme ? Cette action est irreversible.')) return;
        }
        state.nodes = [];
        state.edges = [];
        selection   = [];
        _markerCache = {};
        // Nettoyer les markers dynamiques dans <defs>
        var defs = svgEl.querySelector('defs');
        if (defs) {
            Array.prototype.slice.call(defs.querySelectorAll('marker[id]')).forEach(function(m) {
                // Conserver les markers statiques du JSP (prefixe 'diag-')
                if (!m.id.startsWith('diag-')) defs.removeChild(m);
            });
        }
        pushHistory();
        render();
        toast('Nouveau diagramme');
    });
}

/* -- markerEnd openArrow start support -- */
var propMarkerStart = document.getElementById('propMarkerStart');
if (propMarkerStart) {
    // S'assurer que 'openArrow' est dans wireProps
    var existingOption = Array.prototype.some.call(propMarkerStart.options, function(o){ return o.value === 'openArrow'; });
    if (!existingOption) {
        var opt = document.createElement('option');
        opt.value = 'openArrow'; opt.textContent = 'Ouvert';
        propMarkerStart.insertBefore(opt, propMarkerStart.options[2]);
    }
}

pushHistory();
render();
setTimeout(zoomFit, 100);

/* ================================================================
   INTEGRATION editor.js (WebSocket + sauvegarde)
   Format : { nodes: [...], edges: [...] }
================================================================ */
window.EDITOR_getContent = function () {
    try {
        return JSON.stringify({ nodes: state.nodes, edges: state.edges });
    } catch (e) {
        return JSON.stringify({ nodes: [], edges: [] });
    }
};

window.EDITOR_setContent = function (jsonStr) {
    if (!jsonStr) return;
    try {
        var obj = JSON.parse(jsonStr);
        if (obj && (obj.nodes !== undefined || obj.edges !== undefined)) {
            state.nodes = obj.nodes || [];
            state.edges = obj.edges || [];
            selection = [];
            _markerCache = {};
            /* Recalcul idSeq pour eviter les collisions */
            var maxN = 0;
            state.nodes.concat(state.edges).forEach(function (x) {
                var n = parseInt(String(x.id).replace(/\D/g, ''), 10);
                if (!isNaN(n) && n > maxN) maxN = n;
            });
            idSeq = maxN + 1;
            pushHistory();
            render();
            setTimeout(zoomFit, 50);
        }
    } catch (e) { /* ignore */ }
};

})();
</script>
