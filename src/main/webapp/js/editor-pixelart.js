/**
 * editor-pixelart.js — Éditeur PIXELART (canvas HTML5)
 * Optimisation : pixel_update (1 pixel) pour la collaboration,
 * content_update (grille entière) uniquement à la sauvegarde.
 */

(function () {
    'use strict';

    var canvas    = document.getElementById('pixelCanvas');
    var palEl     = document.getElementById('palette');
    var sizeSel   = document.getElementById('gridSizeSelector');
    var clearBtn  = document.getElementById('clearCanvas');
    var toolPen   = document.getElementById('toolPen');
    var toolErase = document.getElementById('toolEraser');
    var toolFill  = document.getElementById('toolFill');

    if (!canvas) return;

    // ------------------------------------------------------------------
    // État
    // ------------------------------------------------------------------

    var state = {
        width:   32,
        height:  32,
        palette: ['#ffffff','#000000','#ff0000','#00cc00','#0000ff',
                  '#ffff00','#ff8800','#ff00ff','#00ffff','#aaaaaa'],
        pixels:  []
    };

    var currentColor = 1; // index dans palette
    var activeTool   = 'pen'; // pen | eraser | fill
    var isDrawing    = false;
    var cellSize     = 16;

    function initPixels() {
        state.pixels = [];
        for (var r = 0; r < state.height; r++) {
            var row = [];
            for (var c = 0; c < state.width; c++) row.push(0);
            state.pixels.push(row);
        }
    }

    // ------------------------------------------------------------------
    // Rendu palette
    // ------------------------------------------------------------------

    function renderPalette() {
        if (!palEl) return;
        palEl.innerHTML = '';
        state.palette.forEach(function (color, idx) {
            var swatch = document.createElement('div');
            swatch.className = 'palette-swatch' + (idx === currentColor ? ' active' : '');
            swatch.style.background = color;
            swatch.title = color;
            swatch.addEventListener('click', function () {
                currentColor = idx;
                palEl.querySelectorAll('.palette-swatch').forEach(function(s,i) {
                    s.classList.toggle('active', i === idx);
                });
            });
            palEl.appendChild(swatch);
        });
    }

    // ------------------------------------------------------------------
    // Rendu canvas
    // ------------------------------------------------------------------

    function resizeCanvas() {
        var wrapper = canvas.parentElement;
        var maxW = wrapper ? wrapper.clientWidth - 20 : 600;
        cellSize = Math.max(4, Math.floor(Math.min(maxW, 600) / state.width));
        canvas.width  = cellSize * state.width;
        canvas.height = cellSize * state.height;
    }

    function renderFull() {
        resizeCanvas();
        var ctx = canvas.getContext('2d');
        for (var r = 0; r < state.height; r++) {
            for (var c = 0; c < state.width; c++) {
                var idx = state.pixels[r] ? state.pixels[r][c] || 0 : 0;
                ctx.fillStyle = state.palette[idx] || '#ffffff';
                ctx.fillRect(c * cellSize, r * cellSize, cellSize, cellSize);
            }
        }
        // Grille légère
        ctx.strokeStyle = 'rgba(0,0,0,0.08)';
        ctx.lineWidth = 0.5;
        for (var x = 0; x <= state.width; x++) {
            ctx.beginPath(); ctx.moveTo(x*cellSize,0); ctx.lineTo(x*cellSize, canvas.height); ctx.stroke();
        }
        for (var y = 0; y <= state.height; y++) {
            ctx.beginPath(); ctx.moveTo(0,y*cellSize); ctx.lineTo(canvas.width, y*cellSize); ctx.stroke();
        }
    }

    function renderPixel(r, c) {
        var ctx = canvas.getContext('2d');
        var idx = state.pixels[r] ? state.pixels[r][c] || 0 : 0;
        ctx.fillStyle = state.palette[idx] || '#ffffff';
        ctx.fillRect(c * cellSize, r * cellSize, cellSize, cellSize);
        ctx.strokeStyle = 'rgba(0,0,0,0.08)';
        ctx.lineWidth = 0.5;
        ctx.strokeRect(c * cellSize, r * cellSize, cellSize, cellSize);
    }

    // ------------------------------------------------------------------
    // Événements canvas
    // ------------------------------------------------------------------

    function getCell(e) {
        var rect = canvas.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        return {
            r: Math.floor(y / cellSize),
            c: Math.floor(x / cellSize)
        };
    }

    function applyTool(r, c) {
        if (r < 0 || r >= state.height || c < 0 || c >= state.width) return;
        if (activeTool === 'fill') {
            floodFill(r, c, state.pixels[r][c], currentColor);
            renderFull();
            window.EDITOR_send({
                type:    'content_update',
                content: window.EDITOR_getContent()
            });
            return;
        }
        var colorIdx = activeTool === 'eraser' ? 0 : currentColor;
        if (state.pixels[r][c] === colorIdx) return;
        state.pixels[r][c] = colorIdx;
        renderPixel(r, c);
        // Envoyer pixel_update (optimisé, pas de sauvegarde DB)
        window.EDITOR_send({ type: 'pixel_update', x: c, y: r, colorIndex: colorIdx });
    }

    function floodFill(r, c, targetColor, fillColor) {
        if (targetColor === fillColor) return;
        if (r < 0 || r >= state.height || c < 0 || c >= state.width) return;
        if (state.pixels[r][c] !== targetColor) return;
        state.pixels[r][c] = fillColor;
        floodFill(r-1, c, targetColor, fillColor);
        floodFill(r+1, c, targetColor, fillColor);
        floodFill(r, c-1, targetColor, fillColor);
        floodFill(r, c+1, targetColor, fillColor);
    }

    if (COLLAB_CONFIG.canEdit) {
        canvas.addEventListener('mousedown', function (e) {
            isDrawing = true;
            var cell = getCell(e);
            applyTool(cell.r, cell.c);
        });
        canvas.addEventListener('mousemove', function (e) {
            if (!isDrawing) return;
            var cell = getCell(e);
            applyTool(cell.r, cell.c);
        });
        canvas.addEventListener('mouseup',   function () { isDrawing = false; });
        canvas.addEventListener('mouseleave',function () { isDrawing = false; });

        // Touch support
        canvas.addEventListener('touchstart', function(e) {
            e.preventDefault();
            isDrawing = true;
            var cell = getCell(e.touches[0]);
            applyTool(cell.r, cell.c);
        });
        canvas.addEventListener('touchmove', function(e) {
            e.preventDefault();
            if (!isDrawing) return;
            var cell = getCell(e.touches[0]);
            applyTool(cell.r, cell.c);
        });
        canvas.addEventListener('touchend', function() { isDrawing = false; });
    }

    // ------------------------------------------------------------------
    // Outils
    // ------------------------------------------------------------------

    function setTool(t) {
        activeTool = t;
        [toolPen, toolErase, toolFill].forEach(function(btn) {
            if (btn) btn.classList.remove('is-primary');
        });
        var map = { pen: toolPen, eraser: toolErase, fill: toolFill };
        if (map[t]) map[t].classList.add('is-primary');
    }

    if (toolPen)   toolPen.addEventListener('click',   function() { setTool('pen'); });
    if (toolErase) toolErase.addEventListener('click', function() { setTool('eraser'); });
    if (toolFill)  toolFill.addEventListener('click',  function() { setTool('fill'); });

    if (clearBtn) clearBtn.addEventListener('click', function () {
        initPixels();
        renderFull();
        window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
    });

    if (sizeSel) sizeSel.addEventListener('change', function () {
        var newSize = parseInt(sizeSel.value);
        if (isNaN(newSize) || newSize === state.width) return;

        var oldPixels = state.pixels;
        var oldW      = state.width;
        var oldH      = state.height;

        var newPixels = [];
        for (var r = 0; r < newSize; r++) {
            var row = [];
            for (var c = 0; c < newSize; c++) {
                if (r < oldH && c < oldW && oldPixels[r] !== undefined) {
                    row.push(oldPixels[r][c] !== undefined ? oldPixels[r][c] : 0);
                } else {
                    row.push(0);
                }
            }
            newPixels.push(row);
        }

        state.width  = newSize;
        state.height = newSize;
        state.pixels = newPixels;

        resizeCanvas();
        renderFull();
        window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
    });

    // ------------------------------------------------------------------
    // Callbacks
    // ------------------------------------------------------------------

    window.EDITOR_getContent = function () {
        return JSON.stringify({
            width:   state.width,
            height:  state.height,
            palette: state.palette,
            pixels:  state.pixels
        });
    };

    // FIX : synchroniser le <select> et sécuriser les bornes
    window.EDITOR_setContent = function (jsonStr) {
        try {
            var obj = JSON.parse(jsonStr);
            if (obj && obj.pixels) {
                state.width   = obj.width   || 32;
                state.height  = obj.height  || 32;
                state.palette = obj.palette || state.palette;
                state.pixels  = obj.pixels;

                // Mettre à jour le <select> chez les collaborateurs
                if (sizeSel) {
                    var found = false;
                    for (var i = 0; i < sizeSel.options.length; i++) {
                        if (parseInt(sizeSel.options[i].value) === state.width) {
                            sizeSel.selectedIndex = i;
                            found = true;
                            break;
                        }
                    }
                    // Taille non listée dans les options : l'ajouter dynamiquement
                    if (!found) {
                        var opt = document.createElement('option');
                        opt.value       = state.width;
                        opt.textContent = state.width + '\u00d7' + state.height;
                        sizeSel.appendChild(opt);
                        sizeSel.value   = String(state.width);
                    }
                }

                renderPalette();
                renderFull();
            }
        } catch (e) { /* ignore */ }
    };

    // FIX : ignorer les pixels hors grille (désync temporaire de taille)
    window.EDITOR_applyPixel = function (x, y, colorIndex) {
        if (y < 0 || y >= state.height || x < 0 || x >= state.width) return;
        if (!state.pixels[y]) return;
        state.pixels[y][x] = colorIndex;
        renderPixel(y, x);
    };

    // ------------------------------------------------------------------
    // Initialisation
    // ------------------------------------------------------------------

    initPixels();
    renderPalette();
    renderFull();
    window.addEventListener('resize', renderFull);

})();