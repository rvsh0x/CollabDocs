/**
 * editor.js — Logique WebSocket commune pour CollabDocs V2 (CORRIGÉ)
 *
 * Gère : connexion WS, chat, toolbar (titre, user count, statut, save),
 *        présence, notifications, historique.
 *
 * Délègue la gestion du contenu aux éditeurs spécialisés via des callbacks globaux :
 *   window.EDITOR_setContent(jsonString) — appelé à la réception du contenu
 *   window.EDITOR_getContent()           — appelé pour obtenir le contenu à sauvegarder
 *   window.EDITOR_send(msgObj)           — fourni par editor.js aux éditeurs spécialisés
 */

(function () {
    'use strict';

    // ---- Références DOM ----
    var chatMessages = document.getElementById('chatMessages');
    var chatInput    = document.getElementById('chatInput');
    var chatForm     = document.getElementById('chatForm');
    var saveBtn      = document.getElementById('saveBtn');
    var historyBtn   = document.getElementById('historyBtn');
    var titleInput   = document.getElementById('docTitle');
    var userCountEl  = document.getElementById('userCountNum');
    var connStatus   = document.getElementById('connStatus');
    var saveStatus   = document.getElementById('saveStatus');
    var historyModal = document.getElementById('historyModal');
    var restoreBadge = document.getElementById('restoreBadge');

    // ---- État interne ----
    var ws               = null;
    var reconnectTimer   = null;
    var connectTimeout   = null;
    var reconnectDelay   = 1000;
    var maxReconnectDelay = 30000;
    var presenceSet      = {};
    var wsCandidates     = buildWsCandidates();
    var wsCandidateIndex = 0;
    var isDestroyed      = false;

    // Exposer la fonction d'envoi aux éditeurs spécialisés
    window.EDITOR_send = function(obj) { send(obj); };

    // ====================================================================
    // CONNEXION WEBSOCKET
    // ====================================================================

    function connect() {
        if (isDestroyed) return;
        if (!wsCandidates || wsCandidates.length === 0) {
            setConnStatus('disconnected');
            return;
        }
        setConnStatus('connecting');
        var wsUrl = wsCandidates[wsCandidateIndex % wsCandidates.length];
        try {
            ws = new WebSocket(wsUrl);
        } catch (e) {
            setConnStatus('disconnected');
            scheduleReconnect();
            return;
        }

        clearTimeout(connectTimeout);
        connectTimeout = setTimeout(function () {
            if (ws && ws.readyState === WebSocket.CONNECTING) {
                try { ws.close(); } catch (e) {}
            }
        }, 6000);

        ws.onopen = function () {
            clearTimeout(connectTimeout);
            setConnStatus('connected');
            reconnectDelay = 1000;
            presenceSet = {};
            presenceSet[COLLAB_CONFIG.username] = true;
            updatePresence();
        };

        ws.onclose = function () {
            clearTimeout(connectTimeout);
            setConnStatus('disconnected');
            if (wsCandidates.length > 1) {
                wsCandidateIndex = (wsCandidateIndex + 1) % wsCandidates.length;
            }
            scheduleReconnect();
        };

        ws.onerror = function () {
            // L'erreur est gérée par onclose qui sera appelé après
        };

        ws.onmessage = function (event) {
            var msg;
            try { msg = JSON.parse(event.data); } catch (e) { return; }
            handleMessage(msg);
        };
    }

    function scheduleReconnect() {
        if (isDestroyed) return;
        clearTimeout(reconnectTimer);
        reconnectTimer = setTimeout(function () { connect(); }, reconnectDelay);
        reconnectDelay = Math.min(reconnectDelay * 2, maxReconnectDelay);
    }

    // ====================================================================
    // TRAITEMENT DES MESSAGES ENTRANTS
    // ====================================================================

    function handleMessage(msg) {
        switch (msg.type) {

            case 'init':
                if (msg.content !== undefined && msg.content !== null && window.EDITOR_setContent) {
                    window.EDITOR_setContent(msg.content);
                }
                updateUserCount(msg.count || 1);
                if (msg.users && Array.isArray(msg.users)) {
                    presenceSet = {};
                    msg.users.forEach(function(u) { presenceSet[u] = true; });
                    updatePresence();
                }
                break;

            case 'content_update':
                if (msg.sender !== COLLAB_CONFIG.username && window.EDITOR_setContent) {
                    window.EDITOR_setContent(msg.content);
                }
                break;

            case 'pixel_update':
                if (msg.sender !== COLLAB_CONFIG.username && window.EDITOR_applyPixel) {
                    window.EDITOR_applyPixel(msg.x, msg.y, msg.colorIndex);
                }
                break;

            case 'slide_change':
                if (msg.sender !== COLLAB_CONFIG.username && window.EDITOR_goToSlide) {
                    window.EDITOR_goToSlide(msg.slideIndex);
                }
                break;

            case 'cursor_cell':
                if (window.EDITOR_showCursor && msg.username !== COLLAB_CONFIG.username) {
                    window.EDITOR_showCursor(msg.row, msg.col, msg.username);
                }
                break;

            case 'chat_message':
                appendChatMessage(msg.username, msg.text, msg.time);
                break;

            case 'user_joined':
                presenceSet[msg.username] = true;
                updateUserCount(msg.count);
                updatePresence();
                appendSystemMessage(msg.username + ' a rejoint le document.');
                break;

            case 'user_left':
                delete presenceSet[msg.username];
                updateUserCount(msg.count);
                updatePresence();
                appendSystemMessage(msg.username + ' a quitté le document.');
                break;

            case 'saved':
                showSaveStatus('Sauvegardé à ' + formatTime(msg.timestamp));
                break;

            case 'title_update':
                if (titleInput && msg.sender !== COLLAB_CONFIG.username) {
                    titleInput.value = msg.title || '';
                    document.title = (msg.title || '') + ' — CollabDocs';
                }
                break;

            case 'force_restore':
                if (window.EDITOR_setContent) window.EDITOR_setContent(msg.content);
                showNotification('Version restaurée par ' + (msg.restoredBy || 'le propriétaire'), 'is-info');
                break;

            case 'restore_request':
                if (COLLAB_CONFIG.isOwner) {
                    showNotification('Demande de restauration de ' + msg.requestedBy, 'is-warning');
                    if (restoreBadge) {
                        restoreBadge.style.display = '';
                        var ctx = window.location.pathname.split('/').length > 2
                            ? '/' + window.location.pathname.split('/')[1] : '';
                        if (restoreBadge.tagName === 'A') {
                            restoreBadge.href = ctx + '/document/restore/review?requestId=' + msg.requestId;
                        }
                    }
                }
                break;

            case 'restore_approved':
                showNotification('Votre demande de restauration a été approuvée.', 'is-success');
                break;

            case 'restore_rejected':
                showNotification(msg.message || 'Votre demande de restauration a été refusée.', 'is-danger');
                break;

            case 'error':
                showNotification(msg.message || 'Une erreur est survenue.', 'is-danger');
                break;

            default:
                break;
        }
    }

    // ====================================================================
    // ENVOI DE MESSAGES
    // ====================================================================

    function send(obj) {
        if (ws && ws.readyState === WebSocket.OPEN) {
            try {
                ws.send(JSON.stringify(obj));
            } catch (e) {
                showNotification('Erreur lors de l\'envoi du message.', 'is-warning');
            }
        } else {
            // Mise en file d'attente silencieuse — ne pas spammer l'utilisateur
        }
    }

    // ---- Titre modifiable ----
    if (titleInput && COLLAB_CONFIG.canEdit) {
        var titleDebounce = null;
        titleInput.addEventListener('input', function () {
            clearTimeout(titleDebounce);
            titleDebounce = setTimeout(function () {
                send({ type: 'title_update', title: titleInput.value });
                document.title = titleInput.value + ' — CollabDocs';
            }, 500);
        });
    }

    // ---- Bouton Sauvegarder ----
    if (saveBtn) {
        saveBtn.addEventListener('click', function () {
            doSave();
        });
    }

    function doSave() {
        var content = window.EDITOR_getContent ? window.EDITOR_getContent() : '';
        send({ type: 'save_request', content: content });
        showSaveStatus('Sauvegarde en cours...');
    }

    // Raccourci clavier Ctrl+S / Cmd+S
    document.addEventListener('keydown', function (e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (COLLAB_CONFIG.canEdit) {
                doSave();
            }
        }
    });

    // ---- Chat ----
    if (chatForm) {
        chatForm.addEventListener('submit', function (e) {
            e.preventDefault();
            var text = chatInput.value.trim();
            if (!text) return;
            send({ type: 'chat_message', text: text });
            chatInput.value = '';
            chatInput.focus();
        });
    }

    // ---- Historique ----
    if (historyBtn) {
        historyBtn.addEventListener('click', function () { window.openHistory(); });
    }

    // ====================================================================
    // GESTION DU CHAT
    // ====================================================================

    function appendChatMessage(username, text, time) {
        if (!chatMessages) return;
        var div    = document.createElement('div');
        div.className = 'chat-msg' + (username === COLLAB_CONFIG.username ? ' own-msg' : '');

        var header = document.createElement('div');
        header.className = 'chat-msg-header';

        var userSpan = document.createElement('span');
        userSpan.className = 'chat-user';
        userSpan.textContent = username;

        var timeSpan = document.createElement('span');
        timeSpan.className = 'chat-time';
        timeSpan.textContent = time || '';

        header.appendChild(userSpan);
        header.appendChild(timeSpan);

        var p = document.createElement('p');
        p.className = 'chat-text';
        p.textContent = text;

        div.appendChild(header);
        div.appendChild(p);
        chatMessages.appendChild(div);
        scrollChatToBottom();
    }

    function appendSystemMessage(text) {
        if (!chatMessages) return;
        var div = document.createElement('div');
        div.className = 'chat-system';
        div.textContent = text;
        chatMessages.appendChild(div);
        scrollChatToBottom();
    }

    function scrollChatToBottom() {
        if (chatMessages) chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    window.addEventListener('load', scrollChatToBottom);

    // ====================================================================
    // PRÉSENCE ET COMPTEUR
    // ====================================================================

    function updateUserCount(count) {
        if (userCountEl) userCountEl.textContent = count || 1;
    }

    function updatePresence() {
        var el = document.getElementById('presenceList');
        if (!el) return;
        el.textContent = Object.keys(presenceSet).join(', ');
    }

    // ====================================================================
    // STATUT DE CONNEXION
    // ====================================================================

    function setConnStatus(state) {
        if (!connStatus) return;
        connStatus.className = 'tag';
        switch (state) {
            case 'connected':
                connStatus.textContent = 'Connecté';
                connStatus.classList.add('is-success');
                break;
            case 'disconnected':
                connStatus.textContent = 'Déconnecté — reconnexion...';
                connStatus.classList.add('is-danger');
                break;
            case 'connecting':
                connStatus.textContent = 'Connexion...';
                connStatus.classList.add('is-warning');
                break;
        }
    }

    // ====================================================================
    // STATUT DE SAUVEGARDE
    // ====================================================================

    var saveStatusTimer = null;

    function showSaveStatus(message) {
        if (!saveStatus) return;
        saveStatus.textContent = message;
        saveStatus.className = 'tag is-success ml-2';
        saveStatus.style.display = '';
        clearTimeout(saveStatusTimer);
        saveStatusTimer = setTimeout(function () {
            saveStatus.style.display = 'none';
        }, 5000);
    }

    // ====================================================================
    // NOTIFICATIONS TOAST
    // ====================================================================

    function showNotification(message, cssClass) {
        var div = document.createElement('div');
        div.className = 'notification ' + (cssClass || 'is-info') + ' toast-notification';
        div.textContent = message;
        document.body.appendChild(div);
        setTimeout(function () { if (div.parentNode) div.parentNode.removeChild(div); }, 4000);
    }

    window.showEditorNotification = showNotification;

    // ====================================================================
    // MODAL HISTORIQUE
    // ====================================================================

    window.openHistory = function () {
        if (historyModal) historyModal.classList.add('is-active');
    };

    window.closeHistory = function () {
        if (historyModal) historyModal.classList.remove('is-active');
    };

    window.restoreVersion = function (histId) {
        var id = parseInt(histId, 10);
        if (!window.HISTORY_DATA || !Array.isArray(window.HISTORY_DATA)) {
            showNotification('Données d\'historique indisponibles.', 'is-warning');
            return;
        }
        var entry = null;
        for (var i = 0; i < window.HISTORY_DATA.length; i++) {
            if (window.HISTORY_DATA[i].id === id) { entry = window.HISTORY_DATA[i]; break; }
        }
        if (!entry) {
            showNotification('Version introuvable.', 'is-warning');
            return;
        }
        if (!confirm('Restaurer cette version ? Le contenu actuel sera remplacé.')) return;

        var contentToRestore = entry.content;
        if (window.EDITOR_setContent) window.EDITOR_setContent(contentToRestore);
        var currentContent = window.EDITOR_getContent ? window.EDITOR_getContent() : contentToRestore;
        send({ type: 'content_update', content: currentContent });
        send({ type: 'save_request',   content: currentContent });
        window.closeHistory();
        showNotification('Version restaurée.', 'is-success');
    };

    // ====================================================================
    // MESSAGE FLASH (query params)
    // ====================================================================

    window.addEventListener('DOMContentLoaded', function() {
        if (window._flashMsg) {
            showNotification(window._flashMsg.text, window._flashMsg.cls);
        }
        scrollChatToBottom();
    });

    // ====================================================================
    // HELPERS
    // ====================================================================

    function formatTime(ts) {
        if (!ts) return '';
        var d = new Date(ts.replace ? ts.replace(' ', 'T') : ts);
        if (isNaN(d.getTime())) return String(ts);
        return d.getHours().toString().padStart(2, '0') + ':'
             + d.getMinutes().toString().padStart(2, '0');
    }

    function buildWsCandidates() {
        var protocol = location.protocol === 'https:' ? 'wss://' : 'ws://';
        var host = location.host;
        var candidates = [];
        var seen = {};
        function add(url) {
            if (!url || seen[url]) return;
            seen[url] = true;
            candidates.push(url);
        }
        if (COLLAB_CONFIG && COLLAB_CONFIG.wsUrl) add(COLLAB_CONFIG.wsUrl);
        if (COLLAB_CONFIG && COLLAB_CONFIG.docId !== undefined) {
            add(protocol + host + '/ws/doc/' + COLLAB_CONFIG.docId);
            var parts = location.pathname.split('/').filter(Boolean);
            if (parts.length > 0) {
                add(protocol + host + '/' + parts[0] + '/ws/doc/' + COLLAB_CONFIG.docId);
            }
        }
        return candidates;
    }

    // ====================================================================
    // DÉMARRAGE
    // ====================================================================

    connect();

    // Nettoyage lors de la fermeture
    window.addEventListener('beforeunload', function() {
        isDestroyed = true;
        clearTimeout(reconnectTimer);
        clearTimeout(connectTimeout);
        if (ws) { try { ws.close(); } catch(e) {} }
    });

})();
