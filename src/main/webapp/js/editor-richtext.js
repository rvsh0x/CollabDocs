/**
 * editor-richtext.js — Éditeur RICHTEXT (Quill.js) — CORRIGÉ
 * Quill est déjà chargé via CDN dans editor-richtext.jsp.
 */

(function () {
    'use strict';

    var isRemoteUpdate = false;
    var debounceTimer  = null;

    var quillContainer = document.getElementById('quillEditor');
    if (!quillContainer) return;

    // Attendre que Quill soit disponible (chargé via CDN dans le JSP)
    if (typeof Quill === 'undefined') {
        console.error('[RichText] Quill.js non chargé.');
        return;
    }

    var canEdit = !RICHTEXT_READONLY;

    var toolbarOptions = RICHTEXT_READONLY ? false : [
        [{ 'header': [1, 2, 3, false] }],
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'list': 'ordered' }, { 'list': 'bullet' }],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'align': [] }],
        ['link', 'blockquote', 'code-block'],
        ['clean']
    ];

    var quill = new Quill(quillContainer, {
        theme:    'snow',
        readOnly: RICHTEXT_READONLY,
        modules:  { toolbar: toolbarOptions }
    });

    // ------------------------------------------------------------------
    // Callbacks
    // ------------------------------------------------------------------

    window.EDITOR_getContent = function () {
        return JSON.stringify({ delta: quill.getContents() });
    };

    window.EDITOR_setContent = function (jsonStr) {
        if (isRemoteUpdate) return;
        if (!jsonStr) return;
        try {
            var obj = JSON.parse(jsonStr);
            if (obj && obj.delta) {
                isRemoteUpdate = true;
                var sel = quill.getSelection();
                quill.setContents(obj.delta, 'silent');
                if (sel) {
                    try { quill.setSelection(sel, 'silent'); } catch(e) {}
                }
                isRemoteUpdate = false;
            } else if (typeof jsonStr === 'string') {
                // Texte brut fallback
                isRemoteUpdate = true;
                quill.setText(jsonStr, 'silent');
                isRemoteUpdate = false;
            }
        } catch (e) {
            isRemoteUpdate = false;
        }
    };

    // ------------------------------------------------------------------
    // Envoi debounce
    // ------------------------------------------------------------------

    if (!RICHTEXT_READONLY) {
        quill.on('text-change', function (delta, oldDelta, source) {
            if (source !== 'user') return;
            if (isRemoteUpdate) return;
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(function () {
                window.EDITOR_send({
                    type:    'content_update',
                    content: window.EDITOR_getContent()
                });
            }, 300);
        });
    }

})();
