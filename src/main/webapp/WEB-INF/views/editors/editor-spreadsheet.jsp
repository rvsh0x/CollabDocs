<%-- Fragment éditeur SPREADSHEET — inclus par editor.jsp --%>
<%-- JS : /js/editor-spreadsheet.js (chargé par editor.jsp après editor.js) --%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<style>
/* ================================================================
   SPREADSHEET EDITOR — Styles complets
   ================================================================ */

.spreadsheet-wrapper {
    display: flex;
    flex-direction: column;
    height: 100%;
    overflow: hidden;
    background: #fff;
    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
    font-size: 13px;
}

/* ── Barre d'outils ──────────────────────────────────────────── */
.spreadsheet-toolbar {
    display: flex;
    align-items: center;
    gap: 2px;
    padding: 4px 8px;
    background: #f7f7f7;
    border-bottom: 1px solid #d0d0d0;
    flex-shrink: 0;
    flex-wrap: wrap;
}

.spreadsheet-toolbar .toolbar-sep {
    width: 1px;
    height: 20px;
    background: #ccc;
    margin: 0 4px;
    flex-shrink: 0;
}

.spreadsheet-toolbar .button.is-small {
    height: 26px;
    min-width: 28px;
    padding: 0 6px;
    font-size: 12px;
    border: 1px solid #ccc;
    border-radius: 3px;
    background: #fff;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    line-height: 1;
    color: #333;
    transition: background .1s, border-color .1s;
    user-select: none;
}
.spreadsheet-toolbar .button.is-small:hover {
    background: #e8e8e8;
    border-color: #aaa;
}
.spreadsheet-toolbar .button.is-small:active,
.spreadsheet-toolbar .button.is-small.is-active {
    background: #d0e8ff;
    border-color: #4a90d9;
    color: #1a5fa8;
}

/* Référence de cellule (ex : A1) */
.ss-cell-ref-box {
    display: inline-flex;
    align-items: center;
    border: 1px solid #ccc;
    border-radius: 3px;
    background: #fff;
    padding: 0 6px;
    height: 26px;
    min-width: 52px;
    font-size: 12px;
    font-family: monospace;
    color: #555;
    flex-shrink: 0;
}
#cellRef {
    font-weight: 600;
    color: #1a5fa8;
}

/* Barre de formule */
.ss-formula-bar {
    display: flex;
    align-items: center;
    gap: 0;
    flex: 1;
    min-width: 120px;
    max-width: 480px;
}
.ss-formula-bar-prefix {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    height: 26px;
    width: 26px;
    border: 1px solid #ccc;
    border-right: none;
    border-radius: 3px 0 0 3px;
    background: #f0f0f0;
    color: #888;
    font-size: 12px;
    font-style: italic;
    flex-shrink: 0;
    user-select: none;
}
#ssFormulaBar {
    height: 26px;
    flex: 1;
    border: 1px solid #ccc;
    border-radius: 0 3px 3px 0;
    padding: 0 6px;
    font-size: 12px;
    font-family: monospace;
    outline: none;
    color: #222;
    min-width: 0;
}
#ssFormulaBar:focus {
    border-color: #4a90d9;
    box-shadow: 0 0 0 2px rgba(74,144,217,.15);
}

/* Collaborateurs */
.collaborator-cursors {
    margin-left: auto;
    display: flex;
    gap: 4px;
    align-items: center;
}

/* ── Conteneur scrollable ────────────────────────────────────── */
.spreadsheet-container {
    flex: 1;
    overflow: hidden;
    position: relative;
}

.ss-scroll-wrapper {
    width: 100%;
    height: 100%;
    overflow: auto;
    position: absolute;
    inset: 0;
}

/* ── Tableau ─────────────────────────────────────────────────── */
.spreadsheet-table {
    border-collapse: collapse;
    table-layout: fixed;
    min-width: max-content;
    position: relative;
}

/* En-têtes collants */
.spreadsheet-table thead {
    position: sticky;
    top: 0;
    z-index: 20;
}
.spreadsheet-table thead tr {
    background: #f0f0f0;
}
.ss-corner {
    position: sticky;
    left: 0;
    z-index: 30;
    background: #e8e8e8;
    border: 1px solid #ccc;
    min-width: 46px;
    width: 46px;
}
.ss-col-header {
    border: 1px solid #ccc;
    text-align: center;
    font-size: 11px;
    font-weight: 600;
    color: #555;
    min-width: 80px;
    width: 80px;
    height: 22px;
    padding: 0 4px;
    background: #f0f0f0;
    user-select: none;
    cursor: default;
    white-space: nowrap;
    overflow: hidden;
    transition: background .1s;
}
.ss-col-header.ss-axis-hl {
    background: #d0e8ff;
    color: #1a5fa8;
}

.ss-row-header {
    position: sticky;
    left: 0;
    z-index: 10;
    background: #f0f0f0;
    border: 1px solid #ccc;
    text-align: right;
    font-size: 11px;
    font-weight: 600;
    color: #777;
    min-width: 46px;
    width: 46px;
    padding: 0 6px;
    user-select: none;
    cursor: default;
    white-space: nowrap;
    transition: background .1s;
}
.ss-row-header.ss-axis-hl {
    background: #d0e8ff;
    color: #1a5fa8;
}

