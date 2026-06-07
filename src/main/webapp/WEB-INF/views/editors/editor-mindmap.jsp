<%-- Fragment éditeur MINDMAP — inclus par editor.jsp --%>
<%-- JS : /js/editor-mindmap.js (chargé par editor.jsp après editor.js) --%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<style>
/* ══════════════════════════════════════════════════════
   MINDMAP
══════════════════════════════════════════════════════ */
.mindmap-editor {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    position: relative;
    background: #1e1e2e;
    overflow: hidden;
}

/* ── Toolbar principale ── */
.mindmap-toolbar {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 6px 10px;
    background: #181825;
    border-bottom: 1px solid #313244;
    flex-shrink: 0;
    flex-wrap: wrap;
}
.mindmap-toolbar .hint {
    font-size: 11px;
    color: #6c7086;
    font-family: 'Segoe UI', system-ui, sans-serif;
    white-space: nowrap;
}
.mm-btn {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    height: 26px;
    padding: 0 10px;
    background: #313244;
    border: 1px solid #45475a;
    border-radius: 4px;
    color: #cdd6f4;
    font-size: 12px;
    font-family: 'Segoe UI', system-ui, sans-serif;
    cursor: pointer;
    white-space: nowrap;
    transition: background .12s, border-color .12s;
}
.mm-btn:hover        { background: #45475a; border-color: #89b4fa; }
.mm-btn.mm-danger    { border-color: #f38ba8; color: #f38ba8; }
.mm-btn.mm-danger:hover { background: #f38ba8; color: #1e1e2e; }
.mm-btn.mm-primary   { border-color: #89b4fa; color: #89b4fa; }
.mm-btn.mm-primary:hover { background: #89b4fa; color: #1e1e2e; }

/* ── SVG ── */
.mindmap-svg {
    flex: 1;
    min-height: 0;
    display: block;
    cursor: default;
    user-select: none;
}
.mindmap-svg .mm-node {
    cursor: grab;
}
.mindmap-svg .mm-node:active {
    cursor: grabbing;
}

/* ── Panneau propriétés (droite) ── */
#mmPropsPanel {
    position: absolute;
    top: 46px;
    right: 0;
    width: 220px;
    background: #181825;
    border-left: 1px solid #313244;
    border-bottom: 1px solid #313244;
    border-radius: 0 0 0 6px;
    padding: 12px;
    display: none;
    flex-direction: column;
    gap: 10px;
    z-index: 10;
    box-shadow: -4px 4px 12px rgba(0,0,0,.4);
    font-family: 'Segoe UI', system-ui, sans-serif;
}
#mmPropsPanel.visible { display: flex; }

#mmPropsPanel .prop-title {
    font-size: 11px;
    color: #6c7086;
    text-transform: uppercase;
    letter-spacing: .05em;
    margin-bottom: 2px;
}
#mmPropsPanel .prop-row {
    display: flex;
    flex-direction: column;
    gap: 4px;
}
#mmPropsPanel label {
    font-size: 11px;
    color: #a6adc8;
}
#mmPropsPanel input[type="text"] {
    width: 100%;
    padding: 4px 7px;
    background: #313244;
    border: 1px solid #45475a;
    border-radius: 3px;
    color: #cdd6f4;
    font-size: 12px;
    outline: none;
    box-sizing: border-box;
}
#mmPropsPanel input[type="text"]:focus { border-color: #89b4fa; }

#mmPropsPanel input[type="range"] {
    width: 100%;
    accent-color: #89b4fa;
}
#mmPropsPanel .range-row {
    display: flex;
    align-items: center;
    gap: 6px;
}
#mmPropsPanel .range-row input[type="range"] { flex: 1; }
#mmPropsPanel .range-val {
    font-size: 11px;
    color: #cdd6f4;
    min-width: 26px;
    text-align: right;
}

#mmPropsPanel .color-row {
    display: flex;
    align-items: center;
    gap: 8px;
}
#mmPropsPanel input[type="color"] {
    width: 32px;
    height: 24px;
    border: 1px solid #45475a;
    border-radius: 3px;
    background: none;
    cursor: pointer;
    padding: 1px;
}
#mmPropsPanel .color-label {
    font-size: 11px;
    color: #a6adc8;
    flex: 1;
}

