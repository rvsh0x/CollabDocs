<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Partage — CollabDocs" />
<%@ include file="layout/header.jsp" %>


<section class="section">
    <div class="container">
        <div class="columns">
            <div class="column is-8 is-offset-2">

                <div class="level">
                    <div class="level-left">
                        <h1 class="title">Partager «&nbsp;<c:out value="${doc.title}"/>&nbsp;»</h1>
                    </div>
                    <div class="level-right">
                        <a href="${pageContext.request.contextPath}/editor/${doc.id}"
                           class="button is-primary is-outlined is-small">
                            Ouvrir l'éditeur
                        </a>
                    </div>
                </div>

                <c:if test="${not empty error}">
                    <div class="notification is-danger is-light">
                        <c:out value="${error}" />
                    </div>
                </c:if>

                <!-- =========================================================
                     Lien de partage
                ========================================================= -->
                <div class="box">
                    <h2 class="subtitle">Lien de partage</h2>
                    <div class="field has-addons">
                        <div class="control is-expanded">
                            <input class="input" type="text" id="shareLink" readonly
                                   value="${pageContext.request.scheme}://${pageContext.request.serverName}:${pageContext.request.serverPort}${pageContext.request.contextPath}/d/${doc.shareToken}">
                        </div>
                        <div class="control">
                            <button class="button is-info" onclick="copyShareLink()">
                                Copier
                            </button>
                        </div>
                    </div>
                    <p class="help">
                        Type d'accès actuel :
                        <c:choose>
                            <c:when test="${doc.accessType == 'public'}">
                                <strong class="has-text-success">Public</strong> (tout le monde peut voir)
                            </c:when>
                            <c:when test="${doc.accessType == 'link'}">
                                <strong class="has-text-info">Par lien</strong> (seuls ceux qui ont ce lien)
                            </c:when>
                            <c:otherwise>
                                <strong class="has-text-danger">Privé</strong> (seuls les invités explicites)
                            </c:otherwise>
                        </c:choose>
                    </p>
                </div>

                <!-- =========================================================
                     Collaborateurs actuels
                ========================================================= -->
                <div class="box">
                    <h2 class="subtitle">Collaborateurs</h2>
                    <c:choose>
                        <c:when test="${empty permissions}">
                            <p class="has-text-grey">Aucun collaborateur invité pour l'instant.</p>
                        </c:when>
                        <c:otherwise>
                            <table class="table is-fullwidth is-striped">
                                <thead>
                                    <tr>
                                        <th>Utilisateur</th>
                                        <th>Niveau</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach var="perm" items="${permissions}">
                                        <tr>
                                            <td><c:out value="${perm.username}" /></td>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${perm.level == 'write'}">
                                                        <span class="tag is-success">Écriture</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="tag is-info">Lecture</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>
                                            <td>
                                                <form method="post"
                                                      action="${pageContext.request.contextPath}/document/share">
                                                    <input type="hidden" name="docId"        value="${doc.id}">
                                                    <input type="hidden" name="action"       value="remove">
                                                    <input type="hidden" name="targetUserId" value="${perm.userId}">
                                                    <button type="submit" class="button is-danger is-small is-outlined">
                                                        Retirer
                                                    </button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </c:otherwise>
                    </c:choose>
                </div>

                <!-- =========================================================
                     Inviter un utilisateur
                ========================================================= -->
                <div class="box">
                    <h2 class="subtitle">Inviter un utilisateur</h2>
                    <form method="post" action="${pageContext.request.contextPath}/document/share">
                        <input type="hidden" name="docId"  value="${doc.id}">
                        <input type="hidden" name="action" value="add">

                        <div class="field is-grouped">
                            <div class="control is-expanded">
                                <input class="input" type="text" name="targetUsername"
                                       placeholder="Nom d'utilisateur" required>
                            </div>
                            <div class="control">
                                <div class="select">
                                    <select name="level">
                                        <option value="read">Lecture seule</option>
                                        <option value="write">Lecture + Écriture</option>
                                    </select>
                                </div>
                            </div>
                            <div class="control">
                                <button class="button is-primary" type="submit">Inviter</button>
                            </div>
                        </div>
                    </form>
                </div>

                <div class="has-text-centered">
                    <a href="${pageContext.request.contextPath}/home"
                       class="button is-light">
                        Retour à mes documents
                    </a>
                </div>

            </div>
        </div>
    </div>
</section>

<script>
function copyShareLink() {
    var input = document.getElementById('shareLink');
    input.select();
    input.setSelectionRange(0, 99999);
    try {
        navigator.clipboard.writeText(input.value).then(function() {
            showToast('Lien copié dans le presse-papiers !');
        });
    } catch (e) {
        document.execCommand('copy');
        showToast('Lien copié !');
    }
}

function showToast(msg) {
    var toast = document.createElement('div');
    toast.textContent = msg;
    toast.className = 'notification is-success toast-notification';
    document.body.appendChild(toast);
    setTimeout(function() { toast.remove(); }, 3000);
}
</script>

<%@ include file="layout/footer.jsp" %>
