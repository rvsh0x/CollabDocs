/**
 * editor-spreadsheet.js — Éditeur SPREADSHEET — COMPLET
 * Tableau HTML dynamique : colonnes A→Z (26), lignes 1→99
 * Fonctionnalités :
 *  - Édition contenteditable
 *  - Formules arithmétiques : =A1+B2, =SUM(A1:A10), =AVG, =MIN, =MAX, =COUNT
 *  - Références de cellules dans les formules
 *  - Formatage bold / italic
 *  - Collaboration (curseurs distants)
 *  - Synchronisation sans perte de focus
 *  - Navigation clavier (Tab, Enter, flèches)
 *  - Sélection multiple (Shift+clic)
 */

(function () {
    'use strict';

    /* ------------------------------------------------------------------ */
    /* Config                                                               */
    /* ------------------------------------------------------------------ */
    var TOTAL_ROWS = 99;
    var TOTAL_COLS = 26; // A → Z

    var container    = document.getElementById('spreadsheetContainer');
    var cellRefEl    = document.getElementById('cellRef');
    var formulaBarEl = document.getElementById('ssFormulaBar');
    var debounceTimer = null;

    var state = { rows: TOTAL_ROWS, cols: TOTAL_COLS, cells: {} };
    var tableEl   = null;
    var theadEl   = null;
    var tbodyEl   = null;
    var selectedCell  = null;   // td DOM
    var selectedRange = [];     // [{r,c}] pour la sélection multiple
    var isSelectingRange = false;
    var rangeStart = null;

    var collaboratorColors = {};
    var colorPalette = ['#e74c3c','#2ecc71','#3498db','#f39c12','#9b59b6','#1abc9c','#e67e22'];
    var colorIdx = 0;

    var canEdit = (typeof SPREADSHEET_READONLY !== 'undefined') ? !SPREADSHEET_READONLY : true;

    /* ------------------------------------------------------------------ */
    /* Utilitaires                                                          */
    /* ------------------------------------------------------------------ */

    function getUserColor(username) {
        if (!collaboratorColors[username]) {
            collaboratorColors[username] = colorPalette[colorIdx++ % colorPalette.length];
        }
        return collaboratorColors[username];
    }

    function cellKey(r, c) { return r + ':' + c; }

    function colLabel(n) {
        // n est 0-based → A=0, Z=25, AA=26 …
        var s = '';
        var idx = n + 1;
        while (idx > 0) {
            idx--;
            s = String.fromCharCode(65 + (idx % 26)) + s;
            idx = Math.floor(idx / 26);
        }
        return s;
    }

    /** Convertit "A1" → {r:0, c:0}, "Z99" → {r:98, c:25} */
    function parseCellAddress(addr) {
        var m = addr.trim().toUpperCase().match(/^([A-Z]+)(\d+)$/);
        if (!m) return null;
        var col = 0;
        for (var i = 0; i < m[1].length; i++) {
            col = col * 26 + (m[1].charCodeAt(i) - 64);
        }
        col -= 1; // 0-based
        var row = parseInt(m[2], 10) - 1; // 0-based
        return { r: row, c: col };
    }

    /** Retourne la valeur numérique brute d'une cellule (après évaluation) */
    function getCellNumericValue(r, c, visited) {
        var key = cellKey(r, c);
        var cd  = state.cells[key];
        if (!cd || cd.value === undefined || cd.value === null || cd.value === '') return 0;
        var raw = String(cd.value);
        if (raw.charAt(0) === '=') {
            var res = evaluateFormula(raw.slice(1), visited || {});
            return isNaN(res) ? 0 : Number(res);
        }
        return isNaN(Number(raw)) ? 0 : Number(raw);
    }

    /* ------------------------------------------------------------------ */
    /* Évaluation de formules                                              */
    /* ------------------------------------------------------------------ */

    /**
     * Évalue une expression de formule (sans le '=' initial).
     * Supporte :
     *   SUM(A1:B3), AVG(A1:A5), MIN(...), MAX(...), COUNT(...)
     *   Références de cellules : A1, B2 …
     *   Opérateurs : + - * / ^ ( )
     *   Constantes numériques
     */
    function evaluateFormula(expr, visited) {
        if (!visited) visited = {};
        expr = expr.trim().toUpperCase();

        // Traiter les fonctions en premier (SUM, AVG, etc.)
        // Remplace récursivement toutes les occurrences de fonction dans l'expression
        // pour gérer les cas comme =SUM(A1:A3)+SUM(B1:B3)
        var funcRe = /(SUM|AVG|AVERAGE|MIN|MAX|COUNT)\(([^)]+)\)/g;
        var hasFunc = funcRe.test(expr);
        if (hasFunc) {
            var resolved0 = expr.replace(/(SUM|AVG|AVERAGE|MIN|MAX|COUNT)\(([^)]+)\)/g, function(fullMatch, fn, args) {
                args = args.trim();
                var vals;
                // Plage A1:B3
                if (/^[A-Z]+\d+:[A-Z]+\d+$/.test(args)) {
                    vals = getRangeValues(args, visited);
                } else {
                    // Liste A1,B2,3
                    var parts = args.split(',');
                    vals = [];
                    for (var pi = 0; pi < parts.length; pi++) {
                        var p = parts[pi].trim();
                        // Sous-plage dans la liste
                        if (/^[A-Z]+\d+:[A-Z]+\d+$/.test(p)) {
                            vals = vals.concat(getRangeValues(p, visited));
                        } else {
                            var pa = parseCellAddress(p);
                            if (pa) vals.push(getCellNumericValue(pa.r, pa.c, visited));
                            else    vals.push(isNaN(Number(p)) ? 0 : Number(p));
                        }
                    }
                }
                if (!vals.length) return '0';
                switch (fn) {
                    case 'SUM':     return String(vals.reduce(function(a,b){return a+b;},0));
                    case 'AVG':
                    case 'AVERAGE': return String(vals.reduce(function(a,b){return a+b;},0) / vals.length);
                    case 'MIN':     return String(Math.min.apply(null,vals));
                    case 'MAX':     return String(Math.max.apply(null,vals));
                    case 'COUNT':   return String(vals.length);
                    default:        return '0';
                }
            });
            // Après remplacement des fonctions, résoudre les refs restantes et évaluer
            expr = resolved0;
        }

        // Remplacer les références de cellules restantes par leurs valeurs
        var resolved = expr.replace(/([A-Z]+\d+)/g, function(match) {
            var addr = parseCellAddress(match);
            if (!addr) return '0';
            var vKey = cellKey(addr.r, addr.c);
            if (visited[vKey]) return '0'; // référence circulaire
            var childVisited = {};
            var k2;
            for (k2 in visited) { if (visited.hasOwnProperty(k2)) childVisited[k2] = true; }
            childVisited[vKey] = true;
            var n = getCellNumericValue(addr.r, addr.c, childVisited);
            return String(isNaN(n) ? 0 : n);
        });

        // Évaluation sécurisée de l'expression arithmétique
        try {
            var result = safeEval(resolved);
            return result;
        } catch(e) {
            return '#ERR';
        }
    }

    /** Évalue une expression arithmétique — uniquement chiffres et opérateurs */
    function safeEval(expr) {
        expr = expr.replace(/\s/g,'');
        if (expr === '' || expr === undefined) return 0;
        // Remplacer ^ par ** (puissance)
        expr = expr.replace(/\^/g, '**');
        // Validation stricte : chiffres, opérateurs, parens, point, e/E (notation scientifique)
        // On autorise aussi le signe négatif unaire
        if (!/^[-+]?(\d+\.?\d*([eE][-+]?\d+)?|\.\d+)([+\-*/](\d+\.?\d*([eE][-+]?\d+)?|\.\d+)|\*\*(\d+\.?\d*([eE][-+]?\d+)?|\.\d+)|\([-+.\d\seE*/]+\))*$/.test(expr)) {
            // Validation légère si la stricte échoue (expressions avec parenthèses imbriquées)
            if (!/^[0-9+\-*/.^()\seE]+$/.test(expr)) return '#ERR';
        }
        try {
            // eslint-disable-next-line no-new-func
            var result = Function('"use strict"; return (' + expr + ')')();
            if (typeof result === 'number' && isFinite(result)) return result;
            if (result === Infinity || result === -Infinity) return '#DIV0';
            return '#ERR';
        } catch(e) {
            return '#ERR';
        }
    }

    /** Retourne toutes les valeurs numériques d'une plage "A1:C3" */
    function getRangeValues(rangeStr, visited) {
        var parts = rangeStr.split(':');
        if (parts.length !== 2) return [];
        var from = parseCellAddress(parts[0]);
        var to   = parseCellAddress(parts[1]);
        if (!from || !to) return [];
        var vals = [];
        var rMin = Math.min(from.r, to.r), rMax = Math.max(from.r, to.r);
        var cMin = Math.min(from.c, to.c), cMax = Math.max(from.c, to.c);
        for (var r = rMin; r <= rMax; r++) {
            for (var c = cMin; c <= cMax; c++) {
                vals.push(getCellNumericValue(r, c, visited));
            }
        }
        return vals;
    }

    /** Retourne la valeur affichée d'une cellule (formule évaluée ou valeur brute) */
    function getCellDisplayValue(key) {
        var cd = state.cells[key];
        if (!cd || cd.value === undefined) return '';
        var raw = String(cd.value);
        if (raw.charAt(0) === '=') {
            var initVisited = {};
            initVisited[key] = true;
            var res = evaluateFormula(raw.slice(1), initVisited);
            if (res === '#ERR' || res === undefined || res === null) return '#ERR';
            // Arrondir les flottants
            var num = Number(res);
            if (!isNaN(num)) {
                return parseFloat(num.toFixed(10)).toString();
            }
            return String(res);
        }
        return raw;
    }

    /* ------------------------------------------------------------------ */
    /* Construction du tableau                                             */
    /* ------------------------------------------------------------------ */

    function buildTable() {
        if (!container) return;
        container.innerHTML = '';

        var wrapper = document.createElement('div');
        wrapper.className = 'ss-scroll-wrapper';

        tableEl = document.createElement('table');
        tableEl.className = 'spreadsheet-table';
        tableEl.setAttribute('role','grid');

        // En-tête
        theadEl = document.createElement('thead');
        var headerRow = document.createElement('tr');
        var cornerTh = document.createElement('th');
        cornerTh.className = 'ss-corner';
        headerRow.appendChild(cornerTh);
        for (var c = 0; c < state.cols; c++) {
            var th = document.createElement('th');
            th.className = 'ss-col-header';
            th.textContent = colLabel(c);
            th.setAttribute('data-col', c);
            headerRow.appendChild(th);
        }
        theadEl.appendChild(headerRow);
        tableEl.appendChild(theadEl);

        // Corps
        tbodyEl = document.createElement('tbody');
        for (var r = 0; r < state.rows; r++) {
            tbodyEl.appendChild(buildRow(r));
        }
        tableEl.appendChild(tbodyEl);

        // Événements délégués sur tbody
        tbodyEl.addEventListener('focusin',   onCellFocus);
        tbodyEl.addEventListener('focusout',  onCellBlur);
        tbodyEl.addEventListener('input',     onCellInput);
        tbodyEl.addEventListener('keydown',   onCellKeydown);
        tbodyEl.addEventListener('mousedown', onCellMousedown);
        tbodyEl.addEventListener('mouseover', onCellMouseover);

        wrapper.appendChild(tableEl);
        container.appendChild(wrapper);
    }

    function buildRow(r) {
        var tr = document.createElement('tr');
        tr.setAttribute('data-row', r);
        var rowHeader = document.createElement('th');
        rowHeader.className = 'ss-row-header';
        rowHeader.textContent = r + 1;
        tr.appendChild(rowHeader);
        for (var c = 0; c < state.cols; c++) {
            tr.appendChild(buildCell(r, c));
        }
        return tr;
    }

    function buildCell(r, c) {
        var td  = document.createElement('td');
        var key = cellKey(r, c);
        var cd  = state.cells[key] || {};
        td.setAttribute('data-row', r);
        td.setAttribute('data-col', c);
        td.setAttribute('tabindex', '-1');
        td.setAttribute('role', 'gridcell');
        td.contentEditable = canEdit ? 'true' : 'false';
        td.spellcheck = false;
        td.className = 'ss-cell';

        var display = getCellDisplayValue(key);
        td.textContent = display;

        if (cd.bold)   td.style.fontWeight = 'bold';
        if (cd.italic) td.style.fontStyle  = 'italic';
        if (cd.align)  td.style.textAlign  = cd.align;
        if (cd.color)  td.style.color      = cd.color;
        if (cd.bg)     td.style.background = cd.bg;

        // Indicateur de formule
        if (cd.value && String(cd.value).charAt(0) === '=') {
            td.classList.add('has-formula');
        }

        return td;
    }

    function refreshCell(r, c) {
        if (!tbodyEl) return;
        var existing = getCellTd(r, c);
        if (!existing) return;
        var newTd = buildCell(r, c);
        // Conserver le focus si c'était la cellule active
        var hadFocus = (document.activeElement === existing);
        existing.parentNode.replaceChild(newTd, existing);
        if (hadFocus) newTd.focus();
    }

    function getCellTd(r, c) {
        if (!tbodyEl) return null;
        return tbodyEl.querySelector('td[data-row="' + r + '"][data-col="' + c + '"]');
    }

    /* ------------------------------------------------------------------ */
    /* Événements                                                          */
    /* ------------------------------------------------------------------ */

    function getTdFromEvent(e) {
        var el = e.target;
        while (el && el.tagName !== 'TD') el = el.parentElement;
        return (el && el.tagName === 'TD') ? el : null;
    }

    function onCellFocus(e) {
        var td = getTdFromEvent(e);
        if (!td) return;
        selectedCell = td;
        var r = parseInt(td.getAttribute('data-row'));
        var c = parseInt(td.getAttribute('data-col'));
        if (cellRefEl) cellRefEl.textContent = colLabel(c) + (r + 1);

        // Afficher la formule brute dans la barre de formule
        if (formulaBarEl) {
            var key = cellKey(r, c);
            var cd  = state.cells[key];
            formulaBarEl.value = (cd && cd.value !== undefined) ? cd.value : '';
        }
        // Afficher la valeur brute (formule) dans la cellule lors de l'édition
        var key = cellKey(r, c);
        var cd  = state.cells[key];
        if (cd && cd.value && String(cd.value).charAt(0) === '=') {
            td.textContent = cd.value;
        }

        // Highlight colonne/ligne
        updateAxisHighlight(r, c);

        if (window.EDITOR_send) {
            window.EDITOR_send({ type: 'cursor_cell', row: r, col: c });
        }
    }

    function onCellBlur(e) {
        var td = getTdFromEvent(e);
        if (!td) return;
        saveCell(td);
        // Re-afficher la valeur calculée
        var r = parseInt(td.getAttribute('data-row'));
        var c = parseInt(td.getAttribute('data-col'));
        var key = cellKey(r, c);
        td.textContent = getCellDisplayValue(key);
        // Mettre à jour les cellules dépendantes
        refreshDependents(r, c);
        if (formulaBarEl) formulaBarEl.value = '';
        clearAxisHighlight();
    }

    function onCellInput(e) {
        var td = getTdFromEvent(e);
        if (!td) return;
        // Sync barre de formule
        if (formulaBarEl) formulaBarEl.value = td.textContent;

        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(function () {
            saveCell(td);
            if (window.EDITOR_send && window.EDITOR_getContent) {
                window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
            }
        }, 400);
    }

    function onCellKeydown(e) {
        var td = getTdFromEvent(e);
        if (!td) return;
        var r = parseInt(td.getAttribute('data-row'));
        var c = parseInt(td.getAttribute('data-col'));

        switch (e.key) {
            case 'Tab':
                e.preventDefault();
                if (e.shiftKey) { if (c > 0) focusCell(r, c-1); }
                else            { if (c < state.cols-1) focusCell(r, c+1); else if (r < state.rows-1) focusCell(r+1, 0); }
                break;
            case 'Enter':
                e.preventDefault();
                if (r < state.rows-1) focusCell(r+1, c);
                break;
            case 'Escape':
                td.blur();
                break;
            case 'ArrowUp':
                if (!isComposing(td)) { e.preventDefault(); if (r > 0) focusCell(r-1, c); }
                break;
            case 'ArrowDown':
                if (!isComposing(td)) { e.preventDefault(); if (r < state.rows-1) focusCell(r+1, c); }
                break;
            case 'ArrowLeft':
                if (!isComposing(td) && isCaretAtStart(td)) { e.preventDefault(); if (c > 0) focusCell(r, c-1); }
                break;
            case 'ArrowRight':
                if (!isComposing(td) && isCaretAtEnd(td)) { e.preventDefault(); if (c < state.cols-1) focusCell(r, c+1); }
                break;
            case 'Delete':
            case 'Backspace':
                // Si la cellule est vide et Backspace → aller à gauche
                if (e.key === 'Backspace' && td.textContent === '' && c > 0) {
                    e.preventDefault();
                    focusCell(r, c-1);
                }
                break;
        }

        // Raccourcis formatage
        if (e.ctrlKey || e.metaKey) {
            if (e.key === 'b') { e.preventDefault(); applyBold(); }
            if (e.key === 'i') { e.preventDefault(); applyItalic(); }
            if (e.key === 'z') { /* undo TODO */ }
        }
    }

    function onCellMousedown(e) {
        var td = getTdFromEvent(e);
        if (!td) return;
        if (e.shiftKey && selectedCell) {
            e.preventDefault();
            isSelectingRange = true;
            rangeStart = {
                r: parseInt(selectedCell.getAttribute('data-row')),
                c: parseInt(selectedCell.getAttribute('data-col'))
            };
            updateRangeSelection(parseInt(td.getAttribute('data-row')), parseInt(td.getAttribute('data-col')));
        } else {
            clearRangeSelection();
            isSelectingRange = false;
        }
    }

    function onCellMouseover(e) {
        if (!isSelectingRange || !rangeStart) return;
        var td = getTdFromEvent(e);
        if (!td) return;
        updateRangeSelection(parseInt(td.getAttribute('data-row')), parseInt(td.getAttribute('data-col')));
    }

    document.addEventListener('mouseup', function() { isSelectingRange = false; });

    function updateRangeSelection(r2, c2) {
        clearRangeSelection();
        var r1 = rangeStart.r, c1 = rangeStart.c;
        var rMin = Math.min(r1,r2), rMax = Math.max(r1,r2);
        var cMin = Math.min(c1,c2), cMax = Math.max(c1,c2);
        selectedRange = [];
        for (var r = rMin; r <= rMax; r++) {
            for (var c = cMin; c <= cMax; c++) {
                selectedRange.push({r:r,c:c});
                var td2 = getCellTd(r,c);
                if (td2) td2.classList.add('ss-selected-range');
            }
        }
        // Afficher la référence de range dans cellRef
        if (cellRefEl && selectedRange.length > 1) {
            var topLeft = colLabel(cMin) + (rMin+1);
            var botRight = colLabel(cMax) + (rMax+1);
            cellRefEl.textContent = topLeft + ':' + botRight;
        }
    }

    function clearRangeSelection() {
        if (tbodyEl) tbodyEl.querySelectorAll('.ss-selected-range').forEach(function(el){ el.classList.remove('ss-selected-range'); });
        selectedRange = [];
    }

    /* ------------------------------------------------------------------ */
    /* Helpers focus / caret                                               */
    /* ------------------------------------------------------------------ */

    function isComposing(td) {
        // On suppose pas de composition IME active
        return false;
    }

    function isCaretAtStart(td) {
        var sel = window.getSelection();
        if (!sel || sel.rangeCount === 0) return true;
        var range = sel.getRangeAt(0);
        return range.startOffset === 0 && range.collapsed;
    }

    function isCaretAtEnd(td) {
        var sel = window.getSelection();
        if (!sel || sel.rangeCount === 0) return true;
        var range = sel.getRangeAt(0);
        var len = td.textContent.length;
        return range.endOffset >= len && range.collapsed;
    }

    function focusCell(r, c) {
        var td = getCellTd(r, c);
        if (!td) return;
        td.focus();
        // Placer le curseur en fin
        var range = document.createRange();
        var sel   = window.getSelection();
        range.selectNodeContents(td);
        range.collapse(false);
        sel.removeAllRanges();
        sel.addRange(range);
    }

    /* ------------------------------------------------------------------ */
    /* Surlignage axe                                                      */
    /* ------------------------------------------------------------------ */

    function updateAxisHighlight(r, c) {
        if (!tableEl) return;
        tableEl.querySelectorAll('.ss-axis-hl').forEach(function(el){ el.classList.remove('ss-axis-hl'); });
        // Header ligne
        var rowHdr = tbodyEl.querySelector('tr[data-row="' + r + '"] > th');
        if (rowHdr) rowHdr.classList.add('ss-axis-hl');
        // Header colonne
        var colHdr = theadEl.querySelector('th[data-col="' + c + '"]');
        if (colHdr) colHdr.classList.add('ss-axis-hl');
    }

    function clearAxisHighlight() {
        if (!tableEl) return;
        tableEl.querySelectorAll('.ss-axis-hl').forEach(function(el){ el.classList.remove('ss-axis-hl'); });
    }

    /* ------------------------------------------------------------------ */
    /* Sauvegarde / dépendances                                            */
    /* ------------------------------------------------------------------ */

    function saveCell(td) {
        var r   = parseInt(td.getAttribute('data-row'));
        var c   = parseInt(td.getAttribute('data-col'));
        var key = cellKey(r, c);
        var val = td.textContent.trim();
        if (val !== '') {
            if (!state.cells[key]) state.cells[key] = {};
            state.cells[key].value = val;
        } else {
            if (state.cells[key]) {
                delete state.cells[key].value;
                if (Object.keys(state.cells[key]).length === 0) delete state.cells[key];
            }
        }
        // Indicateur formule
        if (val && val.charAt(0) === '=') {
            td.classList.add('has-formula');
        } else {
            td.classList.remove('has-formula');
        }
    }

    /** Recalcule toutes les cellules contenant des formules */
    function refreshAllFormulas() {
        if (!tbodyEl) return;
        tbodyEl.querySelectorAll('td.ss-cell').forEach(function(td) {
            var r = parseInt(td.getAttribute('data-row'));
            var c = parseInt(td.getAttribute('data-col'));
            if (document.activeElement === td) return; // ne pas interrompre l'édition
            var key = cellKey(r, c);
            var cd  = state.cells[key];
            if (cd && cd.value && String(cd.value).charAt(0) === '=') {
                td.textContent = getCellDisplayValue(key);
            }
        });
    }

    /** Recalcule les cellules qui pourraient référencer la cellule modifiée */
    function refreshDependents(changedR, changedC) {
        var changedAddr = (colLabel(changedC) + (changedR+1)).toUpperCase();
        if (!tbodyEl) return;
        tbodyEl.querySelectorAll('td.ss-cell').forEach(function(td) {
            var r = parseInt(td.getAttribute('data-row'));
            var c = parseInt(td.getAttribute('data-col'));
            if (r === changedR && c === changedC) return;
            if (document.activeElement === td) return;
            var key = cellKey(r, c);
            var cd  = state.cells[key];
            if (!cd || !cd.value || String(cd.value).charAt(0) !== '=') return;
            // Vérifier si la formule référence changedAddr
            if (String(cd.value).toUpperCase().indexOf(changedAddr) !== -1) {
                td.textContent = getCellDisplayValue(key);
            }
        });
    }

    /* ------------------------------------------------------------------ */
    /* Toolbar                                                             */
    /* ------------------------------------------------------------------ */

    function applyFormat(prop, value, styleKey) {
        var targets = (selectedRange.length > 1) ? selectedRange : (selectedCell ? [{
            r: parseInt(selectedCell.getAttribute('data-row')),
            c: parseInt(selectedCell.getAttribute('data-col'))
        }] : []);
        targets.forEach(function(pos) {
            var key = cellKey(pos.r, pos.c);
            if (!state.cells[key]) state.cells[key] = {};
            state.cells[key][prop] = !state.cells[key][prop];
            var td2 = getCellTd(pos.r, pos.c);
            if (td2) td2.style[styleKey] = state.cells[key][prop] ? value : '';
        });
        sendUpdate();
        if (selectedCell) selectedCell.focus();
    }

    function applyBold()   { applyFormat('bold',   'bold',   'fontWeight'); }
    function applyItalic() { applyFormat('italic', 'italic', 'fontStyle');  }

    function applyAlign(align) {
        var targets = (selectedRange.length > 1) ? selectedRange : (selectedCell ? [{
            r: parseInt(selectedCell.getAttribute('data-row')),
            c: parseInt(selectedCell.getAttribute('data-col'))
        }] : []);
        targets.forEach(function(pos) {
            var key = cellKey(pos.r, pos.c);
            if (!state.cells[key]) state.cells[key] = {};
            state.cells[key].align = align;
            var td2 = getCellTd(pos.r, pos.c);
            if (td2) td2.style.textAlign = align;
        });
        sendUpdate();
        if (selectedCell) selectedCell.focus();
    }

    // Liaison boutons toolbar
    function bindToolbar() {
        var boldBtn   = document.getElementById('ssFormatBold');
        var italicBtn = document.getElementById('ssFormatItalic');
        var alignL    = document.getElementById('ssAlignLeft');
        var alignC    = document.getElementById('ssAlignCenter');
        var alignR    = document.getElementById('ssAlignRight');
        var clearBtn  = document.getElementById('ssClearCell');

        if (boldBtn)   boldBtn.addEventListener('click',   applyBold);
        if (italicBtn) italicBtn.addEventListener('click', applyItalic);
        if (alignL)    alignL.addEventListener('click',    function(){ applyAlign('left'); });
        if (alignC)    alignC.addEventListener('click',    function(){ applyAlign('center'); });
        if (alignR)    alignR.addEventListener('click',    function(){ applyAlign('right'); });
        if (clearBtn)  clearBtn.addEventListener('click',  clearSelectedCells);

        // Barre de formule
        if (formulaBarEl) {
            formulaBarEl.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    if (selectedCell) {
                        selectedCell.textContent = formulaBarEl.value;
                        saveCell(selectedCell);
                        selectedCell.textContent = getCellDisplayValue(
                            cellKey(parseInt(selectedCell.getAttribute('data-row')),
                                    parseInt(selectedCell.getAttribute('data-col')))
                        );
                        refreshDependents(
                            parseInt(selectedCell.getAttribute('data-row')),
                            parseInt(selectedCell.getAttribute('data-col'))
                        );
                        selectedCell.focus();
                    }
                }
            });
            formulaBarEl.addEventListener('input', function() {
                if (selectedCell) {
                    selectedCell.textContent = formulaBarEl.value;
                }
            });
        }
    }

    function clearSelectedCells() {
        var targets = (selectedRange.length > 1) ? selectedRange : (selectedCell ? [{
            r: parseInt(selectedCell.getAttribute('data-row')),
            c: parseInt(selectedCell.getAttribute('data-col'))
        }] : []);
        targets.forEach(function(pos) {
            var key = cellKey(pos.r, pos.c);
            delete state.cells[key];
            var td2 = getCellTd(pos.r, pos.c);
            if (td2) {
                td2.textContent = '';
                td2.style.fontWeight = '';
                td2.style.fontStyle  = '';
                td2.style.textAlign  = '';
                td2.classList.remove('has-formula');
            }
        });
        refreshAllFormulas();
        sendUpdate();
    }

    function sendUpdate() {
        if (window.EDITOR_send && window.EDITOR_getContent) {
            window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
        }
    }

    /* ------------------------------------------------------------------ */
    /* Callbacks publics (interface avec editor.js)                        */
    /* ------------------------------------------------------------------ */

    window.EDITOR_getContent = function () {
        if (selectedCell) saveCell(selectedCell);
        return JSON.stringify({ rows: state.rows, cols: state.cols, cells: state.cells });
    };

    window.EDITOR_setContent = function (jsonStr) {
        if (!jsonStr) return;
        try {
            var obj = JSON.parse(jsonStr);
            if (obj && obj.cells !== undefined) {
                // Toujours utiliser les constantes maximales, jamais réduire
                state.rows  = TOTAL_ROWS;
                state.cols  = TOTAL_COLS;
                // Normalisation des clés : supporter "r,c" et "r:c"
                var norm = {};
                Object.keys(obj.cells || {}).forEach(function(k) {
                    norm[k.replace(',', ':')] = obj.cells[k];
                });
                state.cells = norm;
                buildTable();
                bindToolbar();
                // Rafraîchir les formules après chargement
                setTimeout(refreshAllFormulas, 0);
            }
        } catch(e) { console.error('[spreadsheet] setContent error:', e); }
    };

    window.EDITOR_showCursor = function (row, col, username) {
        if (!tbodyEl) return;
        tbodyEl.querySelectorAll('.collab-cursor[data-user="' + username + '"]')
               .forEach(function(el){ el.parentNode && el.parentNode.removeChild(el); });
        var td = getCellTd(row, col);
        if (!td) return;
        var badge = document.createElement('span');
        badge.className = 'collab-cursor';
        badge.setAttribute('data-user', username);
        badge.textContent = username.charAt(0).toUpperCase();
        badge.style.cssText = [
            'background:' + getUserColor(username),
            'position:absolute',
            'top:0',
            'right:0',
            'font-size:9px',
            'padding:1px 3px',
            'border-radius:2px',
            'color:#fff',
            'pointer-events:none',
            'z-index:10',
            'line-height:1.4'
        ].join(';');
        td.style.position = 'relative';
        td.appendChild(badge);
        setTimeout(function(){ if (badge.parentNode) badge.parentNode.removeChild(badge); }, 3000);
    };

    /* ------------------------------------------------------------------ */
    /* Initialisation                                                      */
    /* ------------------------------------------------------------------ */

    buildTable();
    bindToolbar();

})();
