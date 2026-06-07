<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ page pageEncoding="UTF-8" %>
<c:set var="pageTitle" value="Mes documents — CollabDocs" />
<%@ include file="layout/header.jsp" %>


<section class="section">
    <div class="container">

        <div class="level">
            <div class="level-left">
                <div class="level-item">
                    <h1 class="title">Mes documents</h1>
                </div>
            </div>
            <div class="level-right">
                <div class="level-item">
                    <a href="${pageContext.request.contextPath}/document/new"
                       class="button is-primary">
                        + Nouveau document
                    </a>
                </div>
            </div>
        </div>

        <%-- ---- Filtres par type ---- --%>
        <div class="type-filter-bar mb-4" id="typeFilterBar">
            <button class="button is-small filter-btn is-info" data-filter="ALL">Tous</button>
            <button class="button is-small filter-btn" data-filter="CODE">Code</button>
            <button class="button is-small filter-btn" data-filter="PIXELART">Pixel Art</button>
            <button class="button is-small filter-btn" data-filter="RICHTEXT">Texte riche</button>
            <button class="button is-small filter-btn" data-filter="SPREADSHEET">Tableur</button>
            <button class="button is-small filter-btn" data-filter="PRESENTATION">Présentation</button>
            <button class="button is-small filter-btn" data-filter="PLANNING">Planning</button>
            <button class="button is-small filter-btn" data-filter="MINDMAP">Mind Map</button>
            <button class="button is-small filter-btn" data-filter="DIAGRAM">Diagramme</button>
        </div>

        <%-- =========================================================
             Documents dont l'utilisateur est propriétaire
        ========================================================= --%>
        <c:choose>
            <c:when test="${empty myDocs}">
                <div class="notification is-info is-light">
                    Vous n'avez aucun document pour l'instant.
                    <a href="${pageContext.request.contextPath}/document/new">Créez-en un !</a>
                </div>
            </c:when>
            <c:otherwise>
                <div class="table-container">
                    <table class="table is-fullwidth is-striped is-hoverable" id="myDocsTable">
                        <thead>
                            <tr>
                                <th>Titre</th>
                                <th>Type</th>
                                <th>Accès</th>
                                <th>Dernière modification</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="doc" items="${myDocs}">
                                <tr data-doctype="${doc.docType}">
                                    <td>
                                        <a href="${pageContext.request.contextPath}/editor/${doc.id}">
                                            <c:out value="${doc.title}" />
                                        </a>
                                        <c:if test="${doc.hasPassword()}">
                                            <span class="tag is-warning is-light ml-1"
                                                  title="Protégé par mot de passe">Securisé par mot de passe</span>
                                        </c:if>
                                    </td>
                                    <td>
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
                                                <c:otherwise>${doc.docType}</c:otherwise>
                                            </c:choose>
                                        </span>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${doc.accessType == 'public'}">
                                                <span class="tag is-success is-light">Public</span>
                                            </c:when>
                                            <c:when test="${doc.accessType == 'link'}">
                                                <span class="tag is-info is-light">Par lien</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="tag is-danger is-light">Privé</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <fmt:formatDate value="${doc.updatedAt}"
                                                        pattern="dd/MM/yyyy HH:mm" />
                                    </td>
                                    <td>
                                        <div class="buttons are-small">
                                            <a href="${pageContext.request.contextPath}/editor/${doc.id}"
                                               class="button is-primary is-outlined">
                                                Ouvrir
                                            </a>
                                            <a href="${pageContext.request.contextPath}/document/share?id=${doc.id}"
                                               class="button is-info is-outlined">
                                                Partager
                                            </a>
                                            <form method="post"
                                                  action="${pageContext.request.contextPath}/document/delete"
                                                  onsubmit="return confirm('Supprimer définitivement ce document ?');"
                                                  style="display:inline;">
                                                <input type="hidden" name="docId" value="${doc.id}">
                                                <button type="submit" class="button is-danger is-outlined">
                                                    Supprimer
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>

        <%-- =========================================================
             Documents partagés avec l'utilisateur
        ========================================================= --%>
        <c:if test="${not empty sharedDocs}">
            <hr>
            <h2 class="title is-4">Partagés avec moi</h2>
            <div class="table-container">
                <table class="table is-fullwidth is-striped is-hoverable" id="sharedDocsTable">
                    <thead>
                        <tr>
                            <th>Titre</th>
                            <th>Type</th>
                            <th>Propriétaire</th>
                            <th>Accès</th>
                            <th>Dernière modification</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="doc" items="${sharedDocs}">
                            <tr data-doctype="${doc.docType}">
                                <td>
                                    <a href="${pageContext.request.contextPath}/editor/${doc.id}">
                                        <c:out value="${doc.title}" />
                                    </a>
                                </td>
                                <td>
                                    <span class="doc-type-badge badge-${doc.docType}">
                                        <c:choose>
                                            <c:when test="${doc.docType == 'CODE'}">Code</c:when>
                                            <c:when test="${doc.docType == 'PIXELART'}">Pixel Art</c:when>
                                            <c:when test="${doc.docType == 'RICHTEXT'}">Texte riche</c:when>
                                            <c:when test="${doc.docType == 'SPREADSHEET'}">Tableur</c:when>
                                            <c:when test="${doc.docType == 'PRESENTATION'}">Présentation</c:when>
                                            <c:when test="${doc.docType == 'PLANNING'}">Planning</c:when>
                                            <c:when test="${doc.docType == 'MINDMAP'}">Mind Map</c:when>
                                            <c:when test="${doc.docType == 'DIAGRAM'}"> Diagramme</c:when>
                                            <c:otherwise>${doc.docType}</c:otherwise>
                                        </c:choose>
                                    </span>
                                </td>
                                <td><c:out value="${doc.ownerUsername}" /></td>
                                <td>
                                    <c:choose>
                                        <c:when test="${doc.accessType == 'public'}">
                                            <span class="tag is-success is-light">Public</span>
                                        </c:when>
                                        <c:when test="${doc.accessType == 'link'}">
                                            <span class="tag is-info is-light">Par lien</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="tag is-danger is-light">Privé</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td>
                                    <fmt:formatDate value="${doc.updatedAt}"
                                                    pattern="dd/MM/yyyy HH:mm" />
                                </td>
                                <td>
                                    <a href="${pageContext.request.contextPath}/editor/${doc.id}"
                                       class="button is-primary is-small is-outlined">
                                        Ouvrir
                                    </a>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:if>

    </div>
</section>

<script>
(function() {
    var buttons = document.querySelectorAll('.filter-btn');
    var rows    = document.querySelectorAll('tr[data-doctype]');

    buttons.forEach(function(btn) {
        btn.addEventListener('click', function() {
            buttons.forEach(function(b) {
                b.classList.remove('is-info');
                b.classList.add('is-light');
            });
            btn.classList.remove('is-light');
            btn.classList.add('is-info');

            var filter = btn.dataset.filter;
            rows.forEach(function(row) {
                if (filter === 'ALL' || row.dataset.doctype === filter) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    });

    // Correction classe initiale
    document.querySelectorAll('.filter-btn:not([data-filter="ALL"])').forEach(function(b) {
        b.classList.add('is-light');
    });
})();
</script>

<%@ include file="layout/footer.jsp" %>
