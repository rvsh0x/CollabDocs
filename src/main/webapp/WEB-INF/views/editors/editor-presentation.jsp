<%-- Fragment éditeur PRESENTATION — inclus par editor.jsp --%>
<%-- JS : /js/editor-presentation.js (chargé par editor.jsp après editor.js) --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<style>
/* ═══════════════════════════════════════════════════════════════
   PRESENTATION EDITOR — Design System
   Palette : ardoise foncé + blanc cassé + accent cobalt
═══════════════════════════════════════════════════════════════ */
:root {
  --pe-bg:          #1a1d23;
  --pe-surface:     #22262f;
  --pe-panel:       #1e222b;
  --pe-border:      #2e3340;
  --pe-accent:      #4f7ef8;
  --pe-accent-h:    #3a66e0;
  --pe-danger:      #e05252;
  --pe-success:     #3ecf8e;
  --pe-text:        #d6dae8;
  --pe-text-muted:  #6b7280;
  --pe-slide-ratio: 56.25%; /* 16:9 */
  --pe-thumb-w:     160px;
  --pe-panel-w:     200px;
  --pe-prop-w:      260px;
  --pe-toolbar-h:   48px;
  --pe-radius:      6px;
  --pe-font-ui:     'Segoe UI', system-ui, sans-serif;
  --pe-shadow:      0 4px 24px rgba(0,0,0,.45);
}

/* ── Layout principal ── */
.presentation-editor {
  display: flex;
  height: calc(100vh - 60px);
  background: var(--pe-bg);
  font-family: var(--pe-font-ui);
  color: var(--pe-text);
  overflow: hidden;
}

/* ── Panneau slides (gauche) ── */
.pe-slides-panel {
  width: var(--pe-panel-w);
  min-width: var(--pe-panel-w);
  background: var(--pe-panel);
  border-right: 1px solid var(--pe-border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.pe-slides-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border-bottom: 1px solid var(--pe-border);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .08em;
  text-transform: uppercase;
  color: var(--pe-text-muted);
}
.pe-slides-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 6px;
  scrollbar-width: thin;
  scrollbar-color: var(--pe-border) transparent;
}
.pe-slide-thumb {
  position: relative;
  width: 100%;
  margin-bottom: 8px;
  border-radius: var(--pe-radius);
  border: 2px solid transparent;
  cursor: pointer;
  transition: border-color .15s, box-shadow .15s;
  background: #fff;
  overflow: hidden;
  user-select: none;
}
.pe-slide-thumb:hover  { border-color: var(--pe-accent); }
.pe-slide-thumb.active { border-color: var(--pe-accent); box-shadow: 0 0 0 3px rgba(79,126,248,.25); }
.pe-slide-thumb-inner {
  width: 100%;
  padding-top: var(--pe-slide-ratio);
  position: relative;
  pointer-events: none;
}
.pe-slide-thumb-canvas {
  position: absolute;
  inset: 0;
  overflow: hidden;
  font-size: 3.5px;
  line-height: 1.3;
}
.pe-slide-thumb-num {
  position: absolute;
  bottom: 2px;
  right: 4px;
  font-size: 9px;
  color: var(--pe-text-muted);
  background: rgba(0,0,0,.35);
  padding: 1px 4px;
  border-radius: 3px;
  pointer-events: none;
}
.pe-slide-thumb-drag-over { border-color: var(--pe-success) !important; }

/* ── Zone centrale ── */
.pe-editor-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: var(--pe-bg);
}

