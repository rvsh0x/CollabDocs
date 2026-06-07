<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="${doc.title} — CollabDocs" />
<%@ include file="layout/header.jsp" %>

<%-- Données injectées pour editor.js et les éditeurs spécialisés --%>
<script>
var COLLAB_CONFIG = {
    docId:    ${doc.id},
    docType:  '<c:out value="${doc.docType}"/>',
    canEdit:  ${canEdit},
    isOwner:  ${sessionScope.user != null && sessionScope.user.id == doc.ownerId},
    username: '<c:out value="${sessionScope.user != null ? sessionScope.user.username : 'Visiteur'}"/>',
    wsUrl:    (location.protocol === 'https:' ? 'wss://' : 'ws://')
              + location.host
              + '${pageContext.request.contextPath}/ws/doc/${doc.id}'
};

<%-- Données de présentation (si applicable) --%>
<c:if test="${doc.docType == 'PRESENTATION'}">
var PRESENTATION_DATA = null;
<c:if test="${not empty doc.content}">
try {
    PRESENTATION_DATA = <c:out value="${doc.content}" escapeXml="false"/>;
} catch(e) { PRESENTATION_DATA = null; }
</c:if>
window.DOCUMENT_ID = ${doc.id};
</c:if>
</script>

<div class="editor-page">

    <%-- ---- Barre d'outils ---- --%>
    <div class="editor-toolbar">
        <div class="toolbar-left">
            <a href="${pageContext.request.contextPath}/home" class="button is-small is-light mr-2">
                ← Retour
            </a>
            <input type="text" id="docTitle" class="input is-small title-input"
                   value="<c:out value='${doc.title}'/>"
                   <c:if test="${!canEdit}">readonly</c:if>
                   maxlength="200"
                   title="Cliquer pour modifier le titre">
            <span class="doc-type-badge badge-${doc.docType}">
                <c:choose>
                    <c:when test="${doc.docType == 'CODE'}">Code</c:when>
                    <c:when test="${doc.docType == 'PIXELART'}">Pixel Art</c:when>
                    <c:when test="${doc.docType == 'RICHTEXT'}">Texte riche</c:when>
                    <c:when test="${doc.docType == 'SPREADSHEET'}">Tableur</c:when>
                    <c:when test="${doc.docType == 'PRESENTATION'}">Présentation</c:when>
                    <c:when test="${doc.docType == 'PLANNING'}">Planning</c:when>
                    <c:when test="${doc.docType == 'MINDMAP'}">Mind Map</c:when>
                    <c:when test="${doc.docType == 'DIAGRAM'}">Diagramme</c:when>
                </c:choose>
            </span>
        </div>
        <div class="toolbar-center">
            <span id="userCount" class="tag is-dark mr-2">
                <span id="userCountNum">1</span> connecté(s)
            </span>
            <span id="connStatus" class="tag is-warning">Connexion...</span>
            <span id="saveStatus" class="tag is-light ml-2" style="display:none;"></span>
        </div>
        <div class="toolbar-right">
            <c:if test="${canEdit}">
                <button id="saveBtn" class="button is-primary is-small mr-2"
                        title="Sauvegarder (Ctrl+S)">
                    Sauvegarder
                </button>
            </c:if>
            <button id="historyBtn" class="button is-info is-small is-outlined mr-1"
                    title="Historique des versions">
                Versions
            </button>
            <%-- Badge demande de restauration (propriétaire seulement) --%>
            <c:choose>
                <c:when test="${sessionScope.user.id == doc.ownerId and not empty pendingRestore}">
                    <a id="restoreBadge"
                       href="${pageContext.request.contextPath}/document/restore/review?requestId=${pendingRestore[0]}"
                       class="button is-danger is-small mr-1"
                       title="Demande de restauration en attente">
                        ● Restauration
                    </a>
                </c:when>
                <c:when test="${sessionScope.user.id == doc.ownerId}">
                    <span id="restoreBadge" style="display:none;"></span>
                </c:when>
            </c:choose>
            <c:if test="${sessionScope.user.id == doc.ownerId}">
                <a href="${pageContext.request.contextPath}/document/share?id=${doc.id}"
                   class="button is-light is-small ml-1">
                    Partager
                </a>
            </c:if>
        </div>
    </div>

    <%-- ---- Corps principal ---- --%>
    <div class="editor-body">

        <%-- Zone d'édition — dispatcher par type (70%) --%>
        <div class="editor-pane" id="editorPane">
            <c:choose>
                <c:when test="${doc.docType == 'CODE'}">
                    <jsp:include page="editors/editor-code.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'PIXELART'}">
                    <jsp:include page="editors/editor-pixelart.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'RICHTEXT'}">
                    <jsp:include page="editors/editor-richtext.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'SPREADSHEET'}">
                    <jsp:include page="editors/editor-spreadsheet.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'PRESENTATION'}">
                    <jsp:include page="editors/editor-presentation.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'PLANNING'}">
                    <jsp:include page="editors/editor-planning.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'MINDMAP'}">
                    <jsp:include page="editors/editor-mindmap.jsp"/>
                </c:when>
                <c:when test="${doc.docType == 'DIAGRAM'}">
                    <jsp:include page="editors/editor-diagram.jsp"/>
                </c:when>
                <c:otherwise>
                    <jsp:include page="editors/editor-code.jsp"/>
                </c:otherwise>
            </c:choose>
        </div>

        <%-- Panneau chat (30%) --%>
        <div class="chat-pane">
            <div class="chat-header">
                <strong>Chat</strong>
                <span class="tag is-light is-small ml-2" id="presenceList"></span>
            </div>

            <div class="chat-messages" id="chatMessages">
                <c:forEach var="msg" items="${messages}">
                    <div class="chat-msg">
                        <div class="chat-msg-header">
                            <span class="chat-user"><c:out value="${msg.username}"/></span>
                            <span class="chat-time">
                                <fmt:formatDate value="${msg.sentAt}" pattern="HH:mm"/>
                            </span>
                        </div>
                        <p class="chat-text"><c:out value="${msg.content}"/></p>
                    </div>
                </c:forEach>
            </div>

            <div class="chat-input">
                <form id="chatForm" autocomplete="off">
                    <div class="field has-addons">
                        <div class="control is-expanded">
                            <input class="input is-small" type="text" id="chatInput"
                                   placeholder="Message..." maxlength="500">
                        </div>
                        <div class="control">
                            <button class="button is-primary is-small" type="submit">
                                Envoyer
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>

    </div>

