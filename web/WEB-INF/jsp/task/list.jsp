<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tasks</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Tasks</h2>
<p class="page-sub">Manage page tasks for your series</p>

<div id="overdueAlert" class="alert-box" style="display:none;"></div>

<section class="metric-grid">
    <article class="metric-card"><div id="activeTasks" class="metric-value">0</div><div class="metric-label">Active</div></article>
    <article class="metric-card"><div id="submittedTasks" class="metric-value metric-violet">0</div><div class="metric-label">Submitted</div></article>
    <article class="metric-card"><div id="overdueTasks" class="metric-value metric-danger">0</div><div class="metric-label">Overdue</div></article>
    <article class="metric-card"><div id="completedTasks" class="metric-value metric-ok">0</div><div class="metric-label">Completed</div></article>
</section>

<div id="taskResult" class="alert error" style="display:none;"></div>

<div id="taskActions" class="section-card" style="display:none;">
    <div class="section-head">
        <div>
            <h3 class="section-title">Task Actions</h3>
            <p class="section-desc">Click an action button to open form</p>
        </div>
    </div>

    <div class="inline-meta" style="margin: 0 0 12px 0; gap: 10px;">
        <button class="btn" type="button" data-task-pane="taskCreatePane">Create Task</button>
    </div>

    <form id="taskCreateForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskCreatePane">
        <strong>Create Task</strong>
        <select id="createTaskChapterId" name="chapterId" required>
            <option value="">Loading chapters...</option>
        </select>
        <select id="createTaskAssistantId" name="assistantId" required>
            <option value="">Select Chapter first</option>
        </select>
        <input name="pageRangeStart" type="number" min="1" placeholder="Page Start" required />
        <input name="pageRangeEnd" type="number" min="1" placeholder="Page End" required />
        <select name="taskType" required>
            <option value="">Select Task Type</option>
            <option value="SKETCHING">Sketching</option>
            <option value="INKING">Inking</option>
            <option value="COLORING">Coloring</option>
            <option value="LETTERING">Lettering</option>
        </select>
        <label class="field-label" for="taskCreateDueDate">Due Date</label>
        <input id="taskCreateDueDate" name="dueDate" type="date" aria-label="Due Date" required />
        <button class="btn primary" type="submit">Create</button>
    </form>
</div>

<div class="section-card">
    <h3 class="section-title">All Tasks</h3>
    <table class="data-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Series</th>
                <th>Pages</th>
                <th>Type</th>
                <th>Assigned To</th>
                <th>Status</th>
                <th>Due Date</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody id="taskRows">
            <c:forEach items="${tasks}" var="t">
                <tr>
                    <td>${t.id}</td>
                    <td><strong>${t.seriesTitle}</strong><br/>Ch. ${t.chapterNumber} - ${t.chapterTitle}</td>
                    <td>${t.pageRangeStart}-${t.pageRangeEnd}</td>
                    <td>${t.taskType}</td>
                    <td>${t.assistantName}</td>
                    <td>
                        <span class="status-chip ${t.status=='OVERDUE' ? 'status-overdue' : (t.status=='IN_PROGRESS' ? 'status-progress' : (t.status=='PENDING' ? 'status-pending' : (t.status=='APPROVED' ? 'status-approved' : 'status-draft')))}">${t.status}</span>
                    </td>
                    <td>${t.dueDate}</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/tasks/${t.id}">View</a></td>
                </tr>
            </c:forEach>
            <c:if test="${empty tasks}"><tr><td colspan="7">No tasks found.</td></tr></c:if>
        </tbody>
    </table>
