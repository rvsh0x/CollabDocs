<%-- Fragment éditeur PLANNING — inclus par editor.jsp --%>
<%-- JS : /js/editor-planning.js (chargé par editor.jsp après editor.js) --%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<div class="planning-editor">

    <%-- Tableau des tâches --%>
    <div class="planning-tasks-section">
        <h3 class="planning-section-title">Tâches</h3>

        <div class="planning-table-wrapper">
            <table class="table is-fullwidth is-striped is-hoverable is-narrow" id="tasksTable">
                <thead>
                    <tr>
                        <th>Libellé</th>
                        <th>Début</th>
                        <th>Fin</th>
                        <th>Couleur</th>
                        <th>Fait ?</th>
                        <c:if test="${canEdit}"><th>Actions</th></c:if>
                    </tr>
                </thead>
                <tbody id="tasksBody">
                    <%-- Généré par JS --%>
                </tbody>
            </table>
        </div>

        <c:if test="${canEdit}">
            <form id="addTaskForm" class="planning-add-task box mt-3">
                <div class="columns is-vcentered">
                    <div class="column">
                        <input class="input is-small" type="text" id="newTaskLabel"
                               placeholder="Libellé de la tâche" required maxlength="100">
                    </div>
                    <div class="column is-narrow">
                        <input class="input is-small" type="date" id="newTaskStart" required>
                    </div>
                    <div class="column is-narrow">
                        <input class="input is-small" type="date" id="newTaskEnd" required>
                    </div>
                    <div class="column is-narrow">
                        <input type="color" id="newTaskColor" value="#4CAF50" title="Couleur">
                    </div>
                    <div class="column is-narrow">
                        <button type="submit" class="button is-primary is-small">+ Ajouter</button>
                    </div>
                </div>
            </form>
        </c:if>
    </div>

    <%-- Rendu Gantt SVG --%>
    <div class="planning-gantt-section">
        <h3 class="planning-section-title">Diagramme de Gantt</h3>
        <div class="gantt-wrapper" id="ganttWrapper">
            <svg id="ganttSvg" class="gantt-svg"></svg>
        </div>
    </div>

</div>

<script>
var PLANNING_READONLY = ${!canEdit};
</script>