</div>

<%-- =========================================================
     Modal Historique des versions
========================================================= --%>
<div class="modal" id="historyModal">
    <div class="modal-background" onclick="closeHistory()"></div>
    <div class="modal-card">
        <header class="modal-card-head">
            <p class="modal-card-title">Historique des versions</p>
            <button class="delete" aria-label="close" onclick="closeHistory()"></button>
        </header>
        <section class="modal-card-body">
            <c:choose>
                <c:when test="${empty history}">
                    <p class="has-text-grey">Aucune version sauvegardée.</p>
                </c:when>
                <c:otherwise>
                    <table class="table is-fullwidth is-striped is-hoverable">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Sauvegardé par</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="h" items="${history}">
                                <tr>
                                    <td>
                                        <fmt:formatDate value="${h[1]}" pattern="dd/MM/yyyy HH:mm:ss"/>
                                    </td>
                                    <td><c:out value="${h[2]}"/></td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${sessionScope.user.id == doc.ownerId}">
                                                <button class="button is-warning is-small is-outlined"
                                                        onclick="restoreVersion(${h[0]})">
                                                    Restaurer
                                                </button>
                                            </c:when>
                                            <c:when test="${canEdit}">
                                                <form method="post"
                                                      action="${pageContext.request.contextPath}/document/restore"
                                                      style="display:inline;">
                                                    <input type="hidden" name="documentId" value="${doc.id}">
                                                    <input type="hidden" name="historyId" value="${h[0]}">
                                                    <button type="submit"
                                                            class="button is-info is-small is-outlined">
                                                        Demander restauration
                                                    </button>
                                                </form>
                                            </c:when>
                                        </c:choose>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:otherwise>
            </c:choose>
        </section>
        <footer class="modal-card-foot">
            <button class="button" onclick="closeHistory()">Fermer</button>
        </footer>
    </div>
</div>

<%-- Messages flash --%>
<c:if test="${not empty param.restored}">
    <script>window._flashMsg = {text:'Version restaurée avec succès.',cls:'is-success'};</script>
</c:if>
<c:if test="${not empty param.restoreRequested}">
    <script>window._flashMsg = {text:'Votre demande a été envoyée au propriétaire.',cls:'is-info'};</script>
</c:if>
<c:if test="${param.restoreError == 'pending'}">
    <script>window._flashMsg = {text:'Une demande de restauration est déjà en attente.',cls:'is-warning'};</script>
</c:if>

<%-- Données d'historique pour JS (restauration côté propriétaire) --%>
<%-- CORRECTION : utilisation de JSON sûr via EL sans escapeXml=false sur le contenu --%>
<script>
var HISTORY_DATA = [];
<c:forEach var="h" items="${history}" varStatus="loop">
(function(){
    var entry = { id: ${h[0]}, content: null };
    try {
        entry.content = <c:out value="${h[3]}" escapeXml="false"/>;
    } catch(e) {
        entry.content = '';
    }
    HISTORY_DATA.push(entry);
})();
</c:forEach>
</script>

<%-- Script principal (WS + chat + toolbar) — chargé en PREMIER --%>
<script src="${pageContext.request.contextPath}/js/editor.js"></script>

<%-- Script spécifique au type d'éditeur — chargé APRÈS editor.js --%>
<c:choose>
    <c:when test="${doc.docType == 'CODE'}">
        <script src="${pageContext.request.contextPath}/js/editor-code.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'PIXELART'}">
        <script src="${pageContext.request.contextPath}/js/editor-pixelart.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'RICHTEXT'}">
        <script src="${pageContext.request.contextPath}/js/editor-richtext.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'SPREADSHEET'}">
        <script src="${pageContext.request.contextPath}/js/editor-spreadsheet.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'PRESENTATION'}">
        <%-- Le moteur est inline dans editor-presentation.jsp ;
             editor-presentation.js fournit uniquement les hooks EDITOR_* --%>
        <script src="${pageContext.request.contextPath}/js/editor-presentation.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'PLANNING'}">
        <script src="${pageContext.request.contextPath}/js/editor-planning.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'MINDMAP'}">
        <script src="${pageContext.request.contextPath}/js/editor-mindmap.js"></script>
    </c:when>
    <c:when test="${doc.docType == 'DIAGRAM'}">
        <%-- Le moteur est inline dans editor-diagram.jsp ;
             editor-diagram.js fournit uniquement les hooks EDITOR_* --%>
        <script src="${pageContext.request.contextPath}/js/editor-diagram.js"></script>
    </c:when>
    <c:otherwise>
        <script src="${pageContext.request.contextPath}/js/editor-code.js"></script>
    </c:otherwise>
</c:choose>

<%@ include file="layout/footer.jsp" %>
