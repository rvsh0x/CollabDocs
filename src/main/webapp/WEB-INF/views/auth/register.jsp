<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page pageEncoding="UTF-8" %>
<c:set var="pageTitle" value="Inscription — CollabDocs" />
<%@ include file="../layout/header.jsp" %>

<section class="section">
    <div class="container">
        <div class="columns is-centered">
            <div class="column is-5-tablet is-4-desktop is-4-widescreen">

                <h1 class="title has-text-centered">Créer un compte</h1>
                <h2 class="subtitle has-text-centered">Rejoignez CollabDocs</h2>

                <c:if test="${not empty error}">
                    <div class="notification is-danger is-light">
                        <c:out value="${error}" />
                    </div>
                </c:if>

                <form method="post" action="${pageContext.request.contextPath}/register"
                      class="box">

                    <div class="field">
                        <label class="label" for="username">Nom d'utilisateur</label>
                        <div class="control">
                            <input class="input" type="text" id="username" name="username"
                                   value="<c:out value='${username}'/>"
                                   placeholder="Entre 3 et 50 caractères"
                                   minlength="3" maxlength="50"
                                   autofocus required>
                        </div>
                    </div>

                    <div class="field">
                        <label class="label" for="email">Adresse e-mail</label>
                        <div class="control">
                            <input class="input" type="email" id="email" name="email"
                                   value="<c:out value='${email}'/>"
                                   placeholder="vous@exemple.fr" required>
                        </div>
                    </div>

                    <div class="field">
                        <label class="label" for="password">Mot de passe</label>
                        <div class="control">
                            <input class="input" type="password" id="password" name="password"
                                   placeholder="Minimum 6 caractères"
                                   minlength="6" required>
                        </div>
                    </div>

                    <div class="field">
                        <label class="label" for="password2">Confirmer le mot de passe</label>
                        <div class="control">
                            <input class="input" type="password" id="password2" name="password2"
                                   placeholder="Répétez le mot de passe"
                                   minlength="6" required>
                        </div>
                    </div>

                    <div class="field">
                        <div class="control">
                            <button class="button is-primary is-fullwidth" type="submit">
                                Créer mon compte
                            </button>
                        </div>
                    </div>

                    <div class="has-text-centered mt-4">
                        <p>Déjà un compte ?
                            <a href="${pageContext.request.contextPath}/login">Se connecter</a>
                        </p>
                    </div>
                </form>

            </div>
        </div>
    </div>
</section>

<%@ include file="../layout/footer.jsp" %>
