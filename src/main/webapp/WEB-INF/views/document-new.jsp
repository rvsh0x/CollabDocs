<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="pageTitle" value="Nouveau document — CollabDocs" />
<%@ include file="layout/header.jsp" %>

<section class="section">
    <div class="container">

        <h1 class="title">Nouveau document</h1>

        <c:if test="${not empty error}">
            <div class="notification is-danger is-light">
                <c:out value="${error}" />
            </div>
        </c:if>

        <form method="post" action="${pageContext.request.contextPath}/document/new">

            <%-- Champ hidden mis à jour par JS lorsque l'utilisateur clique sur un type --%>
            <input type="hidden" id="docTypeInput" name="docType" value="CODE">

            <%-- ---- Titre ---- --%>
            <div class="field">
                <label class="label" for="title">Titre du document</label>
                <div class="control">
                    <input class="input" type="text" id="title" name="title"
                           placeholder="Mon nouveau document"
                           maxlength="200" autofocus required>
                </div>
            </div>

            <%-- ---- Sélecteur de type ---- --%>
            <div class="field">
                <label class="label">Type de document</label>
                <div class="doc-type-grid" id="typeGrid">

                    <div class="doc-type-card selected" data-type="CODE">
                    
                        <div class="type-name">Code / Texte</div>
                        <div class="type-desc">Éditeur monospace avec coloration syntaxique</div>
                    </div>

                    <div class="doc-type-card" data-type="PIXELART">
                      
                        <div class="type-name">Pixel Art</div>
                        <div class="type-desc">Grille canvas interactive, palette de couleurs</div>
                    </div>

                    <div class="doc-type-card" data-type="RICHTEXT">
                    
                        <div class="type-name">Texte riche</div>
                        <div class="type-desc">Éditeur WYSIWYG avec mise en forme</div>
                    </div>

                    <div class="doc-type-card" data-type="SPREADSHEET">
                    
                        <div class="type-name">Tableur</div>
                        <div class="type-desc">Grille de cellules éditables, style Sheets</div>
                    </div>

                    <div class="doc-type-card" data-type="PRESENTATION">
                      
                        <div class="type-name">Présentation</div>
                        <div class="type-desc">Diaporama de slides avec mode plein écran</div>
                    </div>

                    <div class="doc-type-card" data-type="PLANNING">
                       
                        <div class="type-name">Planning</div>
                        <div class="type-desc">Tâches avec dates et rendu Gantt SVG</div>
                    </div>

                    <div class="doc-type-card" data-type="MINDMAP">
                       
                        <div class="type-name">Carte mentale</div>
                        <div class="type-desc">Arbre de nœuds interactifs en SVG</div>
                    </div>

                    <div class="doc-type-card" data-type="DIAGRAM">
                        <div class="type-name">Diagramme</div>
                        <div class="type-desc">Nœuds et flèches libres sur canvas</div>
                    </div>

                </div>
            </div>

            <%-- ---- Type d'accès ---- --%>
            <div class="field">
                <label class="label">Type d'accès</label>
                <div class="control">
                    <label class="radio">
                        <input type="radio" name="accessType" value="link" checked>
                        Par lien — seuls ceux qui ont le lien peuvent accéder
                    </label>
                    <br>
                    <label class="radio mt-2">
                        <input type="radio" name="accessType" value="public">
                        Public — tout le monde peut lire
                    </label>
                    <br>
                    <label class="radio mt-2">
                        <input type="radio" name="accessType" value="private">
                        Privé — uniquement vous et vos invités
                    </label>
                </div>
            </div>

            <%-- ---- Mot de passe ---- --%>
            <div class="field">
                <label class="label" for="docPassword">Mot de passe (optionnel)</label>
                <div class="control">
                    <input class="input" type="password" id="docPassword" name="docPassword"
                           placeholder="Laisser vide pour pas de protection"
                           autocomplete="new-password">
                </div>
                <p class="help">
                    Si renseigné, un mot de passe sera demandé à chaque ouverture.
                    Le mot de passe n'apparaît jamais dans les URLs.
                </p>
            </div>

            <div class="field is-grouped mt-5">
                <div class="control">
                    <button class="button is-primary" type="submit">
                        Créer le document
                    </button>
                </div>
                <div class="control">
                    <a class="button is-light"
                       href="${pageContext.request.contextPath}/home">
                        Annuler
                    </a>
                </div>
            </div>

        </form>

    </div>
</section>

<script>
(function() {
    var cards = document.querySelectorAll('.doc-type-card');
    var input = document.getElementById('docTypeInput');

    cards.forEach(function(card) {
        card.addEventListener('click', function() {
            cards.forEach(function(c) { c.classList.remove('selected'); });
            card.classList.add('selected');
            input.value = card.dataset.type;
        });
    });
})();
</script>

<%@ include file="layout/footer.jsp" %>
