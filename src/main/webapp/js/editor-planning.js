/**
 * editor-planning.js — Éditeur PLANNING (Gantt) — CORRIGÉ
 * Corrections :
 * - Champ 'label' unifié (label dans l'éditeur, compatible avec title dans review)
 * - Gantt rendu robuste (dates invalides gérées)
 * - Ajout de tâche sans rechargement complet
 * - Sauvegarde correcte du contenu
 */

(function () {
    'use strict';

    var READONLY = (typeof PLANNING_READONLY !== 'undefined') ? PLANNING_READONLY : true;

    var state = { tasks: [] };
    var debounceTimer = null;

    var tasksBody   = document.getElementById('tasksBody');
    var addForm     = document.getElementById('addTaskForm');
    var ganttSvg    = document.getElementById('ganttSvg');
    var ganttWrapper = document.getElementById('ganttWrapper');

    // ------------------------------------------------------------------
    // Rendu tableau des tâches
    // ------------------------------------------------------------------

    function renderTable() {
        if (!tasksBody) return;
        tasksBody.innerHTML = '';
        state.tasks.forEach(function (task, idx) {
            var tr = document.createElement('tr');
            tr.style.opacity = task.done ? '0.6' : '1';

            function td(content, isHtml) {
                var el = document.createElement('td');
                if (isHtml) el.innerHTML = content;
                else el.textContent = content;
                tr.appendChild(el);
                return el;
            }

            // Utiliser label ou title (compatibilité)
            td(task.label || task.title || '');
            td(task.start || '');
            td(task.end   || '');

            var colorTd = document.createElement('td');
            var swatch = document.createElement('span');
            swatch.style.cssText = 'display:inline-block;width:20px;height:20px;border-radius:3px;background:' + (task.color || '#4CAF50');
            colorTd.appendChild(swatch);
            tr.appendChild(colorTd);

            var doneTd = document.createElement('td');
            var cb = document.createElement('input');
            cb.type = 'checkbox';
            cb.checked = !!task.done;
            if (!READONLY) {
                cb.addEventListener('change', function () {
                    task.done = cb.checked;
                    tr.style.opacity = task.done ? '0.6' : '1';
                    sendUpdate();
                });
            } else {
                cb.disabled = true;
            }
            doneTd.appendChild(cb);
            tr.appendChild(doneTd);

            if (!READONLY) {
                var actionTd = document.createElement('td');
                var delBtn = document.createElement('button');
                delBtn.className = 'button is-danger is-small is-outlined';
                delBtn.textContent = '✕';
                delBtn.setAttribute('type', 'button');
                delBtn.addEventListener('click', function () {
                    state.tasks.splice(idx, 1);
                    renderTable();
                    renderGantt();
                    sendUpdate();
                });
                actionTd.appendChild(delBtn);
                tr.appendChild(actionTd);
            }

            tasksBody.appendChild(tr);
        });
    }

    // ------------------------------------------------------------------
    // Formulaire ajout tâche
    // ------------------------------------------------------------------

    if (addForm && !READONLY) {
        addForm.addEventListener('submit', function (e) {
            e.preventDefault();
            var labelInput = document.getElementById('newTaskLabel');
            var startInput = document.getElementById('newTaskStart');
            var endInput   = document.getElementById('newTaskEnd');
            var colorInput = document.getElementById('newTaskColor');

            var label = labelInput ? labelInput.value.trim() : '';
            var start = startInput ? startInput.value : '';
            var end   = endInput   ? endInput.value   : '';
            var color = colorInput ? colorInput.value  : '#4CAF50';

            if (!label || !start || !end) return;
            if (new Date(start) > new Date(end)) {
                alert('La date de début doit être antérieure à la date de fin.');
                return;
            }

            state.tasks.push({
                id:    Date.now(),
                label: label,
                title: label,  // compatibilité review
                start: start,
                end:   end,
                color: color || '#4CAF50',
                done:  false
            });
            addForm.reset();
            if (colorInput) colorInput.value = '#4CAF50';
            renderTable();
            renderGantt();
            sendUpdate();
        });
    }

    // ------------------------------------------------------------------
    // Rendu Gantt SVG
    // ------------------------------------------------------------------

    function renderGantt() {
        if (!ganttSvg) return;
        if (state.tasks.length === 0) {
            ganttSvg.innerHTML = '';
            return;
        }

        var tasks = state.tasks.filter(function (t) {
            return t.start && t.end && !isNaN(new Date(t.start)) && !isNaN(new Date(t.end));
        });

        if (tasks.length === 0) {
            ganttSvg.innerHTML = '<text x="10" y="20" fill="#9ca3af" font-size="12">Aucune tâche avec des dates valides.</text>';
            return;
        }

        var allDates = [];
        tasks.forEach(function (t) {
            allDates.push(new Date(t.start));
            allDates.push(new Date(t.end));
        });

        var minDate = new Date(Math.min.apply(null, allDates));
        var maxDate = new Date(Math.max.apply(null, allDates));
        var totalDays = Math.max(1, (maxDate - minDate) / 86400000) + 1;

        var wrapW    = ganttWrapper ? ganttWrapper.clientWidth - 20 : 700;
        var labelW   = 160;
        var barArea  = Math.max(300, wrapW - labelW - 20);
        var rowH     = 30;
        var headerH  = 34;
        var svgW     = labelW + barArea + 10;
        var svgH     = headerH + tasks.length * rowH + 10;

        ganttSvg.setAttribute('width',   svgW);
        ganttSvg.setAttribute('height',  svgH);
        ganttSvg.setAttribute('viewBox', '0 0 ' + svgW + ' ' + svgH);
        ganttSvg.innerHTML = '';

        var ns = 'http://www.w3.org/2000/svg';

        function mk(tag, attrs) {
            var el = document.createElementNS(ns, tag);
            Object.keys(attrs).forEach(function (k) { el.setAttribute(k, attrs[k]); });
            return el;
        }

        // Fond
        ganttSvg.appendChild(mk('rect', { x: 0, y: 0, width: svgW, height: svgH, fill: '#1e1e2e' }));
        ganttSvg.appendChild(mk('rect', { x: 0, y: 0, width: svgW, height: headerH, fill: '#313244' }));

        // Dates repères
        var dateMilestones = [0, Math.round(totalDays / 4), Math.round(totalDays / 2), Math.round(totalDays * 3 / 4), totalDays - 1];
        var seenMilestone = {};
        dateMilestones.forEach(function (d) {
            if (seenMilestone[d]) return;
            seenMilestone[d] = true;
            var x = labelW + (d / totalDays) * barArea;
            var dt = new Date(minDate.getTime() + d * 86400000);
            var label = (dt.getDate() < 10 ? '0' : '') + dt.getDate() + '/' + ((dt.getMonth() + 1) < 10 ? '0' : '') + (dt.getMonth() + 1);
            var txt = document.createElementNS(ns, 'text');
            txt.setAttribute('x', x);
            txt.setAttribute('y', headerH - 6);
            txt.setAttribute('font-size', '10');
            txt.setAttribute('fill', '#cdd6f4');
            txt.setAttribute('text-anchor', 'middle');
            txt.textContent = label;
            ganttSvg.appendChild(txt);
            ganttSvg.appendChild(mk('line', {
                x1: x, y1: headerH, x2: x, y2: svgH,
                stroke: '#45475a', 'stroke-width': '0.5', 'stroke-dasharray': '4'
            }));
        });

        // Barres
        tasks.forEach(function (task, idx) {
            var y = headerH + idx * rowH;
            if (idx % 2 === 0) {
                ganttSvg.appendChild(mk('rect', { x: 0, y: y, width: svgW, height: rowH, fill: 'rgba(255,255,255,0.02)' }));
            }
            var lbl = document.createElementNS(ns, 'text');
            lbl.setAttribute('x', labelW - 6);
            lbl.setAttribute('y', y + rowH / 2 + 4);
            lbl.setAttribute('font-size', '11');
            lbl.setAttribute('fill', '#cdd6f4');
            lbl.setAttribute('text-anchor', 'end');
            var taskLabel = task.label || task.title || '';
            lbl.textContent = taskLabel.length > 20 ? taskLabel.substring(0, 18) + '…' : taskLabel;
            ganttSvg.appendChild(lbl);

            var startDate = new Date(task.start);
            var endDate   = new Date(task.end);
            var startD = (startDate - minDate) / 86400000;
            var endD   = (endDate   - minDate) / 86400000 + 1;
            var bx = labelW + (startD / totalDays) * barArea;
            var bw = Math.max(4, ((endD - startD) / totalDays) * barArea);
            var barColor = task.done ? '#6c7086' : (task.color || '#4CAF50');

            ganttSvg.appendChild(mk('rect', {
                x: bx, y: y + 5,
                width: bw, height: rowH - 10,
                rx: 3, fill: barColor, opacity: '0.85'
            }));

            if (task.done) {
                var done = document.createElementNS(ns, 'text');
                done.setAttribute('x', bx + bw / 2);
                done.setAttribute('y', y + rowH / 2 + 4);
                done.setAttribute('font-size', '10');
                done.setAttribute('fill', '#fff');
                done.setAttribute('text-anchor', 'middle');
                done.textContent = '✓';
                ganttSvg.appendChild(done);
            }
        });
    }

    // ------------------------------------------------------------------
    // Callbacks
    // ------------------------------------------------------------------

    function sendUpdate() {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(function () {
            window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
        }, 300);
    }

    window.EDITOR_getContent = function () {
        return JSON.stringify({ tasks: state.tasks });
    };

    window.EDITOR_setContent = function (jsonStr) {
        if (!jsonStr) return;
        try {
            var obj = JSON.parse(jsonStr);
            if (obj && obj.tasks) {
                // Normalisation : assurer que label ET title sont présents
                state.tasks = obj.tasks.map(function (t) {
                    return {
                        id:    t.id    || Date.now(),
                        label: t.label || t.title || '',
                        title: t.title || t.label || '',
                        start: t.start || '',
                        end:   t.end   || '',
                        color: t.color || '#4CAF50',
                        done:  !!t.done
                    };
                });
                renderTable();
                renderGantt();
            }
        } catch (e) { /* ignore */ }
    };

    // ------------------------------------------------------------------
    // Initialisation
    // ------------------------------------------------------------------

    renderTable();
    renderGantt();
    window.addEventListener('resize', renderGantt);

})();
