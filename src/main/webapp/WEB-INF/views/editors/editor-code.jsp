<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
    Fragment editeur CODE — inclus par editor.jsp via jsp:include.
    Ce fichier ne contient QUE le HTML et le CSS.
    Toute la logique JS (colorisation, download, EDITOR_getContent/setContent)
    est dans editor-code.js, charge par editor.jsp apres ce fragment.

    IDs exposes pour editor-code.js :
      #langSelector  — <select> choix du langage
      #ceDownloadBtn — bouton telecharger
      #ceCopyBtn     — bouton copier
      #ceExtLbl      — span affichant l'extension (.py, .js, ...)
      #ceHL          — <pre> couche de colorisation
      #ceGutter      — gouttiere numeros de ligne
      #docContent    — <textarea> saisie
      #cePos         — barre de statut : position curseur
      #ceLang        — barre de statut : label du langage
--%>

<style>
/* ══════════════════════════════════════════════════════
   EDITEUR CODE
══════════════════════════════════════════════════════ */
.ce-root {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    background: #1e1e1e;
    font-family: 'Cascadia Code', 'Fira Code', 'Consolas', 'Courier New', monospace;
    font-size: 13px;
    line-height: 1.6;
    overflow: hidden;
}

/* ── Toolbar ── */
.ce-bar {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 5px 10px;
    background: #252526;
    border-bottom: 1px solid #111;
    flex-shrink: 0;
    flex-wrap: wrap;
}
.ce-bar label {
    font-size: 11px;
    color: #858585;
    font-family: 'Segoe UI', system-ui, sans-serif;
    white-space: nowrap;
}
.ce-bar select {
    height: 26px;
    padding: 0 6px;
    background: #3c3c3c;
    border: 1px solid #555;
    border-radius: 3px;
    color: #ccc;
    font-size: 12px;
    font-family: 'Segoe UI', system-ui, sans-serif;
    cursor: pointer;
    outline: none;
}
.ce-bar select:focus { border-color: #007acc; }

.ce-btn {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    height: 26px;
    padding: 0 10px;
    background: #3c3c3c;
    border: 1px solid #555;
    border-radius: 3px;
    color: #ccc;
    font-size: 12px;
    font-family: 'Segoe UI', system-ui, sans-serif;
    cursor: pointer;
    white-space: nowrap;
    transition: background .1s, border-color .1s, color .1s;
}
.ce-btn:hover  { background: #4a4a4a; border-color: #007acc; color: #fff; }
.ce-btn:active { background: #007acc; }
.ce-btn.ce-ok  { border-color: #4ec9b0; color: #4ec9b0; }

/* ── Corps ── */
.ce-body {
    display: flex;
    flex: 1;
    min-height: 0;
    overflow: hidden;
}
.ce-gutter {
    padding: 10px 10px 10px 6px;
    background: #1e1e1e;
    border-right: 1px solid #2a2a2a;
    color: #4a4a4a;
    text-align: right;
    white-space: pre;
    user-select: none;
    overflow: hidden;
    flex-shrink: 0;
    min-width: 38px;
    font-variant-numeric: tabular-nums;
    font-size: 12px;
    line-height: 1.6;
}
.ce-scroll {
    position: relative;
    flex: 1;
    min-width: 0;
    overflow: hidden;
}

/* Couche colorisation (en dessous, lecture seule) */
/* On ne fait PAS font:inherit car Bulma reset les <pre> avec sa propre couleur.
   On declare tout explicitement pour etre sur de l'emporter. */
#ceHL {
    position: absolute;
    inset: 0;
    margin: 0;
    padding: 10px 14px;
    font-family: 'Cascadia Code', 'Fira Code', 'Consolas', 'Courier New', monospace;
    font-size: 13px;
    font-weight: normal;
    font-style: normal;
    line-height: 1.6;
    white-space: pre;
    word-break: normal;
    overflow-wrap: normal;
    color: #d4d4d4;
    background: transparent;
    border: none;
    border-radius: 0;
    padding-top: 10px;
    max-height: none;
    pointer-events: none;
    overflow: hidden;
    box-sizing: border-box;
    tab-size: 4;
    -moz-tab-size: 4;
}
/* Neutraliser reset Bulma/normalize sur pre > code */
#ceHL code {
    background: transparent;
    color: inherit;
    font-size: inherit;
    padding: 0;
}

/* Textarea transparente (saisie, au-dessus) */
#docContent {
    position: absolute;
    inset: 0;
    margin: 0;
    padding: 10px 14px;
    font-family: 'Cascadia Code', 'Fira Code', 'Consolas', 'Courier New', monospace;
    font-size: 13px;
    font-weight: normal;
    line-height: 1.6;
    white-space: pre;
    word-break: normal;
    overflow-wrap: normal;
    color: transparent;
    caret-color: #aeafad;
    background: transparent;
    border: none;
    outline: none;
    resize: none;
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    overflow: auto;
    tab-size: 4;
    -moz-tab-size: 4;
    -webkit-text-fill-color: transparent;
    scrollbar-width: thin;
    scrollbar-color: #424242 transparent;
    z-index: 1;
}
#docContent::-webkit-scrollbar       { width: 8px; height: 8px; }
#docContent::-webkit-scrollbar-track { background: transparent; }
#docContent::-webkit-scrollbar-thumb { background: #424242; border-radius: 4px; }
#docContent::selection {
    background: rgba(38, 79, 120, .7);
    -webkit-text-fill-color: transparent;
}