</div>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var resultBox = document.getElementById('taskResult');
    var currentUser = null;
    var seriesList = [];
    var chapters = [];
    var tasks = [];
    var seriesById = {};
    var chapterById = {};
    var currentTaskPaneId = '';

    function escapeHtml(value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value).replace(/[&<>"]/g, function (ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[ch];
        });
    }

    function hasRole(role) {
        var roles = currentUser && currentUser.roles ? currentUser.roles : [];
        return roles.indexOf(role) !== -1;
    }

    function isAssignedAssistant(task) {
        return hasRole('ASSISTANT') && Number(task.assistantId) === Number(currentUser.id);
    }

    function isTaskOwner(task) {
        var chapter = chapterById[String(task.chapterId)];
        var series = chapter ? seriesById[String(chapter.seriesId)] : null;
        return hasRole('MANGAKA') && series && Number(series.mangakaId) === Number(currentUser.id);
    }

    function formatStatus(status) {
        if (!status) {
            return '';
        }
        return String(status).toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, function (ch) { return ch.toUpperCase(); });
    }

    function statusClass(status) {
        status = String(status || '').toUpperCase();
        if (status === 'OVERDUE') { return 'status-overdue'; }
        if (status === 'IN_PROGRESS') { return 'status-progress'; }
        if (status === 'PENDING') { return 'status-pending'; }
        if (status === 'APPROVED') { return 'status-approved'; }
        if (status === 'REJECTED') { return 'status-rejected'; }
        return 'status-draft';
    }


    function renderTaskTypeSelect(selectedType) {
        var options = [
            { value: 'SKETCHING', label: 'Sketching' },
            { value: 'INKING', label: 'Inking' },
            { value: 'COLORING', label: 'Coloring' },
            { value: 'LETTERING', label: 'Lettering' }
        ];
        var selected = String(selectedType || '').toUpperCase();
        return '<select name="taskType" required><option value="">Select Task Type</option>' + options.map(function (option) {
            return '<option value="' + option.value + '" ' + (option.value === selected ? 'selected' : '') + '>' + option.label + '</option>';
        }).join('') + '</select>';
    }
    function showMessage(msg, isError) {
        if (!resultBox) {
            return;
        }
        resultBox.style.display = 'block';
        resultBox.className = isError ? 'alert error' : 'panel';
        resultBox.textContent = msg;
    }

    function formToObject(form) {
        var data = {};
        var fd = new FormData(form);
        fd.forEach(function (v, k) { data[k] = v; });
        return data;
    }

    async function callApi(method, path, data) {
        var opts = { method: method, headers: { 'Accept': 'application/json' } };
        var url = ctx + path;
        if (data) {
            var params = new URLSearchParams(data).toString();
            if (method === 'GET' || method === 'PUT' || method === 'PATCH') {
                url += (url.indexOf('?') === -1 ? '?' : '&') + params;
            } else {
                opts.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
                opts.body = params;
            }
        }

        var res = await fetch(url, opts);
        var text = await res.text();
        var body = null;
        try { body = text ? JSON.parse(text) : null; } catch (e) {}

        if (!res.ok || (body && body.success === false)) {
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || text || ('Request failed: HTTP ' + res.status);
            throw new Error(msg);
        }
        return body;
    }

    function toggleTaskPane(targetPaneId) {
        currentTaskPaneId = (currentTaskPaneId === targetPaneId) ? '' : targetPaneId;
        var panes = document.querySelectorAll('.task-pane');
        for (var i = 0; i < panes.length; i++) {
            var pane = panes[i];
            pane.style.display = (currentTaskPaneId && pane.getAttribute('data-task-pane-id') === currentTaskPaneId) ? 'grid' : 'none';
        }
    }

    function hideInlineRows() {
        var rows = document.querySelectorAll('.task-inline-row');
        for (var i = 0; i < rows.length; i++) {
            rows[i].style.display = 'none';
            var panes = rows[i].querySelectorAll('.task-inline-pane');
            for (var j = 0; j < panes.length; j++) {
                panes[j].style.display = 'none';
            }
        }
    }

    async function fillAssistantSelect(select, seriesId, selectedId) {
        if (!select || !seriesId) {
            return;
        }
        select.innerHTML = '<option value="">Loading assistants...</option>';
        try {
            var res = await callApi('GET', '/api/v1/series/' + seriesId + '/assistants');
            var assistants = res.data || [];
            select.innerHTML = '<option value="">Select Assistant</option>' + assistants.map(function (a) {
                var selected = Number(a.id) === Number(selectedId) ? 'selected' : '';
                return '<option value="' + a.id + '" ' + selected + '>#' + a.id + ' - ' + escapeHtml(a.fullName || a.username) + '</option>';
            }).join('');
        } catch (err) {
            select.innerHTML = '<option value="">Cannot load assistants</option>';
            showMessage(err.message, true);
        }
    }

    function renderTaskActions() {
        var actions = document.getElementById('taskActions');
        if (!hasRole('MANGAKA')) {
            actions.style.display = 'none';
            return;
        }
        actions.style.display = 'block';

        var select = document.getElementById('createTaskChapterId');
        var ownChapters = chapters.filter(function (ch) {
            var series = seriesById[String(ch.seriesId)];
            return series && Number(series.mangakaId) === Number(currentUser.id);
        });
        select.innerHTML = '<option value="">Select Chapter</option>' + ownChapters.map(function (ch) {
            return '<option value="' + ch.id + '">#' + ch.id + ' - S' + ch.seriesId + ' - Ch.' + ch.chapterNumber + ' - ' + escapeHtml(ch.title) + '</option>';
        }).join('');
    }

    function renderMetrics() {
        var active = 0;
        var submitted = 0;
        var completed = 0;
        var overdue = 0;
        var today = new Date();
        today.setHours(0, 0, 0, 0);

        for (var i = 0; i < tasks.length; i++) {
            var t = tasks[i];
            var st = String(t.status || '').toUpperCase();
            if (st === 'PENDING' || st === 'IN_PROGRESS') { active++; }
            if (st === 'SUBMITTED') { submitted++; }
            if (st === 'APPROVED') { completed++; }
            if (st === 'OVERDUE') {
                overdue++;
            } else if (t.dueDate && st !== 'APPROVED') {
                var due = new Date(t.dueDate + 'T00:00:00');
                if (due < today) { overdue++; }
            }
        }

        document.getElementById('activeTasks').textContent = active;
        document.getElementById('submittedTasks').textContent = submitted;
        document.getElementById('completedTasks').textContent = completed;
        document.getElementById('overdueTasks').textContent = overdue;

        var alert = document.getElementById('overdueAlert');
        if (overdue > 0) {
            alert.style.display = 'block';
            alert.innerHTML = '<strong>' + overdue + ' Overdue Task</strong><br/>These tasks have passed their due date and need immediate attention.';
        } else {
            alert.style.display = 'none';
        }
    }

    function canAssistantStart(task) {
        var st = String(task.status || '').toUpperCase();
        return isAssignedAssistant(task) && (st === 'PENDING' || st === 'REJECTED' || st === 'OVERDUE');
    }

    function canAssistantSubmit(task) {
        return isAssignedAssistant(task) && String(task.status || '').toUpperCase() === 'IN_PROGRESS';
    }

    function renderUpdateForm(task) {
        var chapter = chapterById[String(task.chapterId)];
        var seriesId = chapter ? chapter.seriesId : '';
        return '<form class="panel form-grid task-inline-pane task-inline-update-form" data-task-pane-key="update" style="display:none; max-width:640px;">'
            + '<strong>Reassign / Update Task #' + task.id + '</strong>'
            + '<input name="taskId" type="hidden" value="' + task.id + '" />'
            + '<select class="assistant-select" name="assistantId" data-series-id="' + seriesId + '" data-selected-assistant-id="' + task.assistantId + '" required><option value="">Open form to load assistants</option></select>'
            + '<input name="pageRangeStart" type="number" min="1" value="' + task.pageRangeStart + '" placeholder="Page Start" required />'
            + '<input name="pageRangeEnd" type="number" min="1" value="' + task.pageRangeEnd + '" placeholder="Page End" required />'
            + renderTaskTypeSelect(task.taskType)
            + '<label class="field-label" for="taskUpdateDueDate' + task.id + '">Due Date</label>'
            + '<input id="taskUpdateDueDate' + task.id + '" name="dueDate" type="date" value="' + escapeHtml(task.dueDate || '') + '" aria-label="Due Date" required />'
            + '<button class="btn" type="submit">Update</button>'
            + '</form>';
    }

    function renderStatusForm(task) {
        var options = '';
        if (canAssistantStart(task)) {
            options += '<option value="IN_PROGRESS">In Progress</option>';
        }
        if (canAssistantSubmit(task)) {
            options += '<option value="SUBMITTED">Submitted</option>';
        }
        return '<form class="panel form-grid task-inline-pane task-inline-status-form" data-task-pane-key="status" style="display:none; max-width:640px;">'
            + '<strong>Update Status For Task #' + task.id + '</strong>'
            + '<input name="taskId" type="hidden" value="' + task.id + '" />'
            + '<select name="status" required>' + options + '</select>'
            + '<button class="btn" type="submit">Update Status</button>'
            + '</form>';
    }

    function renderTaskDetail(task) {
        return '<strong>Task #' + task.id + ' Detail</strong>'
            + '<p class="section-desc" style="margin:8px 0 0;">' + escapeHtml(task.seriesTitle) + ' - Ch. ' + escapeHtml(task.chapterNumber) + ' - ' + escapeHtml(task.chapterTitle) + '</p>'
            + '<div class="inline-meta" style="margin-top:10px;gap:14px;">'
            + '<span>Pages: ' + task.pageRangeStart + '-' + task.pageRangeEnd + '</span>'
            + '<span>Type: ' + formatStatus(task.taskType) + '</span>'
            + '<span>Assigned: ' + escapeHtml(task.assistantName) + '</span>'
            + '<span>Status: ' + formatStatus(task.status) + '</span>'
            + '<span>Due Date: ' + escapeHtml(task.dueDate) + '</span>'
            + '</div>';
    }

    function renderTasks() {
        var tbody = document.getElementById('taskRows');
        if (!tasks.length) {
            tbody.innerHTML = '<tr><td colspan="8">No tasks found.</td></tr>';
            return;
        }

        tbody.innerHTML = tasks.map(function (task) {
            var owner = isTaskOwner(task);
            var canStatus = canAssistantStart(task) || canAssistantSubmit(task);
            var actionButtons = '<button class="btn small" type="button" data-task-inline="taskInlineRow' + task.id + '" data-task-id="' + task.id + '" data-task-pane-key="detail">Detail</button>';
            if (owner) {
                actionButtons += ' <button class="btn small" type="button" data-task-inline="taskInlineRow' + task.id + '" data-task-id="' + task.id + '" data-task-pane-key="update">Update</button>';
                actionButtons += ' <button class="btn small" type="button" data-task-decision="approve" data-task-id="' + task.id + '">Approve</button>';
                actionButtons += ' <button class="btn small" type="button" data-task-decision="reject" data-task-id="' + task.id + '">Reject</button>';
            }
            if (canStatus) {
                actionButtons += ' <button class="btn small" type="button" data-task-inline="taskInlineRow' + task.id + '" data-task-id="' + task.id + '" data-task-pane-key="status">Status</button>';
            }

            var inlinePanes = '<div class="panel task-inline-pane" data-task-pane-key="detail" style="display:none;">Loading detail...</div>';
            if (owner) {
                inlinePanes += renderUpdateForm(task);
            }
            if (canStatus) {
                inlinePanes += renderStatusForm(task);
            }

            return '<tr>'
                + '<td>' + task.id + '</td>'
                + '<td><strong>' + escapeHtml(task.seriesTitle) + '</strong><br/>Ch. ' + escapeHtml(task.chapterNumber) + ' - ' + escapeHtml(task.chapterTitle) + '</td>'
                + '<td>' + task.pageRangeStart + '-' + task.pageRangeEnd + '</td>'
                + '<td>' + formatStatus(task.taskType) + '</td>'
                + '<td>' + escapeHtml(task.assistantName) + '</td>'
                + '<td><span class="status-chip ' + statusClass(task.status) + '">' + formatStatus(task.status) + '</span></td>'
                + '<td>' + escapeHtml(task.dueDate) + '</td>'
                + '<td><div class="inline-meta" style="gap:6px;margin:0;">' + actionButtons + '</div></td>'
                + '</tr>'
                + '<tr id="taskInlineRow' + task.id + '" class="task-inline-row" style="display:none;"><td colspan="8">' + inlinePanes + '</td></tr>';
        }).join('');
    }

    async function openTaskInline(rowId, paneKey, taskId) {
        var row = document.getElementById(rowId);
        var pane = row ? row.querySelector('[data-task-pane-key="' + paneKey + '"]') : null;
        var alreadyOpen = row && row.style.display === 'table-row' && pane && pane.style.display !== 'none';
        hideInlineRows();
        if (alreadyOpen || !row || !pane) {
            return;
        }

        row.style.display = 'table-row';
        pane.style.display = pane.tagName === 'FORM' ? 'grid' : 'block';

        if (paneKey === 'detail') {
            try {
                pane.innerHTML = 'Loading detail...';
                var res = await callApi('GET', '/api/v1/tasks/' + taskId);
                pane.innerHTML = renderTaskDetail(res.data);
            } catch (err) {
                pane.innerHTML = escapeHtml(err.message);
            }
        }

        if (paneKey === 'update') {
            var select = pane.querySelector('.assistant-select');
            await fillAssistantSelect(select, select.getAttribute('data-series-id'), select.getAttribute('data-selected-assistant-id'));
        }
    }

    async function loadData() {
        try {
            var userRes = await callApi('GET', '/api/v1/auth/me');
            currentUser = userRes.data;
            var results = await Promise.all([
                callApi('GET', '/api/v1/series'),
                callApi('GET', '/api/v1/chapters'),
                callApi('GET', '/api/v1/tasks')
            ]);
            seriesList = results[0].data || [];
            chapters = results[1].data || [];
            tasks = results[2].data || [];
            seriesById = {};
            chapterById = {};
            for (var i = 0; i < seriesList.length; i++) {
                seriesById[String(seriesList[i].id)] = seriesList[i];
            }
            for (var j = 0; j < chapters.length; j++) {
                chapterById[String(chapters[j].id)] = chapters[j];
            }
            renderTaskActions();
            renderMetrics();
            renderTasks();
        } catch (err) {
            document.getElementById('taskRows').innerHTML = '<tr><td colspan="8">' + escapeHtml(err.message) + '</td></tr>';
        }
    }

    document.addEventListener('click', async function (e) {
        var paneButton = e.target.closest ? e.target.closest('[data-task-pane]') : null;
        if (paneButton) {
            toggleTaskPane(paneButton.getAttribute('data-task-pane'));
            return;
        }

        var inlineButton = e.target.closest ? e.target.closest('[data-task-inline]') : null;
        if (inlineButton) {
            await openTaskInline(inlineButton.getAttribute('data-task-inline'), inlineButton.getAttribute('data-task-pane-key'), inlineButton.getAttribute('data-task-id'));
            return;
        }

        var decisionButton = e.target.closest ? e.target.closest('[data-task-decision]') : null;
        if (decisionButton) {
            try {
                var action = decisionButton.getAttribute('data-task-decision');
                var taskId = decisionButton.getAttribute('data-task-id');
                await callApi('POST', '/api/v1/tasks/' + taskId + '/' + action);
                showMessage(action === 'approve' ? 'Task approved.' : 'Task rejected.', false);
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }
    });

    document.addEventListener('change', async function (e) {
        if (e.target.id === 'createTaskChapterId') {
            var chapter = chapterById[String(e.target.value)];
            var assistantSelect = document.getElementById('createTaskAssistantId');
            if (!chapter) {
                assistantSelect.innerHTML = '<option value="">Select Chapter first</option>';
                return;
            }
            await fillAssistantSelect(assistantSelect, chapter.seriesId, '');
        }
    });

    document.addEventListener('submit', async function (e) {
        if (e.target.id === 'taskCreateForm') {
            e.preventDefault();
            try {
                var createData = formToObject(e.target);
                await callApi('POST', '/api/v1/chapters/' + createData.chapterId + '/tasks', {
                    assistantId: createData.assistantId,
                    pageRangeStart: createData.pageRangeStart,
                    pageRangeEnd: createData.pageRangeEnd,
                    taskType: createData.taskType,
                    dueDate: createData.dueDate
                });
                showMessage('Task created successfully.', false);
                e.target.reset();
                document.getElementById('createTaskAssistantId').innerHTML = '<option value="">Select Chapter first</option>';
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }

        if (e.target.classList.contains('task-inline-update-form')) {
            e.preventDefault();
            try {
                var updateData = formToObject(e.target);
                await callApi('PUT', '/api/v1/tasks/' + updateData.taskId, {
                    assistantId: updateData.assistantId,
                    pageRangeStart: updateData.pageRangeStart,
                    pageRangeEnd: updateData.pageRangeEnd,
                    taskType: updateData.taskType,
                    dueDate: updateData.dueDate
                });
                showMessage('Task updated successfully.', false);
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }

        if (e.target.classList.contains('task-inline-status-form')) {
            e.preventDefault();
            try {
                var statusData = formToObject(e.target);
                await callApi('PATCH', '/api/v1/tasks/' + statusData.taskId + '/status', { status: statusData.status });
                showMessage('Task status updated.', false);
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }
    });

    loadData();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