/* Cellules */
.ss-cell {
    border: 1px solid #e0e0e0;
    padding: 1px 4px;
    min-width: 80px;
    width: 80px;
    height: 22px;
    max-height: 22px;
    white-space: nowrap;
    overflow: hidden;
    outline: none;
    vertical-align: middle;
    font-size: 13px;
    color: #222;
    cursor: cell;
    position: relative;
    box-sizing: border-box;
    caret-color: #1a5fa8;
    transition: background .07s;
}
.ss-cell:focus {
    border: 2px solid #4a90d9;
    padding: 0 3px;
    z-index: 5;
    background: #fff !important;
    box-shadow: 0 0 0 3px rgba(74,144,217,.18);
}
.ss-cell:hover:not(:focus) {
    background: #f5f9ff;
}

/* Cellule avec formule */
.ss-cell.has-formula {
    color: #1a5fa8;
}
.ss-cell.has-formula::before {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    border-style: solid;
    border-width: 0 5px 5px 0;
    border-color: transparent #4a90d9 transparent transparent;
    opacity: .6;
}

/* Sélection de plage */
.ss-cell.ss-selected-range {
    background: #e3f0ff !important;
    border-color: #4a90d9;
}

/* Curseur collaborateur */
.collab-cursor {
    font-size: 9px;
    padding: 1px 3px;
    border-radius: 2px;
    color: #fff;
    pointer-events: none;
    z-index: 10;
    line-height: 1.4;
}

/* Chargement */
.spreadsheet-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100px;
    color: #999;
    font-style: italic;
    font-size: 13px;
}

/* Responsive mobile */
@media (max-width: 600px) {
    .ss-col-header, .ss-cell { min-width: 60px; width: 60px; }
    .ss-corner, .ss-row-header { min-width: 36px; width: 36px; }
}
</style>

<div class="spreadsheet-wrapper">

    <%-- ── Barre d'outils ──────────────────────────────── --%>
    <div class="spreadsheet-toolbar">

        <%-- Référence cellule --%>
        <div class="ss-cell-ref-box">
            <span id="cellRef">—</span>
        </div>

        <%-- Barre de formule --%>
        <div class="ss-formula-bar">
            <span class="ss-formula-bar-prefix">fx</span>
            <input type="text" id="ssFormulaBar"
                   placeholder="Valeur ou formule  (ex : =A1+B2, =SUM(A1:A5))"
                   autocomplete="off" spellcheck="false"
                   <c:if test="${!canEdit}">disabled</c:if> />
        </div>

        <c:if test="${canEdit}">
            <div class="toolbar-sep"></div>

            <%-- Formatage --%>
            <button id="ssFormatBold"   class="button is-small" title="Gras (Ctrl+B)"><strong>G</strong></button>
            <button id="ssFormatItalic" class="button is-small" title="Italique (Ctrl+I)"><em>I</em></button>

            <div class="toolbar-sep"></div>

            <%-- Alignement --%>
            <button id="ssAlignLeft"   class="button is-small" title="Aligner à gauche">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect x="0" y="1" width="12" height="1.5" fill="currentColor"/>
                    <rect x="0" y="4" width="8"  height="1.5" fill="currentColor"/>
                    <rect x="0" y="7" width="12" height="1.5" fill="currentColor"/>
                    <rect x="0" y="10" width="6" height="1.5" fill="currentColor"/>
                </svg>
            </button>
            <button id="ssAlignCenter" class="button is-small" title="Centrer">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect x="0" y="1" width="12" height="1.5" fill="currentColor"/>
                    <rect x="2" y="4" width="8"  height="1.5" fill="currentColor"/>
                    <rect x="0" y="7" width="12" height="1.5" fill="currentColor"/>
                    <rect x="3" y="10" width="6" height="1.5" fill="currentColor"/>
                </svg>
            </button>
            <button id="ssAlignRight"  class="button is-small" title="Aligner à droite">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect x="0"  y="1" width="12" height="1.5" fill="currentColor"/>
                    <rect x="4"  y="4" width="8"  height="1.5" fill="currentColor"/>
                    <rect x="0"  y="7" width="12" height="1.5" fill="currentColor"/>
                    <rect x="6"  y="10" width="6" height="1.5" fill="currentColor"/>
                </svg>
            </button>

            <div class="toolbar-sep"></div>

            <%-- Effacer --%>
            <button id="ssClearCell" class="button is-small" title="Effacer la sélection (Suppr)">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M2 2L10 10M10 2L2 10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                </svg>
            </button>
        </c:if>

        <%-- Curseurs collaborateurs --%>
        <span class="collaborator-cursors" id="collaboratorCursors"></span>
    </div>

    <%-- ── Tableau (généré par JS) ─────────────────────── --%>
    <div class="spreadsheet-container" id="spreadsheetContainer">
        <div class="spreadsheet-loading">Chargement du tableur…</div>
    </div>

</div>

<script>
/* Passé au JS depuis le serveur */
var SPREADSHEET_READONLY = ${!canEdit};
</script>