#mmPropsPanel .prop-sep {
    border: none;
    border-top: 1px solid #313244;
    margin: 2px 0;
}

/* Input flottant (rename rapide dbl-clic) */
.mm-node-input {
    position: absolute;
    z-index: 20;
    background: #313244;
    border: 1px solid #89b4fa;
    border-radius: 4px;
    color: #cdd6f4;
    font-size: 13px;
    padding: 3px 7px;
    outline: none;
    box-shadow: 0 2px 8px rgba(0,0,0,.5);
}
</style>

<div class="mindmap-editor" id="mindmapEditor">

    <%-- Toolbar principale --%>
    <div class="mindmap-toolbar">
        <span class="hint">
            <c:choose>
                <c:when test="${canEdit}">
                    Dbl-clic fond = nœud &nbsp;·&nbsp;
                    Dbl-clic nœud = renommer &nbsp;·&nbsp;
                    Clic = sélectionner &nbsp;·&nbsp;
                    Glisser = déplacer
                </c:when>
                <c:otherwise>Mode lecture seule</c:otherwise>
            </c:choose>
        </span>

        <c:if test="${canEdit}">
            <button id="mmAddRootBtn"  class="mm-btn mm-primary" title="Ajouter un nœud racine au centre">
                + Nœud
            </button>
            <button id="mmAddChildBtn" class="mm-btn" title="Ajouter un nœud enfant au nœud sélectionné">
                + Enfant
            </button>
            <button id="mmDeleteBtn"   class="mm-btn mm-danger" title="Supprimer le nœud sélectionné (et ses enfants)">
                Supprimer
            </button>
        </c:if>

        <button id="mmZoomFit"  class="mm-btn" title="Centrer et ajuster la vue">
            ⊡ Ajuster
        </button>
        <button id="mmZoomIn"   class="mm-btn" title="Zoomer">+</button>
        <button id="mmZoomOut"    class="mm-btn" title="Dézoomer">−</button>
        <button id="mmExportSvgBtn" class="mm-btn" title="Télécharger la carte en SVG">
            &#8595; SVG
        </button>
    </div>

    <%-- SVG principal --%>
    <svg id="mindmapSvg" class="mindmap-svg">
        <defs>
            <marker id="mmArrow" markerWidth="8" markerHeight="8"
                    refX="6" refY="3" orient="auto">
                <path d="M0,0 L0,6 L8,3 z" fill="#89b4fa" opacity=".7"/>
            </marker>
        </defs>
        <g id="mindmapGroup"></g>
    </svg>

    <%-- Panneau propriétés (affiché quand un nœud est sélectionné) --%>
    <c:if test="${canEdit}">
    <div id="mmPropsPanel">
        <div class="prop-title">Propriétés du nœud</div>

        <div class="prop-row">
            <label for="mmPropLabel">Nom</label>
            <input type="text" id="mmPropLabel" maxlength="80" placeholder="Nom du nœud">
        </div>

        <hr class="prop-sep">

        <div class="prop-row">
            <label>Taille</label>
            <div class="range-row">
                <input type="range" id="mmPropSize" min="20" max="100" step="5" value="40">
                <span class="range-val" id="mmPropSizeVal">40</span>
            </div>
        </div>

        <hr class="prop-sep">

        <div class="prop-row">
            <label>Couleur du nœud</label>
            <div class="color-row">
                <input type="color" id="mmPropFill" value="#313244">
                <span class="color-label" id="mmPropFillLbl">#313244</span>
            </div>
        </div>

        <div class="prop-row">
            <label>Couleur du texte</label>
            <div class="color-row">
                <input type="color" id="mmPropText" value="#cdd6f4">
                <span class="color-label" id="mmPropTextLbl">#cdd6f4</span>
            </div>
        </div>

        <div class="prop-row">
            <label>Couleur de la bordure</label>
            <div class="color-row">
                <input type="color" id="mmPropStroke" value="#45475a">
                <span class="color-label" id="mmPropStrokeLbl">#45475a</span>
            </div>
        </div>
    </div>
    </c:if>

    <%-- Input flottant renommage rapide --%>
    <input type="text" id="mmNodeInput" class="mm-node-input"
           style="display:none;" maxlength="80">

</div>

<script>
var MINDMAP_READONLY = ${!canEdit};
</script>