/* ── Barre de statut ── */
.ce-status {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 12px;
    height: 20px;
    background: #007acc;
    color: rgba(255,255,255,.9);
    font-size: 11px;
    font-family: 'Segoe UI', system-ui, sans-serif;
    flex-shrink: 0;
    user-select: none;
}

/* ══════════════════════════════════════════════════════
   TOKENS (palette VS Code Dark+)
══════════════════════════════════════════════════════ */
.ck  { color: #569cd6 }
.ck2 { color: #c586c0 }
.cs  { color: #ce9178 }
.cs2 { color: #98c379 }
.cc  { color: #6a9955; font-style: italic }
.cn  { color: #b5cea8 }
.ct  { color: #4ec9b0 }
.cf  { color: #dcdcaa }
.cm  { color: #c586c0 }
.ca  { color: #9cdcfe }
.cta { color: #ce9178 }
.cat { color: #9cdcfe }
.cmk { color: #569cd6 }
.cmb { color: #ce9178; font-weight: bold }
.cmi { color: #ce9178; font-style: italic }
.cmc { color: #6a9955; font-family: monospace }
</style>

<div class="ce-root" id="ceRoot">

    <%-- Toolbar --%>
    <div class="ce-bar">
        <label for="langSelector">Langage&nbsp;</label>
        <select id="langSelector" <c:if test="${!canEdit}">disabled</c:if>>
            <option value="plaintext">Texte brut</option>
            <optgroup label="Web">
                <option value="html">HTML</option>
                <option value="css">CSS</option>
                <option value="javascript">JavaScript</option>
                <option value="typescript">TypeScript</option>
                <option value="json">JSON</option>
                <option value="xml">XML</option>
                <option value="php">PHP</option>
            </optgroup>
            <optgroup label="Systemes">
                <option value="c">C</option>
                <option value="cpp">C++</option>
                <option value="java">Java</option>
                <option value="python">Python</option>
                <option value="go">Go</option>
                <option value="rust">Rust</option>
                <option value="bash">Bash / Shell</option>
            </optgroup>
            <optgroup label="Donnees">
                <option value="sql">SQL</option>
                <option value="markdown">Markdown</option>
            </optgroup>
        </select>

        <button class="ce-btn" id="ceDownloadBtn" type="button">
            &#8595;&nbsp;Telecharger&nbsp;<span id="ceExtLbl">.py</span>
        </button>
        <button class="ce-btn" id="ceCopyBtn" type="button">Copier</button>
    </div>

    <%-- Corps --%>
    <div class="ce-body">
        <div class="ce-gutter" id="ceGutter">1</div>
        <div class="ce-scroll">
            <pre id="ceHL" aria-hidden="true"></pre>
            <textarea
                id="docContent"
                spellcheck="false"
                autocomplete="off"
                autocorrect="off"
                autocapitalize="off"
                <c:if test="${!canEdit}">readonly</c:if>
                placeholder="// Votre code ici..."></textarea>
        </div>
    </div>

    <%-- Barre de statut --%>
    <div class="ce-status">
        <span id="cePos">Ln 1, Col 1</span>
        <span id="ceLang">Python</span>
    </div>

</div>