/* ── Toolbar centrale ── */
.pe-toolbar {
  height: var(--pe-toolbar-h);
  min-height: var(--pe-toolbar-h);
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 12px;
  background: var(--pe-surface);
  border-bottom: 1px solid var(--pe-border);
  flex-wrap: nowrap;
  overflow-x: auto;
}
.pe-toolbar-sep {
  width: 1px;
  height: 22px;
  background: var(--pe-border);
  margin: 0 4px;
  flex-shrink: 0;
}
.pe-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 0 10px;
  height: 30px;
  border: 1px solid var(--pe-border);
  border-radius: var(--pe-radius);
  background: var(--pe-surface);
  color: var(--pe-text);
  font-size: 12px;
  font-family: var(--pe-font-ui);
  cursor: pointer;
  white-space: nowrap;
  transition: background .12s, border-color .12s;
  flex-shrink: 0;
}
.pe-btn:hover  { background: #2c3245; border-color: var(--pe-accent); }
.pe-btn.active { background: var(--pe-accent); border-color: var(--pe-accent); color: #fff; }
.pe-btn.danger { border-color: var(--pe-danger); color: var(--pe-danger); }
.pe-btn.danger:hover { background: var(--pe-danger); color: #fff; }
.pe-btn.primary { background: var(--pe-accent); border-color: var(--pe-accent); color: #fff; }
.pe-btn.primary:hover { background: var(--pe-accent-h); }
.pe-btn:disabled { opacity: .4; cursor: not-allowed; }

.pe-select {
  height: 30px;
  padding: 0 6px;
  border: 1px solid var(--pe-border);
  border-radius: var(--pe-radius);
  background: var(--pe-surface);
  color: var(--pe-text);
  font-size: 12px;
  font-family: var(--pe-font-ui);
  cursor: pointer;
}
.pe-select:focus { outline: none; border-color: var(--pe-accent); }

.pe-input-sm {
  height: 30px;
  padding: 0 8px;
  border: 1px solid var(--pe-border);
  border-radius: var(--pe-radius);
  background: var(--pe-surface);
  color: var(--pe-text);
  font-size: 12px;
  font-family: var(--pe-font-ui);
}
.pe-input-sm:focus { outline: none; border-color: var(--pe-accent); }

.pe-color-btn {
  width: 30px;
  height: 30px;
  padding: 3px;
  border: 1px solid var(--pe-border);
  border-radius: var(--pe-radius);
  background: var(--pe-surface);
  cursor: pointer;
  flex-shrink: 0;
}
.pe-color-btn input[type=color] {
  width: 100%;
  height: 100%;
  border: none;
  padding: 0;
  background: transparent;
  cursor: pointer;
  border-radius: 3px;
}

/* ── Canvas zone ── */
.pe-canvas-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: auto;
  background: #13151a;
  background-image: radial-gradient(circle at 1px 1px, #2a2d36 1px, transparent 0);
  background-size: 20px 20px;
  position: relative;
}

.pe-slide-canvas {
  position: relative;
  background: #ffffff;
  box-shadow: var(--pe-shadow);
  overflow: hidden;
  transform-origin: top left;
  /* taille pilotée par JS */
}

/* Éléments sur le canvas */
.pe-element {
  position: absolute;
  box-sizing: border-box;
  cursor: default;
  user-select: none;
}
.pe-element.selected {
  outline: 2px solid var(--pe-accent);
  outline-offset: 1px;
}
.pe-element.text-el  { cursor: text; }
.pe-element.image-el { cursor: default; }
.pe-element.shape-el { cursor: default; }

/* Poignées de redimensionnement */
.pe-handle {
  position: absolute;
  width: 9px;
  height: 9px;
  background: #fff;
  border: 2px solid var(--pe-accent);
  border-radius: 2px;
  z-index: 10;
  box-sizing: border-box;
}
.pe-handle.nw { top:-5px; left:-5px; cursor:nw-resize; }
.pe-handle.ne { top:-5px; right:-5px; cursor:ne-resize; }
.pe-handle.sw { bottom:-5px; left:-5px; cursor:sw-resize; }
.pe-handle.se { bottom:-5px; right:-5px; cursor:se-resize; }
.pe-handle.n  { top:-5px; left:50%; transform:translateX(-50%); cursor:n-resize; }
.pe-handle.s  { bottom:-5px; left:50%; transform:translateX(-50%); cursor:s-resize; }
.pe-handle.w  { top:50%; left:-5px; transform:translateY(-50%); cursor:w-resize; }
.pe-handle.e  { top:50%; right:-5px; transform:translateY(-50%); cursor:e-resize; }

/* Éditeur de texte inline */
.pe-text-edit {
  width: 100%;
  height: 100%;
  border: none;
  outline: none;
  background: transparent;
  resize: none;
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  color: inherit;
  text-align: inherit;
  line-height: inherit;
  padding: 4px;
  box-sizing: border-box;
  overflow: hidden;
}

/* Drop overlay */
.pe-drop-overlay {
  position: absolute;
  inset: 0;
  background: rgba(79,126,248,.18);
  border: 3px dashed var(--pe-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  font-weight: 700;
  color: var(--pe-accent);
  pointer-events: none;
  opacity: 0;
  transition: opacity .15s;
  z-index: 100;
  border-radius: var(--pe-radius);
}
.pe-drop-overlay.visible { opacity: 1; }

/* ── Panneau propriétés (droite) ── */
.pe-props-panel {
  width: var(--pe-prop-w);
  min-width: var(--pe-prop-w);
  background: var(--pe-panel);
  border-left: 1px solid var(--pe-border);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: var(--pe-border) transparent;
}
.pe-props-section {
  padding: 12px;
  border-bottom: 1px solid var(--pe-border);
}
.pe-props-title {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: .1em;
  text-transform: uppercase;
  color: var(--pe-text-muted);
  margin-bottom: 10px;
}
.pe-prop-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  gap: 6px;
}
.pe-prop-label {
  font-size: 11px;
  color: var(--pe-text-muted);
  white-space: nowrap;
}
.pe-prop-input {
  height: 26px;
  padding: 0 6px;
  border: 1px solid var(--pe-border);
  border-radius: 4px;
  background: var(--pe-bg);
  color: var(--pe-text);
  font-size: 12px;
  font-family: var(--pe-font-ui);
  width: 100px;
  text-align: right;
}
.pe-prop-input:focus { outline: none; border-color: var(--pe-accent); }
.pe-prop-color {
  width: 30px;
  height: 26px;
  border: 1px solid var(--pe-border);
  border-radius: 4px;
  padding: 2px;
  background: var(--pe-bg);
  cursor: pointer;
}
.pe-prop-select {
  height: 26px;
  padding: 0 4px;
  border: 1px solid var(--pe-border);
  border-radius: 4px;
  background: var(--pe-bg);
  color: var(--pe-text);
  font-size: 11px;
  width: 110px;
}
.pe-prop-select:focus { outline: none; border-color: var(--pe-accent); }
.pe-btn-full {
  display: block;
  width: 100%;
  padding: 7px;
  border: 1px solid var(--pe-border);
  border-radius: var(--pe-radius);
  background: var(--pe-surface);
  color: var(--pe-text);
  font-size: 12px;
  text-align: center;
  cursor: pointer;
  margin-top: 4px;
  transition: background .12s, border-color .12s;
}
.pe-btn-full:hover { background: #2c3245; border-color: var(--pe-accent); }
.pe-btn-full.danger { color: var(--pe-danger); border-color: var(--pe-danger); }
.pe-btn-full.danger:hover { background: var(--pe-danger); color: #fff; }

/* ── Présentation plein écran ── */
.pe-fullscreen {
  position: fixed;
  inset: 0;
  background: #000;
  z-index: 9999;
  display: none;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.pe-fullscreen.active { display: flex; }
.pe-fullscreen-slide {
  position: relative;
  background: #fff;
  overflow: hidden;
  max-width: 95vw;
  max-height: 87vh;
  width: 95vw;
  /* ratio 16:9 géré en JS */
}
.pe-fullscreen-controls {
  position: fixed;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 10px;
  background: rgba(0,0,0,.65);
  padding: 8px 20px;
  border-radius: 40px;
  backdrop-filter: blur(8px);
}
.pe-fullscreen-controls .pe-btn { height: 32px; }
.pe-slide-counter { font-size: 13px; color: #fff; min-width: 60px; text-align: center; }

/* ── Notifications ── */
.pe-toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 99999;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.pe-toast {
  padding: 10px 18px;
  border-radius: var(--pe-radius);
  font-size: 13px;
  background: var(--pe-surface);
  border: 1px solid var(--pe-border);
  color: var(--pe-text);
  box-shadow: var(--pe-shadow);
  animation: peToastIn .2s ease;
}
.pe-toast.success { border-color: var(--pe-success); color: var(--pe-success); }
.pe-toast.error   { border-color: var(--pe-danger);  color: var(--pe-danger); }
@keyframes peToastIn { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:none; } }

/* ── Indicateur collaboratif ── */
.pe-collab-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  display: inline-block;
  margin-right: 4px;
}
.pe-collab-user {
  display: flex;
  align-items: center;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 12px;
  background: rgba(79,126,248,.15);
  border: 1px solid rgba(79,126,248,.3);
  margin-left: 4px;
}

/* ── Règle/grille overlay ── */
.pe-grid-overlay {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

/* Barre d'état slide title */
.pe-slide-title-bar {
  display: flex;
  align-items: center;
  padding: 0 12px;
  height: 38px;
  border-bottom: 1px solid var(--pe-border);
  background: var(--pe-surface);
  gap: 8px;
}
.pe-slide-title-input {
  flex: 1;
  height: 26px;
  padding: 0 8px;
  border: 1px solid transparent;
  border-radius: 4px;
  background: transparent;
  color: var(--pe-text);
  font-size: 13px;
  font-family: var(--pe-font-ui);
  font-weight: 600;
}
.pe-slide-title-input:hover  { border-color: var(--pe-border); background: var(--pe-bg); }
.pe-slide-title-input:focus  { outline: none; border-color: var(--pe-accent); background: var(--pe-bg); }

/* Sélection multiple rubber-band */
.pe-rubberband {
  position: absolute;
  border: 1px solid var(--pe-accent);
  background: rgba(79,126,248,.12);
  pointer-events: none;
  z-index: 50;
}

/* Responsive */
@media (max-width: 900px) {
  .pe-props-panel { display: none; }
}
@media (max-width: 600px) {
  .pe-slides-panel { width: 120px; min-width: 120px; }
}
</style>

<%-- ══════════════════════════════════════════════════
     HTML STRUCTURE
══════════════════════════════════════════════════ --%>
<div class="presentation-editor" id="peRoot">

  <%-- Panneau gauche : liste des slides --%>
  <div class="pe-slides-panel" id="peSlidesPanel">
    <div class="pe-slides-header">
      <span>Slides</span>
      <c:if test="${canEdit}">
        <button class="pe-btn primary" id="peAddSlideBtn" style="padding:0 8px;height:22px;font-size:14px;" title="Ajouter une slide">+</button>
      </c:if>
    </div>
    <div class="pe-slides-list" id="peSlidesList"></div>
  </div>

  <%-- Zone centrale --%>
  <div class="pe-editor-main" id="peEditorMain">

    <%-- Toolbar formatage --%>
    <div class="pe-toolbar" id="peToolbar">
      <%-- Insertion --%>
      <c:if test="${canEdit}">
        <button class="pe-btn" id="peAddTextBtn"  title="Ajouter une zone de texte">T</button>
        <button class="pe-btn" id="peAddImageBtn" title="Insérer une image">Img</button>
        <button class="pe-btn" id="peAddRectBtn"  title="Rectangle">Rect</button>
        <button class="pe-btn" id="peAddLineBtn"  title="Ligne horizontale">Ligne</button>
        <div class="pe-toolbar-sep"></div>
      </c:if>

      <%-- Typo --%>
      <select class="pe-select" id="peFontFamily" style="width:120px;" title="Police">
        <option value="Arial">Arial</option>
        <option value="Georgia">Georgia</option>
        <option value="Trebuchet MS">Trebuchet MS</option>
        <option value="Verdana">Verdana</option>
        <option value="Courier New">Courier New</option>
        <option value="Impact">Impact</option>
        <option value="Palatino Linotype">Palatino</option>
        <option value="Tahoma">Tahoma</option>
        <option value="Times New Roman">Times New Roman</option>
      </select>
      <select class="pe-select" id="peFontSize" style="width:58px;" title="Taille">
        <option>10</option><option>12</option><option>14</option>
        <option>16</option><option>18</option><option>20</option>
        <option>24</option><option>28</option><option>32</option>
        <option>36</option><option>40</option><option>48</option>
        <option>56</option><option>64</option><option>72</option>
        <option>80</option><option>96</option>
      </select>
      <div class="pe-toolbar-sep"></div>
      <button class="pe-btn" id="peBold"   title="Gras"      style="font-weight:700;">G</button>
      <button class="pe-btn" id="peItalic" title="Italique"  style="font-style:italic;">I</button>
      <button class="pe-btn" id="peUnder"  title="Souligné"  style="text-decoration:underline;">S</button>
      <div class="pe-toolbar-sep"></div>
      <button class="pe-btn" id="peAlignL" title="Gauche">&#8676;</button>
      <button class="pe-btn" id="peAlignC" title="Centrer">&#8801;</button>
      <button class="pe-btn" id="peAlignR" title="Droite">&#8677;</button>
      <div class="pe-toolbar-sep"></div>
      <div class="pe-color-btn" title="Couleur texte">
        <input type="color" id="peTextColor" value="#000000">
      </div>
      <div class="pe-color-btn" title="Couleur remplissage">
        <input type="color" id="peFillColor" value="#ffffff">
      </div>
      <div class="pe-toolbar-sep"></div>
      <button class="pe-btn" id="peZUp"   title="Avancer">Z+</button>
      <button class="pe-btn" id="peZDown" title="Reculer">Z-</button>
      <div class="pe-toolbar-sep"></div>
      <button class="pe-btn" id="pePdfBtn" title="Télécharger PDF">PDF</button>
      <button class="pe-btn primary" id="pePresentBtn" title="Mode présentation">Présenter</button>
    </div>

    <%-- Barre titre slide --%>
    <div class="pe-slide-title-bar" id="peSlideTitleBar">
      <input type="text" class="pe-slide-title-input" id="peSlideTitleInput"
             placeholder="Titre de la slide..."
             <c:if test="${!canEdit}">readonly</c:if>>
      <div class="pe-color-btn" title="Couleur de fond de la slide">
        <input type="color" id="peSlideBgColor" value="#ffffff">
      </div>
      <%-- Indicateurs collaborateurs --%>
      <span id="peCollabIndicator" style="display:flex;gap:4px;margin-left:8px;"></span>
    </div>

    <%-- Canvas de la slide --%>
    <div class="pe-canvas-area" id="peCanvasArea">
      <div class="pe-slide-canvas" id="peSlideCanvas">
        <canvas class="pe-grid-overlay" id="peGridCanvas"></canvas>
        <div class="pe-drop-overlay" id="peDropOverlay">Déposer une image ici</div>
        <%-- éléments injectés par JS --%>
      </div>
    </div>
  </div>

  <%-- Panneau propriétés (droite) --%>
  <div class="pe-props-panel" id="pePropsPanel">

    <div class="pe-props-section" id="peSlideProps">
      <div class="pe-props-title">Slide</div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Fond</span>
        <input type="color" class="pe-prop-color" id="pePropSlideBg" value="#ffffff">
      </div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Format</span>
        <select class="pe-prop-select" id="pePropFormat">
          <option value="16:9">16:9</option>
          <option value="4:3">4:3</option>
          <option value="A4">A4</option>
        </select>
      </div>
      <c:if test="${canEdit}">
        <button class="pe-btn-full danger" id="pePropDeleteSlide">Supprimer la slide</button>
        <button class="pe-btn-full" id="pePropDupSlide">Dupliquer la slide</button>
      </c:if>
    </div>

    <div class="pe-props-section" id="peElemProps" style="display:none;">
      <div class="pe-props-title">Element</div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">X</span>
        <input type="number" class="pe-prop-input" id="pePropX" min="0">
      </div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Y</span>
        <input type="number" class="pe-prop-input" id="pePropY" min="0">
      </div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Largeur</span>
        <input type="number" class="pe-prop-input" id="pePropW" min="10">
      </div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Hauteur</span>
        <input type="number" class="pe-prop-input" id="pePropH" min="10">
      </div>
      <div class="pe-prop-row">
        <span class="pe-prop-label">Opacité</span>
        <input type="number" class="pe-prop-input" id="pePropOpacity" min="0" max="100" value="100">
      </div>
      <div class="pe-prop-row" id="pePropBorderRow">
        <span class="pe-prop-label">Bordure</span>
        <input type="number" class="pe-prop-input" id="pePropBorder" min="0" max="20" value="0" style="width:50px;">
        <input type="color" class="pe-prop-color" id="pePropBorderColor" value="#000000" style="width:36px;">
      </div>
      <div class="pe-prop-row" id="pePropRadiusRow">
        <span class="pe-prop-label">Rayon</span>
        <input type="number" class="pe-prop-input" id="pePropRadius" min="0" max="200" value="0">
      </div>
      <c:if test="${canEdit}">
        <button class="pe-btn-full danger" id="pePropDeleteElem">Supprimer l'élément</button>
      </c:if>
    </div>

  </div>
</div>

<%-- Présentation plein écran --%>
<div class="pe-fullscreen" id="peFullscreen">
  <div class="pe-fullscreen-slide" id="peFullscreenSlide"></div>
  <div class="pe-fullscreen-controls">
    <button class="pe-btn" id="pePrevSlide">Précédent</button>
    <span class="pe-slide-counter" id="peSlideCounter">1 / 1</span>
    <button class="pe-btn" id="peNextSlide">Suivant</button>
    <button class="pe-btn danger" id="peExitPresent">Quitter</button>
  </div>
</div>

<%-- Input fichier image caché --%>
<input type="file" id="peImageFileInput" accept="image/*" style="display:none;" multiple>

<%-- Toast container --%>
<div class="pe-toast-container" id="peToastContainer"></div>

<script>
/* ════════════════════════════════════════════════════════════════
   PRESENTATION EDITOR — Core Engine
   Fonctionnalités :
   - Canvas vectoriel (éléments texte, image, forme)
   - Drag, resize, z-order, multi-select
   - Historique undo/redo
   - Collaboration WebSocket (delta sync)
   - Export PDF via canvas (sans dépendance externe)
   - Import image drag&drop / sélecteur fichier
   - Miniatures slides en temps réel
════════════════════════════════════════════════════════════════ */
(function() {
'use strict';

/* ── Config globale ── */
var READONLY   = ${!canEdit};
var SLIDE_W    = 960;   // px de référence (16:9)
var SLIDE_H    = 540;
var GRID_SIZE  = 10;
var SNAP_ENABLED = true;
var AUTO_SAVE_DELAY = 1500; // ms

/* ══════════════════
   STATE
══════════════════ */
var state = {
  slides: [],          // [{id, title, bg, elements:[...]}]
  currentSlide: 0,
  selectedIds: [],     // ids d'éléments sélectionnés
  zoom: 1,
  format: '16:9',
  history: [],         // pour undo
  historyPos: -1,
  collab: {            // utilisateurs connectés
    users: {},         // id -> {name, color, slide}
  },
  dirty: false,
};

/* ══════════════════
   UTILITAIRES
══════════════════ */
function uid() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}
function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }
function snap(v) { return SNAP_ENABLED ? Math.round(v / GRID_SIZE) * GRID_SIZE : v; }

function deepClone(obj) { return JSON.parse(JSON.stringify(obj)); }

function toast(msg, type) {
  var c = document.getElementById('peToastContainer');
  var d = document.createElement('div');
  d.className = 'pe-toast' + (type ? ' ' + type : '');
  d.textContent = msg;
  c.appendChild(d);
  setTimeout(function() { if(d.parentNode) d.parentNode.removeChild(d); }, 3000);
}

/* ══════════════════
   SLIDE FACTORY
══════════════════ */
function makeSlide(title) {
  return {
    id: uid(),
    title: title || 'Nouvelle slide',
    bg: '#ffffff',
    elements: []
  };
}

function makeElement(type, extra) {
  var base = {
    id: uid(),
    type: type,        // 'text' | 'image' | 'rect' | 'line'
    x: 80,  y: 80,
    w: 300, h: 60,
    z: 1,
    opacity: 1,
    borderW: 0,
    borderColor: '#000000',
    radius: 0,
  };
  if (type === 'text') {
    base.text      = 'Double-cliquez pour éditer';
    base.fontSize  = 20;
    base.fontFamily= 'Arial';
    base.bold      = false;
    base.italic    = false;
    base.underline = false;
    base.color     = '#000000';
    base.align     = 'left';
    base.fill      = 'transparent';
    base.h         = 60;
  }
  if (type === 'image') {
    base.src = '';
    base.w   = 320;
    base.h   = 200;
    base.fill= 'transparent';
  }
  if (type === 'rect') {
    base.fill  = '#e2e8f0';
    base.w     = 200;
    base.h     = 120;
  }
  if (type === 'line') {
    base.fill  = '#334155';
    base.w     = 400;
    base.h     = 4;
    base.radius= 0;
  }
  return Object.assign(base, extra || {});
}

/* ══════════════════
   DOM REFS
══════════════════ */
var $ = function(id){ return document.getElementById(id); };

var peSlidesList     = $('peSlidesList');
var peSlideCanvas    = $('peSlideCanvas');
var peCanvasArea     = $('peCanvasArea');
var peSlideTitleInput= $('peSlideTitleInput');
var peSlideBgColor   = $('peSlideBgColor');
var pePropSlideBg    = $('pePropSlideBg');
var pePropFormat     = $('pePropFormat');
var peDropOverlay    = $('peDropOverlay');
var peFullscreen     = $('peFullscreen');
var peFullscreenSlide= $('peFullscreenSlide');
var peSlideCounter   = $('peSlideCounter');
var pePropsPanel     = $('pePropsPanel');
var peElemProps      = $('peElemProps');
var peSlideProps     = $('peSlideProps');
var peCollabIndicator= $('peCollabIndicator');
var peImageFileInput = $('peImageFileInput');
var peGridCanvas     = $('peGridCanvas');

/* ══════════════════
   HISTORIQUE UNDO/REDO
══════════════════ */
function pushHistory() {
  var snap = deepClone(state.slides);
  if (state.historyPos < state.history.length - 1) {
    state.history = state.history.slice(0, state.historyPos + 1);
  }
  state.history.push(snap);
  if (state.history.length > 80) state.history.shift();
  state.historyPos = state.history.length - 1;
}

function undo() {
  if (state.historyPos <= 0) return;
  state.historyPos--;
  state.slides = deepClone(state.history[state.historyPos]);
  state.selectedIds = [];
  renderAll();
  toast('Annulé', '');
}
function redo() {
  if (state.historyPos >= state.history.length - 1) return;
  state.historyPos++;
  state.slides = deepClone(state.history[state.historyPos]);
  state.selectedIds = [];
  renderAll();
  toast('Refait', '');
}

/* ══════════════════
   ZOOM & CANVAS SIZE
══════════════════ */
function computeZoom() {
  var area = peCanvasArea;
  var aw = area.clientWidth  - 48;
  var ah = area.clientHeight - 48;
  var rw = aw / SLIDE_W;
  var rh = ah / SLIDE_H;
  state.zoom = Math.min(rw, rh, 1.5);
}

function applyZoom() {
  computeZoom();
  var z = state.zoom;
  peSlideCanvas.style.width  = (SLIDE_W * z) + 'px';
  peSlideCanvas.style.height = (SLIDE_H * z) + 'px';
  peSlideCanvas.style.transform = 'none';
  // Grid canvas
  peGridCanvas.width  = SLIDE_W * z;
  peGridCanvas.height = SLIDE_H * z;
  drawGrid();
}

function drawGrid() {
  if (!peGridCanvas) return;
  var ctx = peGridCanvas.getContext('2d');
  var z   = state.zoom;
  var w   = peGridCanvas.width;
  var h   = peGridCanvas.height;
  ctx.clearRect(0, 0, w, h);
  ctx.strokeStyle = 'rgba(100,120,160,0.12)';
  ctx.lineWidth   = 0.5;
  var gs = GRID_SIZE * z;
  for (var x = 0; x <= w; x += gs) {
    ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke();
  }
  for (var y = 0; y <= h; y += gs) {
    ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke();
  }
}

/* ══════════════════
   SLIDES LIST (miniatures)
══════════════════ */
function renderSlidesList() {
  var cur = state.currentSlide;
  var html = '';
  for (var i = 0; i < state.slides.length; i++) {
    var sl = state.slides[i];
    html += '<div class="pe-slide-thumb' + (i === cur ? ' active' : '') + '" '
          + 'data-idx="' + i + '" '
          + 'draggable="' + (!READONLY ? 'true' : 'false') + '">'
          + '<div class="pe-slide-thumb-inner">'
          + '<div class="pe-slide-thumb-canvas" id="peThumb_' + i + '" '
          + 'style="background:' + (sl.bg || '#fff') + ';"></div>'
          + '</div>'
          + '<div class="pe-slide-thumb-num">' + (i+1) + '</div>'
          + '</div>';
  }
  peSlidesList.innerHTML = html;

  // Events sur les thumbs
  var thumbs = peSlidesList.querySelectorAll('.pe-slide-thumb');
  thumbs.forEach(function(th) {
    th.addEventListener('click', function() {
      var idx = parseInt(th.getAttribute('data-idx'));
      switchSlide(idx);
    });
    if (!READONLY) {
      // Réordonnancement drag-drop
      th.addEventListener('dragstart', function(e) {
        e.dataTransfer.setData('text/plain', th.getAttribute('data-idx'));
      });
      th.addEventListener('dragover', function(e) {
        e.preventDefault();
        th.classList.add('pe-slide-thumb-drag-over');
      });
      th.addEventListener('dragleave', function() {
        th.classList.remove('pe-slide-thumb-drag-over');
      });
      th.addEventListener('drop', function(e) {
        e.preventDefault();
        th.classList.remove('pe-slide-thumb-drag-over');
        var fromIdx = parseInt(e.dataTransfer.getData('text/plain'));
        var toIdx   = parseInt(th.getAttribute('data-idx'));
        if (fromIdx !== toIdx) {
          pushHistory();
          var moved = state.slides.splice(fromIdx, 1)[0];
          state.slides.splice(toIdx, 0, moved);
          state.currentSlide = toIdx;
          renderAll();
          scheduleAutoSave();
        }
      });
    }
  });

  // Rendu miniatures
  setTimeout(renderAllThumbs, 50);
}

/* ── Rendu miniature d'une slide par CSS inline ── */
function renderThumb(idx) {
  var el = $('peThumb_' + idx);
  if (!el) return;
  var sl = state.slides[idx];
  if (!sl) return;
  var z  = 160 / SLIDE_W;  // facteur de réduction

  var html = '';
  // Tri par z
  var sorted = sl.elements.slice().sort(function(a,b){ return (a.z||0)-(b.z||0); });
  sorted.forEach(function(elem) {
    var style = 'position:absolute;'
      + 'left:' + (elem.x * z) + 'px;'
      + 'top:'  + (elem.y * z) + 'px;'
      + 'width:'  + (elem.w * z) + 'px;'
      + 'height:' + (elem.h * z) + 'px;'
      + 'overflow:hidden;'
      + 'border-radius:' + ((elem.radius||0)*z) + 'px;'
      + 'opacity:' + (elem.opacity !== undefined ? elem.opacity : 1) + ';';

    if (elem.borderW) {
      style += 'border:' + (elem.borderW*z) + 'px solid ' + (elem.borderColor||'#000') + ';';
    }

    if (elem.type === 'text') {
      style += 'background:' + (elem.fill||'transparent') + ';'
             + 'font-size:'   + (elem.fontSize * z) + 'px;'
             + 'font-family:' + elem.fontFamily + ';'
             + 'font-weight:' + (elem.bold ? 700 : 400) + ';'
             + 'color:'       + (elem.color||'#000') + ';'
             + 'text-align:'  + (elem.align||'left') + ';'
             + 'padding:' + (2*z) + 'px;'
             + 'white-space:pre-wrap;line-height:1.3;';
      html += '<div style="' + style + '">' + escHtml(elem.text||'') + '</div>';
    } else if (elem.type === 'image' && elem.src) {
      style += 'background:transparent;';
      html += '<div style="' + style + '">'
            + '<img src="' + elem.src + '" style="width:100%;height:100%;object-fit:contain;" />'
            + '</div>';
    } else {
      style += 'background:' + (elem.fill||'transparent') + ';';
      html += '<div style="' + style + '"></div>';
    }
  });
  el.innerHTML = html;
}

function renderAllThumbs() {
  for (var i = 0; i < state.slides.length; i++) {
    renderThumb(i);
  }
}

function escHtml(s) {
  return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

/* ══════════════════
   SWITCH SLIDE
══════════════════ */
function switchSlide(idx) {
  // Validation texte en cours
  commitTextEdit();

  state.currentSlide = clamp(idx, 0, state.slides.length - 1);
  state.selectedIds  = [];
  renderSlidesList();
  renderCanvas();
  updateSlideTitleBar();
  updatePropsPanel();

  // Signaler la slide active aux collaborateurs
  wsEmit({ type: 'cursor', slide: state.currentSlide });
}

/* ══════════════════
   CANVAS RENDER
══════════════════ */
function renderCanvas() {
  var sl = currentSlide();
  if (!sl) { peSlideCanvas.innerHTML = '<div id="peGridCanvas-wrap"></div>'; return; }

  peSlideCanvas.style.background = sl.bg || '#fff';

  // Supprimer les éléments DOM précédents (garder grid + drop overlay)
  var children = Array.from(peSlideCanvas.children);
  children.forEach(function(c) {
    if (c.id !== 'peGridCanvas' && c.id !== 'peDropOverlay') {
      peSlideCanvas.removeChild(c);
    }
  });

  // Tri par z
  var sorted = sl.elements.slice().sort(function(a,b){ return (a.z||0)-(b.z||0); });
  sorted.forEach(function(elem) {
    var domEl = buildElementDom(elem);
    peSlideCanvas.appendChild(domEl);
  });

  updateHandles();
}

function currentSlide() {
  return state.slides[state.currentSlide] || null;
}

/* ── Création du DOM d'un élément ── */
function buildElementDom(elem) {
  var z    = state.zoom;
  var div  = document.createElement('div');
  div.className = 'pe-element ' + elem.type + '-el';
  div.id = 'peEl_' + elem.id;
  div.setAttribute('data-eid', elem.id);

  div.style.left    = (elem.x * z) + 'px';
  div.style.top     = (elem.y * z) + 'px';
  div.style.width   = (elem.w * z) + 'px';
  div.style.height  = (elem.h * z) + 'px';
  div.style.zIndex  = elem.z || 1;
  div.style.opacity = elem.opacity !== undefined ? elem.opacity : 1;
  div.style.borderRadius = ((elem.radius||0) * z) + 'px';
  if (elem.borderW) {
    div.style.border = (elem.borderW * z) + 'px solid ' + (elem.borderColor||'#000');
  }

  if (elem.type === 'text') {
    div.style.background  = elem.fill || 'transparent';
    div.style.color       = elem.color || '#000';
    div.style.fontSize    = (elem.fontSize * z) + 'px';
    div.style.fontFamily  = elem.fontFamily || 'Arial';
    div.style.fontWeight  = elem.bold ? '700' : '400';
    div.style.fontStyle   = elem.italic ? 'italic' : 'normal';
    div.style.textDecoration = elem.underline ? 'underline' : 'none';
    div.style.textAlign   = elem.align || 'left';
    div.style.lineHeight  = '1.35';
    div.style.padding     = (4*z) + 'px';
    div.style.boxSizing   = 'border-box';
    div.style.overflow    = 'hidden';
    div.style.whiteSpace  = 'pre-wrap';
    div.style.wordBreak   = 'break-word';
    div.style.userSelect  = READONLY ? 'none' : 'text';
    div.textContent = elem.text || '';

    if (!READONLY) {
      div.addEventListener('dblclick', function(e) {
        e.stopPropagation();
        startTextEdit(elem.id, div);
      });
    }
  } else if (elem.type === 'image') {
    div.style.background  = 'transparent';
    div.style.overflow    = 'hidden';
    if (elem.src) {
      var img = document.createElement('img');
      img.src = elem.src;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = 'contain';
      img.draggable = false;
      div.appendChild(img);
    } else {
      div.style.background = '#f1f5f9';
      div.style.border     = '2px dashed #94a3b8';
      div.style.display    = 'flex';
      div.style.alignItems = 'center';
      div.style.justifyContent = 'center';
      div.style.color = '#94a3b8';
      div.style.fontSize = (14 * z) + 'px';
      div.textContent = 'Image';
    }
  } else if (elem.type === 'rect' || elem.type === 'line') {
    div.style.background = elem.fill || '#e2e8f0';
  }

  // Sélection au clic
  if (!READONLY) {
    div.addEventListener('mousedown', function(e) {
      if (e.target.classList.contains('pe-text-edit')) return;
      e.stopPropagation();
      if (e.shiftKey) {
        toggleSelect(elem.id);
      } else {
        selectOnly(elem.id);
      }
      startDrag(e, elem.id);
    });
  } else {
    div.style.pointerEvents = 'none';
  }

  // Highlight si sélectionné
  if (state.selectedIds.indexOf(elem.id) >= 0) {
    div.classList.add('selected');
  }

  return div;
}

/* ══════════════════
   SÉLECTION
══════════════════ */
function selectOnly(id) {
  state.selectedIds = [id];
  updateHandles();
  updatePropsPanel();
  syncToolbarToElem();
}
function toggleSelect(id) {
  var idx = state.selectedIds.indexOf(id);
  if (idx >= 0) state.selectedIds.splice(idx, 1);
  else state.selectedIds.push(id);
  updateHandles();
  updatePropsPanel();
}
function clearSelection() {
  state.selectedIds = [];
  updateHandles();
  updatePropsPanel();
}

function getSelectedElements() {
  var sl = currentSlide();
  if (!sl) return [];
  return sl.elements.filter(function(e) {
    return state.selectedIds.indexOf(e.id) >= 0;
  });
}

function getElem(id) {
  var sl = currentSlide();
  if (!sl) return null;
  for (var i = 0; i < sl.elements.length; i++) {
    if (sl.elements[i].id === id) return sl.elements[i];
  }
  return null;
}

/* ══════════════════
   POIGNÉES (handles)
══════════════════ */
function updateHandles() {
  // Supprimer toutes les poignées existantes
  peSlideCanvas.querySelectorAll('.pe-handle, .pe-rubberband').forEach(function(h) {
    if (h.parentNode) h.parentNode.removeChild(h);
  });

  // Mise à jour des classes selected
  peSlideCanvas.querySelectorAll('.pe-element').forEach(function(d) {
    var eid = d.getAttribute('data-eid');
    if (state.selectedIds.indexOf(eid) >= 0) d.classList.add('selected');
    else d.classList.remove('selected');
  });

  if (READONLY || state.selectedIds.length !== 1) return;

  var elem = getElem(state.selectedIds[0]);
  if (!elem) return;
  var z = state.zoom;

  var positions = ['nw','n','ne','w','e','sw','s','se'];
  positions.forEach(function(pos) {
    var h = document.createElement('div');
    h.className = 'pe-handle ' + pos;
    h.setAttribute('data-pos', pos);
    h.setAttribute('data-eid', elem.id);
    peSlideCanvas.appendChild(h);
    h.addEventListener('mousedown', function(e) {
      e.stopPropagation();
      startResize(e, elem.id, pos);
    });
  });
}

/* ══════════════════
   DRAG (déplacer élément)
══════════════════ */
var dragState = null;

function startDrag(e, eid) {
  if (READONLY) return;
  var z   = state.zoom;
  var rct = peSlideCanvas.getBoundingClientRect();
  dragState = {
    eid: eid,
    startX: e.clientX,
    startY: e.clientY,
    origPositions: {},
    canvasLeft: rct.left,
    canvasTop:  rct.top,
  };
  // Mémoriser positions initiales de tous les sélectionnés
  var elems = getSelectedElements();
  elems.forEach(function(el) {
    dragState.origPositions[el.id] = { x: el.x, y: el.y };
  });
  e.preventDefault();
}

document.addEventListener('mousemove', function(e) {
  if (dragState) {
    var z  = state.zoom;
    var dx = (e.clientX - dragState.startX) / z;
    var dy = (e.clientY - dragState.startY) / z;
    var sl = currentSlide();
    if (!sl) return;
    var elems = getSelectedElements();
    elems.forEach(function(elem) {
      var op = dragState.origPositions[elem.id];
      if (!op) return;
      elem.x = snap(clamp(op.x + dx, 0, SLIDE_W - elem.w));
      elem.y = snap(clamp(op.y + dy, 0, SLIDE_H - elem.h));
      var domEl = $('peEl_' + elem.id);
      if (domEl) {
        domEl.style.left = (elem.x * z) + 'px';
        domEl.style.top  = (elem.y * z) + 'px';
      }
    });
    updateHandles();
    updatePropsPanel();
    return;
  }
  if (resizeState) {
    handleResize(e);
    return;
  }
  if (rubberState) {
    handleRubber(e);
    return;
  }
});

document.addEventListener('mouseup', function(e) {
  if (dragState) {
    pushHistory();
    scheduleAutoSave();
    broadcastSlide();
    renderThumb(state.currentSlide);
    dragState = null;
  }
  if (resizeState) {
    pushHistory();
    scheduleAutoSave();
    broadcastSlide();
    renderThumb(state.currentSlide);
    resizeState = null;
    updateHandles();
  }
  if (rubberState) {
    finishRubber(e);
    rubberState = null;
  }
});

/* ══════════════════
   RESIZE
══════════════════ */
var resizeState = null;

function startResize(e, eid, pos) {
  if (READONLY) return;
  var elem = getElem(eid);
  if (!elem) return;
  var z = state.zoom;
  resizeState = {
    eid, pos,
    startX: e.clientX,
    startY: e.clientY,
    origX: elem.x, origY: elem.y,
    origW: elem.w, origH: elem.h,
    z,
  };
  e.preventDefault();
}

function handleResize(e) {
  var rs   = resizeState;
  var z    = rs.z;
  var dx   = (e.clientX - rs.startX) / z;
  var dy   = (e.clientY - rs.startY) / z;
  var elem = getElem(rs.eid);
  if (!elem) return;

  var nx = rs.origX, ny = rs.origY;
  var nw = rs.origW, nh = rs.origH;
  var pos = rs.pos;

  if (pos.indexOf('e') >= 0) nw = snap(Math.max(20, rs.origW + dx));
  if (pos.indexOf('s') >= 0) nh = snap(Math.max(10, rs.origH + dy));
  if (pos.indexOf('w') >= 0) {
    nw = snap(Math.max(20, rs.origW - dx));
    nx = snap(rs.origX + rs.origW - nw);
  }
  if (pos.indexOf('n') >= 0) {
    nh = snap(Math.max(10, rs.origH - dy));
    ny = snap(rs.origY + rs.origH - nh);
  }

  elem.x = nx; elem.y = ny; elem.w = nw; elem.h = nh;

  var domEl = $('peEl_' + elem.id);
  if (domEl) {
    domEl.style.left   = (elem.x * z) + 'px';
    domEl.style.top    = (elem.y * z) + 'px';
    domEl.style.width  = (elem.w * z) + 'px';
    domEl.style.height = (elem.h * z) + 'px';
  }
  updateHandles();
  updatePropsPanel();
}

/* ══════════════════
   RUBBER-BAND SELECT
══════════════════ */
var rubberState = null;
var rubberEl = null;

peSlideCanvas.addEventListener('mousedown', function(e) {
  if (READONLY) return;
  if (e.target !== peSlideCanvas && e.target !== peGridCanvas) return;
  commitTextEdit();
  clearSelection();

  var rct = peSlideCanvas.getBoundingClientRect();
  rubberState = {
    x0: e.clientX - rct.left,
    y0: e.clientY - rct.top,
    x1: e.clientX - rct.left,
    y1: e.clientY - rct.top,
    rct,
  };
  rubberEl = document.createElement('div');
  rubberEl.className = 'pe-rubberband';
  rubberEl.style.left = rubberState.x0 + 'px';
  rubberEl.style.top  = rubberState.y0 + 'px';
  peSlideCanvas.appendChild(rubberEl);
  e.preventDefault();
});

function handleRubber(e) {
  if (!rubberState || !rubberEl) return;
  var rct = rubberState.rct;
  rubberState.x1 = e.clientX - rct.left;
  rubberState.y1 = e.clientY - rct.top;
  var x = Math.min(rubberState.x0, rubberState.x1);
  var y = Math.min(rubberState.y0, rubberState.y1);
  var w = Math.abs(rubberState.x1 - rubberState.x0);
  var h = Math.abs(rubberState.y1 - rubberState.y0);
  rubberEl.style.left   = x + 'px';
  rubberEl.style.top    = y + 'px';
  rubberEl.style.width  = w + 'px';
  rubberEl.style.height = h + 'px';
}

function finishRubber(e) {
  if (!rubberEl) return;
  var rct = rubberState.rct;
  var x0  = Math.min(rubberState.x0, rubberState.x1);
  var y0  = Math.min(rubberState.y0, rubberState.y1);
  var x1  = Math.max(rubberState.x0, rubberState.x1);
  var y1  = Math.max(rubberState.y0, rubberState.y1);
  if (rubberEl.parentNode) rubberEl.parentNode.removeChild(rubberEl);
  rubberEl = null;

  var z  = state.zoom;
  var sl = currentSlide();
  if (!sl) return;
  var sel = [];
  sl.elements.forEach(function(elem) {
    var ex0 = elem.x * z, ey0 = elem.y * z;
    var ex1 = (elem.x + elem.w) * z, ey1 = (elem.y + elem.h) * z;
    if (ex1 > x0 && ex0 < x1 && ey1 > y0 && ey0 < y1) sel.push(elem.id);
  });
  state.selectedIds = sel;
  updateHandles();
  updatePropsPanel();
}

/* ══════════════════
   ÉDITION TEXTE INLINE
══════════════════ */
var textEditState = null;

function startTextEdit(eid, domEl) {
  commitTextEdit();
  var elem = getElem(eid);
  if (!elem || elem.type !== 'text') return;

  domEl.classList.add('selected');
  var ta = document.createElement('textarea');
  ta.className = 'pe-text-edit';
  ta.value = elem.text || '';
  ta.style.fontSize  = domEl.style.fontSize;
  ta.style.fontFamily= domEl.style.fontFamily;
  ta.style.fontWeight= domEl.style.fontWeight;
  ta.style.fontStyle = domEl.style.fontStyle;
  ta.style.textDecoration = domEl.style.textDecoration;
  ta.style.color     = domEl.style.color;
  ta.style.textAlign = domEl.style.textAlign;
  ta.style.background= domEl.style.background || 'transparent';
  ta.style.lineHeight= '1.35';

  domEl.textContent = '';
  domEl.appendChild(ta);
  ta.focus();
  ta.select();

  textEditState = { eid, domEl, ta };

  ta.addEventListener('input', function() {
    elem.text = ta.value;
    renderThumb(state.currentSlide);
  });
  ta.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') commitTextEdit();
    e.stopPropagation();
  });
}

function commitTextEdit() {
  if (!textEditState) return;
  var te = textEditState;
  var elem = getElem(te.eid);
  if (elem && te.ta) {
    elem.text = te.ta.value;
  }
  te.domEl.removeChild(te.ta);
  te.domEl.textContent = elem ? (elem.text || '') : '';
  textEditState = null;
  pushHistory();
  scheduleAutoSave();
  broadcastSlide();
  renderThumb(state.currentSlide);
}

/* ══════════════════
   TOOLBAR : PROPRIÉTÉS FORMAT TEXTE
══════════════════ */
function syncToolbarToElem() {
  var elems = getSelectedElements();
  if (elems.length !== 1) return;
  var elem = elems[0];
  if (elem.type !== 'text') return;
  $('peFontFamily').value = elem.fontFamily || 'Arial';
  $('peFontSize').value   = elem.fontSize   || 20;
  $('peBold').classList.toggle('active',   !!elem.bold);
  $('peItalic').classList.toggle('active', !!elem.italic);
  $('peUnder').classList.toggle('active',  !!elem.underline);
  $('peTextColor').value  = elem.color || '#000000';
  $('peFillColor').value  = (elem.fill && elem.fill !== 'transparent') ? elem.fill : '#ffffff';
  $('peAlignL').classList.toggle('active', elem.align === 'left'   || !elem.align);
  $('peAlignC').classList.toggle('active', elem.align === 'center');
  $('peAlignR').classList.toggle('active', elem.align === 'right');
}

function applyTextProp(prop, val) {
  if (READONLY) return;
  pushHistory();
  var elems = getSelectedElements().filter(function(e){ return e.type==='text'; });
  if (!elems.length) return;
  elems.forEach(function(e){ e[prop] = val; });
  renderCanvas();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
}

/* Toolbar bindings */
$('peFontFamily').addEventListener('change', function() { applyTextProp('fontFamily', this.value); });
$('peFontSize').addEventListener('change', function() { applyTextProp('fontSize', parseInt(this.value)||20); });
$('peBold').addEventListener('click', function() {
  var elems = getSelectedElements().filter(function(e){ return e.type==='text'; });
  var val = elems.length && !elems[0].bold;
  applyTextProp('bold', val);
  this.classList.toggle('active', val);
});
$('peItalic').addEventListener('click', function() {
  var elems = getSelectedElements().filter(function(e){ return e.type==='text'; });
  var val = elems.length && !elems[0].italic;
  applyTextProp('italic', val);
  this.classList.toggle('active', val);
});
$('peUnder').addEventListener('click', function() {
  var elems = getSelectedElements().filter(function(e){ return e.type==='text'; });
  var val = elems.length && !elems[0].underline;
  applyTextProp('underline', val);
  this.classList.toggle('active', val);
});
$('peAlignL').addEventListener('click', function() { applyTextProp('align','left');   syncToolbarToElem(); });
$('peAlignC').addEventListener('click', function() { applyTextProp('align','center'); syncToolbarToElem(); });
$('peAlignR').addEventListener('click', function() { applyTextProp('align','right');  syncToolbarToElem(); });
$('peTextColor').addEventListener('input', function() { applyTextProp('color', this.value); });
$('peFillColor').addEventListener('input', function() {
  var elems = getSelectedElements();
  if (!elems.length) {
    // Couleur de fond de slide
    var sl = currentSlide();
    if (sl) {
      sl.bg = this.value;
      peSlideBgColor.value = this.value;
      pePropSlideBg.value  = this.value;
      peSlideCanvas.style.background = this.value;
      renderThumb(state.currentSlide);
      scheduleAutoSave();
    }
    return;
  }
  var val = $('peFillColor').value;
  pushHistory();
  elems.forEach(function(e){ e.fill = val; });
  renderCanvas();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
});

/* Z-order */
$('peZUp').addEventListener('click', function() {
  if (READONLY) return;
  pushHistory();
  var elems = getSelectedElements();
  elems.forEach(function(e){ e.z = (e.z||1) + 1; });
  renderCanvas();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
});
$('peZDown').addEventListener('click', function() {
  if (READONLY) return;
  pushHistory();
  var elems = getSelectedElements();
  elems.forEach(function(e){ e.z = Math.max(1, (e.z||1) - 1); });
  renderCanvas();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
});

/* ══════════════════
   AJOUT D'ÉLÉMENTS
══════════════════ */
if (!READONLY) {
  $('peAddTextBtn').addEventListener('click', function() {
    addElement(makeElement('text', { x:100, y:100, w:320, h:70, fontSize:28, text:'Titre' }));
  });
  $('peAddRectBtn').addEventListener('click', function() {
    addElement(makeElement('rect', { x:80, y:80, w:240, h:140 }));
  });
  $('peAddLineBtn').addEventListener('click', function() {
    addElement(makeElement('line', { x:60, y:SLIDE_H/2, w:SLIDE_W-120, h:4, fill:'#334155' }));
  });
  $('peAddImageBtn').addEventListener('click', function() {
    peImageFileInput.click();
  });
  $('peAddSlideBtn') && $('peAddSlideBtn').addEventListener('click', function() {
    addSlide();
  });
}

function addElement(elem) {
  pushHistory();
  var sl = currentSlide();
  if (!sl) return;
  sl.elements.push(elem);
  renderCanvas();
  selectOnly(elem.id);
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
}

/* ══════════════════
   SLIDE TITLE BAR
══════════════════ */
function updateSlideTitleBar() {
  var sl = currentSlide();
  if (!sl) return;
  peSlideTitleInput.value = sl.title || '';
  peSlideBgColor.value    = sl.bg   || '#ffffff';
  pePropSlideBg.value     = sl.bg   || '#ffffff';
}

peSlideTitleInput.addEventListener('input', function() {
  var sl = currentSlide();
  if (!sl || READONLY) return;
  sl.title = this.value;
  renderSlidesList();
  scheduleAutoSave();
  broadcastSlide();
});

peSlideBgColor.addEventListener('input', function() {
  var sl = currentSlide();
  if (!sl || READONLY) return;
  sl.bg = this.value;
  pePropSlideBg.value = this.value;
  peSlideCanvas.style.background = this.value;
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
});

/* ══════════════════
   PANNEAU PROPRIÉTÉS
══════════════════ */
function updatePropsPanel() {
  var elems = getSelectedElements();
  if (elems.length === 1) {
    peSlideProps.style.display = 'none';
    peElemProps.style.display  = 'block';
    var e = elems[0];
    $('pePropX').value       = Math.round(e.x);
    $('pePropY').value       = Math.round(e.y);
    $('pePropW').value       = Math.round(e.w);
    $('pePropH').value       = Math.round(e.h);
    $('pePropOpacity').value = Math.round((e.opacity !== undefined ? e.opacity : 1) * 100);
    $('pePropBorder').value  = e.borderW || 0;
    $('pePropBorderColor').value = e.borderColor || '#000000';
    $('pePropRadius').value  = e.radius || 0;
  } else {
    peElemProps.style.display  = 'none';
    peSlideProps.style.display = 'block';
  }
}

function bindPropInput(id, setter) {
  var el = $(id);
  if (!el) return;
  ['input','change'].forEach(function(ev) {
    el.addEventListener(ev, function() {
      if (READONLY) return;
      setter(this.value);
    });
  });
}

function setPropOnSelected(key, val) {
  pushHistory();
  var elems = getSelectedElements();
  elems.forEach(function(e){ e[key] = val; });
  renderCanvas();
  updateHandles();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
}

bindPropInput('pePropX', function(v){ setPropOnSelected('x', parseFloat(v)||0); });
bindPropInput('pePropY', function(v){ setPropOnSelected('y', parseFloat(v)||0); });
bindPropInput('pePropW', function(v){ setPropOnSelected('w', Math.max(10, parseFloat(v)||10)); });
bindPropInput('pePropH', function(v){ setPropOnSelected('h', Math.max(4,  parseFloat(v)||4)); });
bindPropInput('pePropOpacity', function(v){ setPropOnSelected('opacity', clamp(parseFloat(v)||100,0,100)/100); });
bindPropInput('pePropBorder', function(v){ setPropOnSelected('borderW', parseFloat(v)||0); });
bindPropInput('pePropBorderColor', function(v){ setPropOnSelected('borderColor', v); });
bindPropInput('pePropRadius', function(v){ setPropOnSelected('radius', parseFloat(v)||0); });

pePropSlideBg.addEventListener('input', function() {
  var sl = currentSlide();
  if (!sl || READONLY) return;
  sl.bg = this.value;
  peSlideBgColor.value = this.value;
  peSlideCanvas.style.background = this.value;
  renderThumb(state.currentSlide);
  scheduleAutoSave();
});

pePropFormat.addEventListener('change', function() {
  state.format = this.value;
  if (this.value === '4:3')        { SLIDE_W = 800;  SLIDE_H = 600;  }
  else if (this.value === 'A4')    { SLIDE_W = 794;  SLIDE_H = 1123; }
  else                             { SLIDE_W = 960;  SLIDE_H = 540;  }
  applyZoom();
  renderCanvas();
});

/* Supprimer / dupliquer slide */
$('pePropDeleteSlide') && $('pePropDeleteSlide').addEventListener('click', function() {
  deleteCurrentSlide();
});
$('pePropDupSlide') && $('pePropDupSlide').addEventListener('click', function() {
  duplicateCurrentSlide();
});
$('pePropDeleteElem') && $('pePropDeleteElem').addEventListener('click', function() {
  deleteSelected();
});

/* ══════════════════
   OPÉRATIONS SLIDES
══════════════════ */
function addSlide() {
  if (READONLY) return;
  pushHistory();
  var sl = makeSlide('Slide ' + (state.slides.length + 1));
  // Slide de départ avec titre + sous-titre
  sl.elements.push(makeElement('text', {
    x:60, y:160, w:SLIDE_W-120, h:80,
    fontSize: 40, text: 'Titre de la slide',
    bold: true, align: 'center', color: '#1e293b',
  }));
  sl.elements.push(makeElement('text', {
    x:100, y:270, w:SLIDE_W-200, h:50,
    fontSize: 22, text: 'Sous-titre ou description',
    align: 'center', color: '#64748b',
  }));
  state.slides.push(sl);
  state.currentSlide = state.slides.length - 1;
  renderAll();
  scheduleAutoSave();
  broadcastSlide();
}

function deleteCurrentSlide() {
  if (READONLY || state.slides.length <= 1) return;
  pushHistory();
  state.slides.splice(state.currentSlide, 1);
  state.currentSlide = Math.min(state.currentSlide, state.slides.length - 1);
  state.selectedIds  = [];
  renderAll();
  scheduleAutoSave();
  broadcastSlide();
}

function duplicateCurrentSlide() {
  if (READONLY) return;
  pushHistory();
  var clone = deepClone(currentSlide());
  clone.id  = uid();
  clone.elements.forEach(function(e){ e.id = uid(); });
  clone.title = clone.title + ' (copie)';
  state.slides.splice(state.currentSlide + 1, 0, clone);
  state.currentSlide++;
  state.selectedIds = [];
  renderAll();
  scheduleAutoSave();
  broadcastSlide();
}

function deleteSelected() {
  if (READONLY || !state.selectedIds.length) return;
  pushHistory();
  var sl = currentSlide();
  if (!sl) return;
  sl.elements = sl.elements.filter(function(e) {
    return state.selectedIds.indexOf(e.id) < 0;
  });
  state.selectedIds = [];
  renderCanvas();
  updateHandles();
  updatePropsPanel();
  renderThumb(state.currentSlide);
  scheduleAutoSave();
  broadcastSlide();
}

/* ══════════════════
   IMAGE : DRAG & DROP + SÉLECTEUR
══════════════════ */
peSlideCanvas.addEventListener('dragover', function(e) {
  if (READONLY) return;
  e.preventDefault();
  peDropOverlay.classList.add('visible');
});
peSlideCanvas.addEventListener('dragleave', function(e) {
  peDropOverlay.classList.remove('visible');
});
peSlideCanvas.addEventListener('drop', function(e) {
  e.preventDefault();
  peDropOverlay.classList.remove('visible');
  if (READONLY) return;
  var files = e.dataTransfer.files;
  if (!files.length) return;
  var rct = peSlideCanvas.getBoundingClientRect();
  var dropX = (e.clientX - rct.left) / state.zoom;
  var dropY = (e.clientY - rct.top)  / state.zoom;
  Array.from(files).forEach(function(file, i) {
    if (!file.type.startsWith('image/')) return;
    readImageFile(file, function(src, iw, ih) {
      var ratio = Math.min(400/iw, 300/ih, 1);
      addElement(makeElement('image', {
        x: snap(clamp(dropX - (iw*ratio)/2 + i*20, 0, SLIDE_W-iw*ratio)),
        y: snap(clamp(dropY - (ih*ratio)/2 + i*20, 0, SLIDE_H-ih*ratio)),
        w: Math.round(iw * ratio),
        h: Math.round(ih * ratio),
        src: src,
      }));
    });
  });
});

peImageFileInput.addEventListener('change', function() {
  if (READONLY) return;
  Array.from(this.files).forEach(function(file, i) {
    readImageFile(file, function(src, iw, ih) {
      var ratio = Math.min(400/iw, 300/ih, 1);
      addElement(makeElement('image', {
        x: snap(80 + i*20),
        y: snap(80 + i*20),
        w: Math.round(iw * ratio),
        h: Math.round(ih * ratio),
        src: src,
      }));
    });
  });
  peImageFileInput.value = '';
});

function readImageFile(file, cb) {
  var reader = new FileReader();
  reader.onload = function(ev) {
    var img = new Image();
    img.onload = function() { cb(ev.target.result, img.naturalWidth, img.naturalHeight); };
    img.src = ev.target.result;
  };
  reader.readAsDataURL(file);
}

/* ══════════════════
   CLAVIER : SUPPR, ARROWS, UNDO/REDO, COPY/PASTE
══════════════════ */
var clipboard = [];

document.addEventListener('keydown', function(e) {
  var tag = e.target.tagName;
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
  if (READONLY) return;

  var step = e.shiftKey ? GRID_SIZE * 5 : GRID_SIZE;

  if (e.key === 'Delete' || e.key === 'Backspace') {
    deleteSelected();
    e.preventDefault();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'z') {
    e.preventDefault();
    if (e.shiftKey) redo(); else undo();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'y') {
    e.preventDefault(); redo();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'c') {
    clipboard = deepClone(getSelectedElements());
    if (clipboard.length) toast('Copié (' + clipboard.length + ' élément(s))', 'success');
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'v') {
    if (!clipboard.length) return;
    pushHistory();
    var sl = currentSlide();
    var newIds = [];
    clipboard.forEach(function(elem) {
      var copy = deepClone(elem);
      copy.id = uid();
      copy.x  = snap(copy.x + 20);
      copy.y  = snap(copy.y + 20);
      sl.elements.push(copy);
      newIds.push(copy.id);
    });
    state.selectedIds = newIds;
    renderCanvas();
    renderThumb(state.currentSlide);
    scheduleAutoSave();
    broadcastSlide();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'a') {
    e.preventDefault();
    var sl2 = currentSlide();
    if (sl2) state.selectedIds = sl2.elements.map(function(el){ return el.id; });
    updateHandles();
    updatePropsPanel();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
    e.preventDefault();
    if (!state.selectedIds.length) return;
    pushHistory();
    var sl3 = currentSlide();
    var newIds2 = [];
    var selected = getSelectedElements();
    selected.forEach(function(elem) {
      var copy = deepClone(elem);
      copy.id = uid();
      copy.x  = snap(copy.x + 20);
      copy.y  = snap(copy.y + 20);
      sl3.elements.push(copy);
      newIds2.push(copy.id);
    });
    state.selectedIds = newIds2;
    renderCanvas();
    renderThumb(state.currentSlide);
    scheduleAutoSave();
    broadcastSlide();
  }
  // Flèches pour déplacer
  if (['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].indexOf(e.key) >= 0) {
    if (!state.selectedIds.length) return;
    e.preventDefault();
    pushHistory();
    var elems = getSelectedElements();
    elems.forEach(function(el) {
      if (e.key === 'ArrowLeft')  el.x = snap(clamp(el.x - step, 0, SLIDE_W - el.w));
      if (e.key === 'ArrowRight') el.x = snap(clamp(el.x + step, 0, SLIDE_W - el.w));
      if (e.key === 'ArrowUp')    el.y = snap(clamp(el.y - step, 0, SLIDE_H - el.h));
      if (e.key === 'ArrowDown')  el.y = snap(clamp(el.y + step, 0, SLIDE_H - el.h));
    });
    renderCanvas();
    updateHandles();
    updatePropsPanel();
    renderThumb(state.currentSlide);
    scheduleAutoSave();
  }
  // Navigation entre slides
  if (!e.ctrlKey && !e.metaKey && !e.altKey) {
    if (e.key === 'PageDown') { switchSlide(state.currentSlide + 1); e.preventDefault(); }
    if (e.key === 'PageUp')   { switchSlide(state.currentSlide - 1); e.preventDefault(); }
  }
});

/* ══════════════════
   PRÉSENTATION PLEIN ÉCRAN
══════════════════ */
$('pePresentBtn').addEventListener('click', startPresentation);

var presentIdx = 0;

function startPresentation() {
  presentIdx = state.currentSlide;
  peFullscreen.classList.add('active');
  renderFullscreen(presentIdx);
  document.addEventListener('keydown', presentKeydown);
}

function renderFullscreen(idx) {
  var sl = state.slides[idx];
  if (!sl) return;

  // Taille
  var vw = window.innerWidth  * 0.95;
  var vh = window.innerHeight * 0.87;
  var ratio = SLIDE_W / SLIDE_H;
  var w, h;
  if (vw / vh > ratio) { h = vh; w = h * ratio; }
  else { w = vw; h = w / ratio; }
  var z = w / SLIDE_W;

  peFullscreenSlide.style.width  = w + 'px';
  peFullscreenSlide.style.height = h + 'px';
  peFullscreenSlide.style.background = sl.bg || '#fff';
  peFullscreenSlide.innerHTML = '';

  var sorted = sl.elements.slice().sort(function(a,b){ return (a.z||0)-(b.z||0); });
  sorted.forEach(function(elem) {
    var div = document.createElement('div');
    div.style.position     = 'absolute';
    div.style.left         = (elem.x * z) + 'px';
    div.style.top          = (elem.y * z) + 'px';
    div.style.width        = (elem.w * z) + 'px';
    div.style.height       = (elem.h * z) + 'px';
    div.style.zIndex       = elem.z || 1;
    div.style.opacity      = elem.opacity !== undefined ? elem.opacity : 1;
    div.style.borderRadius = ((elem.radius||0) * z) + 'px';
    div.style.overflow     = 'hidden';
    div.style.boxSizing    = 'border-box';
    if (elem.borderW) {
      div.style.border = (elem.borderW * z) + 'px solid ' + (elem.borderColor||'#000');
    }
    if (elem.type === 'text') {
      div.style.background   = elem.fill || 'transparent';
      div.style.color        = elem.color || '#000';
      div.style.fontSize     = (elem.fontSize * z) + 'px';
      div.style.fontFamily   = elem.fontFamily || 'Arial';
      div.style.fontWeight   = elem.bold ? '700' : '400';
      div.style.fontStyle    = elem.italic ? 'italic' : 'normal';
      div.style.textDecoration = elem.underline ? 'underline' : 'none';
      div.style.textAlign    = elem.align || 'left';
      div.style.lineHeight   = '1.35';
      div.style.padding      = (6*z) + 'px';
      div.style.whiteSpace   = 'pre-wrap';
      div.style.wordBreak    = 'break-word';
      div.textContent        = elem.text || '';
    } else if (elem.type === 'image' && elem.src) {
      var img = document.createElement('img');
      img.src = elem.src;
      img.style.width  = '100%';
      img.style.height = '100%';
      img.style.objectFit = 'contain';
      img.draggable = false;
      div.appendChild(img);
    } else {
      div.style.background = elem.fill || '#e2e8f0';
    }
    peFullscreenSlide.appendChild(div);
  });

  peSlideCounter.textContent = (idx+1) + ' / ' + state.slides.length;
}

function presentKeydown(e) {
  if (e.key === 'Escape' || e.key === 'q') exitPresentation();
  if (e.key === 'ArrowRight' || e.key === 'ArrowDown' || e.key === ' ') {
    e.preventDefault();
    if (presentIdx < state.slides.length - 1) { presentIdx++; renderFullscreen(presentIdx); }
  }
  if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
    e.preventDefault();
    if (presentIdx > 0) { presentIdx--; renderFullscreen(presentIdx); }
  }
}

function exitPresentation() {
  peFullscreen.classList.remove('active');
  document.removeEventListener('keydown', presentKeydown);
}

$('pePrevSlide').addEventListener('click', function() {
  if (presentIdx > 0) { presentIdx--; renderFullscreen(presentIdx); }
});
$('peNextSlide').addEventListener('click', function() {
  if (presentIdx < state.slides.length - 1) { presentIdx++; renderFullscreen(presentIdx); }
});
$('peExitPresent').addEventListener('click', exitPresentation);

/* ══════════════════
   EXPORT PDF
   Technique : rendu canvas par slide, assemblage multi-pages
══════════════════ */
$('pePdfBtn').addEventListener('click', function() {
  exportPdf();
});

function exportPdf() {
  toast('Génération du PDF...', '');
  setTimeout(function() {
    try {
      _doExportPdf();
    } catch(err) {
      toast('Erreur export PDF : ' + err.message, 'error');
      console.error(err);
    }
  }, 50);
}

function _doExportPdf() {
  // Dimensions PDF en points (A4 paysage ou 16:9)
  var PDF_W  = 841.89;  // A4 landscape width in points
  var PDF_H  = 595.28;  // A4 landscape height in points
  var RENDER_SCALE = 2; // résolution rendu
  var RW = Math.round(PDF_W * RENDER_SCALE);
  var RH = Math.round(PDF_H * RENDER_SCALE);

  var pages = [];
  var idx   = 0;

  function renderNextPage() {
    if (idx >= state.slides.length) {
      buildPdfBlob(pages, PDF_W, PDF_H);
      return;
    }
    renderSlideToCanvas(state.slides[idx], RW, RH, function(dataUrl) {
      pages.push(dataUrl);
      idx++;
      renderNextPage();
    });
  }
  renderNextPage();
}

function renderSlideToCanvas(sl, w, h, cb) {
  var canvas  = document.createElement('canvas');
  canvas.width  = w;
  canvas.height = h;
  var ctx = canvas.getContext('2d');

  // Fond
  ctx.fillStyle = sl.bg || '#ffffff';
  ctx.fillRect(0, 0, w, h);

  var zx = w / SLIDE_W;
  var zy = h / SLIDE_H;

  var sorted = sl.elements.slice().sort(function(a,b){ return (a.z||0)-(b.z||0); });

  // Rendu séquentiel (images async)
  var imageJobs = sorted.filter(function(e){ return e.type === 'image' && e.src; });
  var pending = imageJobs.length;

  function drawAll() {
    sorted.forEach(function(elem) {
      ctx.save();
      ctx.globalAlpha = elem.opacity !== undefined ? elem.opacity : 1;

      var ex = elem.x * zx, ey = elem.y * zy;
      var ew = elem.w * zx, eh = elem.h * zy;

      // Clip + rayon
      if (elem.radius) {
        var r = elem.radius * Math.min(zx, zy);
        ctx.beginPath();
        ctx.moveTo(ex+r, ey);
        ctx.arcTo(ex+ew, ey, ex+ew, ey+eh, r);
        ctx.arcTo(ex+ew, ey+eh, ex, ey+eh, r);
        ctx.arcTo(ex, ey+eh, ex, ey, r);
        ctx.arcTo(ex, ey, ex+ew, ey, r);
        ctx.closePath();
        ctx.clip();
      }

      if (elem.type === 'text') {
        if (elem.fill && elem.fill !== 'transparent') {
          ctx.fillStyle = elem.fill;
          ctx.fillRect(ex, ey, ew, eh);
        }
        var fs = elem.fontSize * zy;
        var fStyle = (elem.italic ? 'italic ' : '') + (elem.bold ? 'bold ' : '') + fs + 'px ' + (elem.fontFamily||'Arial');
        ctx.font      = fStyle;
        ctx.fillStyle = elem.color || '#000';
        ctx.textAlign = elem.align || 'left';
        ctx.textBaseline = 'top';
        var tx = elem.align === 'center' ? ex + ew/2
               : elem.align === 'right'  ? ex + ew - 4*zx
               : ex + 4*zx;
        var lines = (elem.text||'').split('\n');
        var lineH = fs * 1.35;
        lines.forEach(function(line, li) {
          ctx.fillText(line, tx, ey + 4*zy + li * lineH, ew - 8*zx);
        });
        if (elem.underline) {
          ctx.strokeStyle = elem.color || '#000';
          ctx.lineWidth   = Math.max(1, fs * 0.05);
          lines.forEach(function(line, li) {
            var tm = ctx.measureText(line);
            var lx = elem.align === 'center' ? tx - tm.width/2
                   : elem.align === 'right'  ? tx - tm.width
                   : tx;
            var ly = ey + 4*zy + li*lineH + fs + 1;
            ctx.beginPath();
            ctx.moveTo(lx, ly);
            ctx.lineTo(lx + tm.width, ly);
            ctx.stroke();
          });
        }
      } else if (elem.type === 'image') {
        var imgEl = imageJobs.__cache && imageJobs.__cache[elem.id];
        if (imgEl) {
          ctx.drawImage(imgEl, ex, ey, ew, eh);
        }
      } else {
        ctx.fillStyle = elem.fill || '#e2e8f0';
        ctx.fillRect(ex, ey, ew, eh);
      }

      // Bordure
      if (elem.borderW) {
        ctx.strokeStyle = elem.borderColor || '#000';
        ctx.lineWidth   = elem.borderW * Math.min(zx, zy);
        ctx.strokeRect(ex, ey, ew, eh);
      }

      ctx.restore();
    });

    cb(canvas.toDataURL('image/jpeg', 0.92));
  }

  if (pending === 0) {
    drawAll();
    return;
  }

  var cache = {};
  imageJobs.forEach(function(elem) {
    var img = new Image();
    img.onload = function() {
      cache[elem.id] = img;
      pending--;
      if (pending === 0) {
        imageJobs.__cache = cache;
        drawAll();
      }
    };
    img.onerror = function() {
      pending--;
      if (pending === 0) {
        imageJobs.__cache = cache;
        drawAll();
      }
    };
    img.src = elem.src;
  });
  imageJobs.__cache = cache;
}

/* ── Assemblage PDF minimal (sans lib externe) ── */
function buildPdfBlob(pages, PW, PH) {
  // PDF basique multi-page avec images JPEG
  var objects = [];
  var offsets = [];
  var n = 1;

  function pushObj(content) {
    offsets.push(0); // sera calculé
    objects.push({ id: n++, content: content });
    return n - 1;
  }

  // Catalog + Pages
  var catalogId = n;
  var pagesId   = n + 1;
  n += 2;

  // Ressources images
  var imgIds = [];
  var pageIds = [];
  var pageObjs = [];

  for (var pi = 0; pi < pages.length; pi++) {
    var b64data = pages[pi].split(',')[1];
    var imgId = n++;
    imgIds.push(imgId);
    var pgId  = n++;
    pageIds.push(pgId);
  }

  var allObjects = [];

  // Catalog
  allObjects.push({ id: catalogId, content: '<< /Type /Catalog /Pages ' + pagesId + ' 0 R >>' });
  // Pages
  var kidsRef = pageIds.map(function(id){ return id + ' 0 R'; }).join(' ');
  allObjects.push({ id: pagesId, content: '<< /Type /Pages /Kids [' + kidsRef + '] /Count ' + pages.length + ' >>' });

  for (var pi2 = 0; pi2 < pages.length; pi2++) {
    var b64 = pages[pi2].split(',')[1];
    var iId = imgIds[pi2];
    var pId = pageIds[pi2];

    // Image object
    var rawBytes = atob(b64);
    var byteLen  = rawBytes.length;

    allObjects.push({
      id: iId,
      isStream: true,
      header: '<< /Type /XObject /Subtype /Image /Width ' + Math.round(PW*2) + ' /Height ' + Math.round(PH*2)
            + ' /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ' + byteLen + ' >>',
      streamB64: b64,
    });

    // Page content stream
    var contentStream = 'q ' + PW.toFixed(2) + ' 0 0 ' + PH.toFixed(2) + ' 0 0 cm /Img' + pi2 + ' Do Q';
    var csLen = contentStream.length;
    var csId  = n++;

    allObjects.push({
      id: csId,
      isStream: true,
      header: '<< /Length ' + csLen + ' >>',
      streamTxt: contentStream,
    });

    // Page object
    allObjects.push({
      id: pId,
      content: '<< /Type /Page /Parent ' + pagesId + ' 0 R'
             + ' /MediaBox [0 0 ' + PW.toFixed(2) + ' ' + PH.toFixed(2) + ']'
             + ' /Resources << /XObject << /Img' + pi2 + ' ' + iId + ' 0 R >> >>'
             + ' /Contents ' + csId + ' 0 R >>',
    });
  }

  // Construire le fichier PDF en bytes
  var parts = [];
  parts.push('%PDF-1.4\n');

  var byteOffset = parts[0].length;
  var xref = {};

  allObjects.sort(function(a,b){ return a.id - b.id; });

  allObjects.forEach(function(obj) {
    xref[obj.id] = byteOffset;
    var chunk;
    if (obj.isStream && obj.streamB64) {
      var header = obj.id + ' 0 obj\n' + obj.header + '\nstream\n';
      var footer = '\nendstream\nendobj\n';
      parts.push(header);
      byteOffset += header.length;
      parts.push({ b64: obj.streamB64, len: atob(obj.streamB64).length });
      byteOffset += atob(obj.streamB64).length;
      parts.push(footer);
      byteOffset += footer.length;
    } else if (obj.isStream && obj.streamTxt) {
      chunk = obj.id + ' 0 obj\n' + obj.header + '\nstream\n' + obj.streamTxt + '\nendstream\nendobj\n';
      parts.push(chunk);
      byteOffset += chunk.length;
    } else {
      chunk = obj.id + ' 0 obj\n' + obj.content + '\nendobj\n';
      parts.push(chunk);
      byteOffset += chunk.length;
    }
  });

  var xrefOffset = byteOffset;
  var maxId = allObjects[allObjects.length - 1].id + 1;
  var xrefStr = 'xref\n0 ' + maxId + '\n0000000000 65535 f \n';
  for (var id = 1; id < maxId; id++) {
    var off = xref[id] !== undefined ? xref[id] : 0;
    xrefStr += ('0000000000' + off).slice(-10) + ' 00000 n \n';
  }
  parts.push(xrefStr);

  var trailer = 'trailer\n<< /Size ' + maxId + ' /Root ' + catalogId + ' 0 R >>\nstartxref\n' + xrefOffset + '\n%%EOF\n';
  parts.push(trailer);

  // Assemblage Blob
  var blobParts = [];
  parts.forEach(function(p) {
    if (typeof p === 'string') {
      blobParts.push(strToUint8(p));
    } else if (p.b64) {
      blobParts.push(b64ToUint8(p.b64));
    }
  });

  var blob = new Blob(blobParts, { type: 'application/pdf' });
  var url  = URL.createObjectURL(blob);
  var a    = document.createElement('a');
  a.href     = url;
  a.download = 'presentation.pdf';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(function(){ URL.revokeObjectURL(url); }, 10000);
  toast('PDF téléchargé !', 'success');
}

function strToUint8(str) {
  var arr = new Uint8Array(str.length);
  for (var i = 0; i < str.length; i++) arr[i] = str.charCodeAt(i) & 0xff;
  return arr;
}

function b64ToUint8(b64) {
  var bin = atob(b64);
  var arr = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

/* ══════════════════
   WEBSOCKET COLLABORATION
══════════════════ */
var ws = null;
var WS_RECONNECT_DELAY = 3000;
var myUserId = 'u_' + uid();
var myUserColor = '#' + Math.floor(Math.random()*0xffffff).toString(16).padStart(6,'0');

// WebSocket interne supprimé : toute la communication passe par editor.js
// via window.EDITOR_send() et window.EDITOR_setContent().
function initWebSocket() { /* délégué à editor.js */ }
var ws = null;

function wsEmit(msg) {
  // Délégué à editor.js
  try {
    if (typeof window.EDITOR_send === 'function') window.EDITOR_send(msg);
  } catch(e) {}
}

function handleWsMessage(msg) {
  if (!msg || !msg.type) return;
  switch (msg.type) {
    case 'join':
      state.collab.users[msg.userId] = { color: msg.color, name: msg.userId };
      updateCollabIndicator();
      break;
    case 'leave':
      delete state.collab.users[msg.userId];
      updateCollabIndicator();
      break;
    case 'slide_update':
      if (msg.userId === myUserId) return;
      handleRemoteSlideUpdate(msg);
      break;
    case 'cursor':
      if (state.collab.users[msg.userId]) {
        state.collab.users[msg.userId].slide = msg.slide;
        updateCollabIndicator();
      }
      break;
  }
}

function handleRemoteSlideUpdate(msg) {
  if (!msg.slide) return;
  // Fusion simple : remplace la slide par son id
  var found = false;
  for (var i = 0; i < state.slides.length; i++) {
    if (state.slides[i].id === msg.slide.id) {
      if (i === state.currentSlide) {
        // Merge sans perdre la sélection locale
        var selBefore = state.selectedIds.slice();
        state.slides[i] = msg.slide;
        state.selectedIds = selBefore.filter(function(sid) {
          return msg.slide.elements.some(function(e){ return e.id === sid; });
        });
        renderCanvas();
        updateHandles();
        updateSlideTitleBar();
      } else {
        state.slides[i] = msg.slide;
      }
      renderSlidesList();
      found = true;
      break;
    }
  }
  if (!found) {
    // Nouvelle slide reçue
    if (msg.slideIdx !== undefined) {
      state.slides.splice(msg.slideIdx, 0, msg.slide);
    } else {
      state.slides.push(msg.slide);
    }
    renderSlidesList();
  }
}

var _broadcastDebounce = null;
function broadcastSlide() {
  clearTimeout(_broadcastDebounce);
  _broadcastDebounce = setTimeout(function () {
    if (typeof window.EDITOR_send === 'function' && typeof window.EDITOR_getContent === 'function') {
      window.EDITOR_send({
        type:    'content_update',
        content: window.EDITOR_getContent()
      });
    }
  }, 300);
}

function updateCollabIndicator() {
  var html = '';
  Object.keys(state.collab.users).forEach(function(uid) {
    var u = state.collab.users[uid];
    if (uid === myUserId) return;
    html += '<span class="pe-collab-user">'
          + '<span class="pe-collab-dot" style="background:' + (u.color||'#888') + '"></span>'
          + (u.slide !== undefined ? 'Slide ' + (u.slide+1) : '')
          + '</span>';
  });
  peCollabIndicator.innerHTML = html;
}

/* ══════════════════
   AUTO-SAVE
══════════════════ */
var autoSaveTimer = null;

function scheduleAutoSave() {
  state.dirty = true;
  if (autoSaveTimer) clearTimeout(autoSaveTimer);
  autoSaveTimer = setTimeout(doAutoSave, AUTO_SAVE_DELAY);
}

function doAutoSave() {
  if (!state.dirty) return;
  state.dirty = false;
  try {
    if (typeof window.EDITOR_send === 'function' && typeof window.EDITOR_getContent === 'function') {
      window.EDITOR_send({
        type:    'save_request',
        content: window.EDITOR_getContent()
      });
    }
  } catch(e) {}
}

/* ══════════════════
   CHARGEMENT INITIAL
══════════════════ */
function loadInitialData() {
  // Tenter de charger depuis window.PRESENTATION_DATA (injecté par le JSP parent)
  var data = (typeof window.PRESENTATION_DATA !== 'undefined') ? window.PRESENTATION_DATA : null;
  if (data && data.slides && data.slides.length) {
    state.slides = data.slides;
  } else {
    // Slide de démarrage
    var intro = makeSlide('Introduction');
    intro.bg = '#ffffff';
    intro.elements = [
      makeElement('rect',  { x:0, y:0, w:SLIDE_W, h:120, fill:'#1e293b', z:1, radius:0, borderW:0 }),
      makeElement('text',  { x:40, y:20, w:SLIDE_W-80, h:80, fontSize:48, text:'Titre de la présentation', bold:true, color:'#f8fafc', align:'left', fill:'transparent', z:2 }),
      makeElement('text',  { x:40, y:170, w:SLIDE_W-80, h:60, fontSize:26, text:'Sous-titre ou description', color:'#475569', align:'left', fill:'transparent', z:2 }),
      makeElement('line',  { x:40, y:250, w:200, h:4, fill:'#4f7ef8', z:2 }),
    ];
    state.slides = [intro];

    // Slide 2
    var sl2 = makeSlide('Contenu');
    sl2.elements = [
      makeElement('text', { x:60, y:50, w:SLIDE_W-120, h:70, fontSize:36, text:'Titre de section', bold:true, color:'#1e293b', align:'left', fill:'transparent', z:1 }),
      makeElement('line', { x:60, y:128, w:SLIDE_W-120, h:3, fill:'#4f7ef8', z:1 }),
      makeElement('text', { x:60, y:150, w:SLIDE_W-120, h:300, fontSize:20, text:'Contenu de la slide\n\nAjoutez votre texte ici.\nDouble-cliquez pour éditer.', color:'#334155', fill:'transparent', z:1 }),
    ];
    state.slides.push(sl2);
  }
  state.currentSlide = 0;
  pushHistory();
}

/* ══════════════════
   RENDU COMPLET
══════════════════ */
function renderAll() {
  renderSlidesList();
  renderCanvas();
  updateSlideTitleBar();
  updatePropsPanel();
  applyZoom();
}

/* ══════════════════
   RESIZE FENÊTRE
══════════════════ */
var resizeTimer;
window.addEventListener('resize', function() {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(function() {
    applyZoom();
    renderCanvas();
  }, 150);
});

/* ══════════════════
   INIT
══════════════════ */
loadInitialData();
applyZoom();
renderAll();
// initWebSocket() supprimé : la connexion WebSocket est gérée par editor.js

// Exposer API publique pour intégration avec editor.js
window.PresentationEditor = {
  getState:    function() { return state; },
  getSlides:   function() { return state.slides; },
  switchSlide: switchSlide,
  addSlide:    addSlide,
  undo:        undo,
  redo:        redo,
  exportPdf:   exportPdf,
};


// ══════════════════════════════════════════
//   INTÉGRATION editor.js (WebSocket)
// ══════════════════════════════════════════
window.EDITOR_getContent = function () {
    try {
        return JSON.stringify({ slides: state.slides });
    } catch (e) {
        return JSON.stringify({ slides: [] });
    }
};

window.EDITOR_setContent = function (jsonStr) {
    if (!jsonStr) return;
    try {
        var parsed = JSON.parse(jsonStr);
        var slides = null;
        if (parsed && parsed.slides && Array.isArray(parsed.slides) && parsed.slides.length > 0) {
            slides = parsed.slides;
        } else if (Array.isArray(parsed) && parsed.length > 0) {
            slides = parsed;
        }
        if (slides) {
            state.slides = slides;
            state.currentSlide = Math.min(state.currentSlide, slides.length - 1);
            state.selectedIds  = [];
            pushHistory();
            renderAll();
        }
    } catch (e) { /* ignore */ }
};

window.EDITOR_goToSlide = function (idx) {
    try { switchSlide(idx); } catch (e) {}
};

})(); // fin IIFE
</script>
