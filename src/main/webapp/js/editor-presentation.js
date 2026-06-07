/**
 * editor-presentation.js — Pont EDITOR API ↔ PresentationEditor inline (CORRIGÉ)
 *
 * Le moteur complet de présentation est intégré directement dans editor-presentation.jsp.
 * Ce fichier fournit uniquement les hooks EDITOR_getContent / EDITOR_setContent
 * pour l'intégration avec editor.js (WebSocket, sauvegarde, historique).
 *
 * Il est chargé APRÈS editor-presentation.jsp, donc PresentationEditor est déjà disponible.
 */

(function () {
    'use strict';

    function waitForPresentationEditor(cb, attempts) {
        if (typeof window.PresentationEditor !== 'undefined') {
            cb();
        } else if ((attempts || 0) < 50) {
            setTimeout(function () { waitForPresentationEditor(cb, (attempts || 0) + 1); }, 100);
        }
    }

    waitForPresentationEditor(function () {
        // EDITOR_getContent : sérialise les slides
        window.EDITOR_getContent = function () {
            try {
                var slides = window.PresentationEditor.getSlides();
                return JSON.stringify({ slides: slides });
            } catch (e) {
                return JSON.stringify({ slides: [] });
            }
        };

        // EDITOR_setContent : charge des slides depuis le JSON serveur
        window.EDITOR_setContent = function (jsonStr) {
            if (!jsonStr) return;
            try {
                var obj = JSON.parse(jsonStr);
                if (obj && obj.slides && Array.isArray(obj.slides) && obj.slides.length > 0) {
                    // Injecter dans l'état interne de PresentationEditor
                    var state = window.PresentationEditor.getState();
                    state.slides = obj.slides;
                    state.currentSlide = 0;
                    state.selectedIds  = [];
                    // Forcer le re-rendu complet
                    if (typeof state.history !== 'undefined') {
                        state.history = [JSON.parse(JSON.stringify(obj.slides))];
                        state.historyPos = 0;
                    }
                    // Appeler renderAll via les fonctions exposées
                    window.PresentationEditor.switchSlide(0);
                }
            } catch (e) { /* ignore */ }
        };

        // Navigation slide distante (collaboration)
        window.EDITOR_goToSlide = function (idx) {
            try {
                window.PresentationEditor.switchSlide(idx);
            } catch (e) {}
        };
    });

})();
