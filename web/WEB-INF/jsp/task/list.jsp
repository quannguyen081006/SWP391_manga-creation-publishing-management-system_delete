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
            <p class="section-desc">Create a task in a small popup. New assignments start In Progress.</p>
        </div>
        <button class="btn primary" type="button" data-modal-open="taskCreateModal">Create Task</button>
    </div>
</div>

<div id="taskCreateModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="taskCreateTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="taskCreateTitle" class="section-title compact-title">Create Task</h3>
        <form id="taskCreateForm" class="form-grid">
        <strong>Create Task</strong>
        <select id="createTaskChapterId" name="chapterId" required>
            <option value="">Loading chapters...</option>
        </select>
        <p id="createTaskDeadlineHint" class="section-desc"></p>
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
        <div id="taskCreateError" class="alert error" style="display:none;"></div>
        <button class="btn primary" type="submit">Create</button>
        </form>
    </div>
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
            <c:if test="${empty tasks}"><tr><td colspan="8">No tasks found.</td></tr></c:if>
        </tbody>
    </table>
</div>

<div id="taskViewModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card modal-card-wide" role="dialog" aria-modal="true" aria-labelledby="taskViewTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="taskViewTitle" class="section-title compact-title">Task Detail</h3>
        <p id="taskViewSubtitle" class="section-desc"></p>
        <div id="taskViewDetail" class="panel" style="margin-top:12px;">Loading detail...</div>
        <div id="taskViewOwnerTools" style="margin-top:14px;"></div>
        <div id="taskViewMangakaActions"></div>
        <div class="section-head" style="margin-top:16px;">
            <div>
                <strong>Task Images</strong>
                <p class="section-desc">Page images uploaded for this task</p>
            </div>
        </div>
        <div id="taskViewImages">Loading images...</div>
        <div id="taskViewAssistantActions" class="detail-actions modal-actions modal-actions-bottom"></div>
    </div>
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

    function escapeHtml(value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value).replace(/[&<>"]/g, function (ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[ch];
        });
    }

    function formatDate(value) {
        if (value === null || value === undefined || value === '') {
            return '';
        }
        var text = String(value);
        if (/^\d+$/.test(text)) {
            var date = new Date(Number(text));
            if (isNaN(date.getTime())) {
                return text;
            }
            var month = String(date.getMonth() + 1);
            var day = String(date.getDate());
            return date.getFullYear() + '-' + (month.length < 2 ? '0' + month : month) + '-' + (day.length < 2 ? '0' + day : day);
        }
        if (text.indexOf('T') > -1) {
            return text.substring(0, 10);
        }
        return text;
    }

    function dateOnly(value) {
        var formatted = formatDate(value);
        return formatted ? new Date(formatted + 'T00:00:00') : null;
    }

    function todayIso() {
        var date = new Date();
        var month = String(date.getMonth() + 1);
        var day = String(date.getDate());
        return date.getFullYear() + '-' + (month.length < 2 ? '0' + month : month) + '-' + (day.length < 2 ? '0' + day : day);
    }

    function addDaysIso(value, days) {
        var date = dateOnly(value);
        if (!date) { return ''; }
        date.setDate(date.getDate() + days);
        var month = String(date.getMonth() + 1);
        var day = String(date.getDate());
        return date.getFullYear() + '-' + (month.length < 2 ? '0' + month : month) + '-' + (day.length < 2 ? '0' + day : day);
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

    function showModalError(msg) {
        var el = document.getElementById('taskCreateError');
        if (!el) {
            return;
        }
        el.style.display = 'block';
        el.textContent = msg;
    }

    function clearModalError() {
        var el = document.getElementById('taskCreateError');
        if (!el) {
            return;
        }
        el.style.display = 'none';
        el.textContent = '';
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

    function openModal(id) {
        var modal = document.getElementById(id);
        if (modal) {
            if (id === 'taskCreateModal') {
                clearModalError();
            }
            modal.classList.add('open');
            modal.setAttribute('aria-hidden', 'false');
        }
    }

    function closeModals() {
        var modals = document.querySelectorAll('.modal-backdrop');
        for (var i = 0; i < modals.length; i++) {
            modals[i].classList.remove('open');
            modals[i].setAttribute('aria-hidden', 'true');
        }
    }

    async function uploadMultipart(path, form) {
        var fd = new FormData(form);
        var file = form.querySelector('input[type="file"]');
        if (file && (!file.files || file.files.length === 0)) {
            fd.delete('file');
        }
        var res = await fetch(ctx + path, { method: 'POST', headers: { 'Accept': 'application/json' }, body: fd });
        var text = await res.text();
        var body = null;
        try { body = text ? JSON.parse(text) : null; } catch (e) {}
        if (!res.ok || (body && body.success === false)) {
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || text || ('Request failed: HTTP ' + res.status);
            throw new Error(msg);
        }
        return body;
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

    function updateCreateTaskDeadlineHint(chapter) {
        var hint = document.getElementById('createTaskDeadlineHint');
        var dueDateInput = document.getElementById('taskCreateDueDate');
        if (dueDateInput) {
            dueDateInput.min = todayIso();
            dueDateInput.removeAttribute('max');
        }
        var latestDueDate = chapter && chapter.submissionDeadline ? addDaysIso(chapter.submissionDeadline, -3) : '';
        if (dueDateInput && latestDueDate) {
            dueDateInput.max = latestDueDate;
        }
        if (!hint) {
            return;
        }
        hint.textContent = chapter && chapter.submissionDeadline
            ? ('Chapter deadline: ' + formatDate(chapter.submissionDeadline) + '. Task due date must be between today and ' + latestDueDate + '.')
            : '';
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
                var due = dateOnly(t.dueDate);
                if (due && due < today) { overdue++; }
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

    function canAssistantSubmit(task) {
        var st = String(task.status || '').toUpperCase();
        return isAssignedAssistant(task) && (st === 'IN_PROGRESS' || st === 'REJECTED' || st === 'OVERDUE');
    }

    function renderUpdateForm(task) {
        var chapter = chapterById[String(task.chapterId)];
        var seriesId = chapter ? chapter.seriesId : '';
        var latestDueDate = chapter && chapter.submissionDeadline ? addDaysIso(chapter.submissionDeadline, -3) : '';
        var dueDateAttrs = ' min="' + todayIso() + '"' + (latestDueDate ? ' max="' + escapeHtml(latestDueDate) + '"' : '');
        var deadlineHelp = chapter && chapter.submissionDeadline
            ? '<p class="section-desc">Chapter deadline: ' + escapeHtml(formatDate(chapter.submissionDeadline)) + '. Task due date must be between today and ' + escapeHtml(latestDueDate) + '.</p>'
            : '<p class="section-desc">Task due date cannot be in the past.</p>';
        return '<form class="panel form-grid task-inline-update-form" style="max-width:640px;">'
            + '<strong>Reassign / Update Task #' + task.id + '</strong>'
            + '<input name="taskId" type="hidden" value="' + task.id + '" />'
            + '<select class="assistant-select" name="assistantId" data-series-id="' + seriesId + '" data-selected-assistant-id="' + task.assistantId + '" required><option value="">Open form to load assistants</option></select>'
            + '<input name="pageRangeStart" type="number" min="1" value="' + task.pageRangeStart + '" placeholder="Page Start" required />'
            + '<input name="pageRangeEnd" type="number" min="1" value="' + task.pageRangeEnd + '" placeholder="Page End" required />'
            + renderTaskTypeSelect(task.taskType)
            + '<label class="field-label" for="taskUpdateDueDate' + task.id + '">Due Date</label>'
            + deadlineHelp
            + '<input id="taskUpdateDueDate' + task.id + '" name="dueDate" type="date" value="' + escapeHtml(formatDate(task.dueDate)) + '" aria-label="Due Date"' + dueDateAttrs + ' required />'
            + '<button class="btn" type="submit">Update</button>'
            + '</form>';
    }

    function renderImageForm(task) {
        var uploadForm = '';
        if (isAssignedAssistant(task)) {
            uploadForm = '<form class="form-grid task-image-upload-form" data-task-id="' + task.id + '" data-chapter-id="' + task.chapterId + '" style="display:grid; max-width:680px;margin-bottom:12px;">'
                + '<strong>Upload Page Image</strong>'
                + '<input name="imageType" type="hidden" value="PAGE" />'
                + '<input name="pageTaskId" type="hidden" value="' + task.id + '" />'
                + '<input name="pageNumber" type="number" min="1" placeholder="Page Number" required />'
                + '<input name="file" type="file" accept="image/*" required />'
                + '<button class="btn primary" type="submit">Upload Image</button>'
                + '</form>';
        } else if (hasRole('MANGAKA')) {
            uploadForm = '<p class="section-desc">PAGE images can be uploaded only by the assistant assigned to this task. Use Chapters > Images to upload cover/reference images.</p>';
        } else if (hasRole('TANTOU_EDITOR')) {
            uploadForm = '<p class="section-desc">Tantou editor has read-only access to task images.</p>';
        }
        return '<div class="panel">'
            + uploadForm
            + '<div class="task-image-list" data-task-image-list="' + task.id + '">Loading images...</div>'
            + '</div>';
    }

    function renderImages(images) {
        if (!images.length) {
            return '<p class="section-desc">No images uploaded yet.</p>';
        }
        return '<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px;">' + images.map(function (img) {
            var url = imageUrl(img.fileUrl);
            var deleteButton = canDeleteImage(img)
                ? '<button class="btn small danger-soft" type="button" data-task-image-delete="' + img.id + '" data-task-id="' + img.pageTaskId + '">Delete</button>'
                : '';
            return '<div class="panel" style="margin:0;padding:10px;">'
                + '<a href="' + escapeHtml(url) + '" target="_blank"><img src="' + escapeHtml(url) + '" alt="' + escapeHtml(img.originalFileName || ('Page ' + img.pageNumber)) + '" style="width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:8px;border:1px solid #e5e7eb;" /></a>'
                + '<div style="margin-top:8px;font-weight:700;">Page ' + escapeHtml(img.pageNumber || '') + '</div>'
                + '<div class="section-desc">' + escapeHtml(img.originalFileName || '') + '</div>'
                + deleteButton
                + '</div>';
        }).join('') + '</div>';
    }

    function canDeleteImage(img) {
        return currentUser && (Number(img.uploadedBy) === Number(currentUser.id) || hasRole('MANGAKA'));
    }

    function imageUrl(fileUrl) {
        var url = String(fileUrl || '');
        if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0) {
            return url;
        }
        if (url.indexOf(ctx + '/') === 0) {
            return url;
        }
        return ctx + url;
    }

    async function loadTaskImages(taskId) {
        var target = document.querySelector('[data-task-image-list="' + taskId + '"]');
        if (!target) {
            return;
        }
        target.innerHTML = 'Loading images...';
        try {
            var res = await callApi('GET', '/api/v1/tasks/' + taskId + '/images');
            target.innerHTML = renderImages(res.data || []);
        } catch (err) {
            target.innerHTML = '<div class="alert error">' + escapeHtml(err.message) + '</div>';
        }
    }

    function renderTaskDetail(task) {
        return '<strong>Task #' + task.id + ' Detail</strong>'
            + '<div class="inline-meta" style="margin-top:10px;gap:14px;">'
            + '<span>Pages: ' + task.pageRangeStart + '-' + task.pageRangeEnd + '</span>'
            + '<span>Type: ' + formatStatus(task.taskType) + '</span>'
            + '<span>Assigned: ' + escapeHtml(task.assistantName) + '</span>'
            + '<span>Status: ' + formatStatus(task.status) + '</span>'
            + '<span>Due Date: ' + escapeHtml(formatDate(task.dueDate)) + '</span>'
            + '</div>';
    }

    function findTask(taskId) {
        for (var i = 0; i < tasks.length; i++) {
            if (Number(tasks[i].id) === Number(taskId)) {
                return tasks[i];
            }
        }
        return null;
    }

    function renderTasks() {
        var tbody = document.getElementById('taskRows');
        if (!tasks.length) {
            tbody.innerHTML = '<tr><td colspan="8">No tasks found.</td></tr>';
            return;
        }

        tbody.innerHTML = tasks.map(function (task) {
            var actionButtons = '<button class="btn small" type="button" data-task-view="' + task.id + '">View</button>';
            if (canAssistantSubmit(task)) {
                actionButtons += ' <button class="btn small primary" type="button" data-task-submit-review="' + task.id + '">Submit for Review</button>';
            }

            return '<tr>'
                + '<td>' + task.id + '</td>'
                + '<td><strong>' + escapeHtml(task.seriesTitle) + '</strong><br/>Ch. ' + escapeHtml(task.chapterNumber) + ' - ' + escapeHtml(task.chapterTitle) + '</td>'
                + '<td>' + task.pageRangeStart + '-' + task.pageRangeEnd + '</td>'
                + '<td>' + formatStatus(task.taskType) + '</td>'
                + '<td>' + escapeHtml(task.assistantName) + '</td>'
                + '<td><span class="status-chip ' + statusClass(task.status) + '">' + formatStatus(task.status) + '</span></td>'
                + '<td>' + escapeHtml(formatDate(task.dueDate)) + '</td>'
                + '<td><div class="inline-meta" style="gap:6px;margin:0;">' + actionButtons + '</div></td>'
                + '</tr>';
        }).join('');
    }

    async function openTaskView(taskId) {
        var task = findTask(taskId);
        if (!task) {
            return;
        }
        document.getElementById('taskViewTitle').textContent = 'Task #' + task.id;
        document.getElementById('taskViewSubtitle').textContent = (task.seriesTitle || '') + ' - Ch. ' + task.chapterNumber + ' - ' + (task.chapterTitle || '');
        document.getElementById('taskViewDetail').innerHTML = renderTaskDetail(task);
        document.getElementById('taskViewOwnerTools').innerHTML = isTaskOwner(task)
            ? renderUpdateForm(task)
            : '';
        var mangakaActionsEl = document.getElementById('taskViewMangakaActions');
        if (mangakaActionsEl) {
            var st = String(task.status || '').toUpperCase();
            if (isTaskOwner(task) && st === 'SUBMITTED') {
                mangakaActionsEl.innerHTML = '<div class="inline-meta" style="gap:8px;margin-top:12px;">'
                    + '<button class="btn success-soft" type="button" data-task-decision="approve" data-task-id="' + task.id + '">Approve</button>'
                    + '<button class="btn danger-soft" type="button" data-task-decision="reject" data-task-id="' + task.id + '">Reject</button>'
                    + '</div>';
            } else {
                mangakaActionsEl.innerHTML = '';
            }
        }
        var assistantActions = document.getElementById('taskViewAssistantActions');
        assistantActions.innerHTML = canAssistantSubmit(task)
            ? '<button class="btn small primary" type="button" data-task-submit-review="' + task.id + '">Submit for Review</button>'
            : '';
        assistantActions.style.display = assistantActions.innerHTML ? 'flex' : 'none';
        document.getElementById('taskViewImages').innerHTML = renderImageForm(task);
        openModal('taskViewModal');
        var updateSelect = document.querySelector('#taskViewOwnerTools .assistant-select');
        if (updateSelect) {
            await fillAssistantSelect(updateSelect, updateSelect.getAttribute('data-series-id'), updateSelect.getAttribute('data-selected-assistant-id'));
        }
        await loadTaskImages(taskId);
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
        var openButton = e.target.closest ? e.target.closest('[data-modal-open]') : null;
        if (openButton) {
            var modalId = openButton.getAttribute('data-modal-open');
            openModal(modalId);
            return;
        }
        if (e.target.closest && e.target.closest('[data-modal-close]')) { closeModals(); return; }
        if (e.target.classList && e.target.classList.contains('modal-backdrop')) { closeModals(); return; }

        var viewButton = e.target.closest ? e.target.closest('[data-task-view]') : null;
        if (viewButton) {
            await openTaskView(viewButton.getAttribute('data-task-view'));
            return;
        }

        var submitReviewButton = e.target.closest ? e.target.closest('[data-task-submit-review]') : null;
        if (submitReviewButton) {
            try {
                var submitTaskId = submitReviewButton.getAttribute('data-task-submit-review');
                await callApi('PATCH', '/api/v1/tasks/' + submitTaskId + '/status', { status: 'SUBMITTED' });
                showMessage('Task submitted for Mangaka review.', false);
                closeModals();
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
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
            return;
        }

        var imageDeleteButton = e.target.closest ? e.target.closest('[data-task-image-delete]') : null;
        if (imageDeleteButton) {
            if (!confirm('Delete this image?')) return;
            try {
                await callApi('DELETE', '/api/v1/images/' + imageDeleteButton.getAttribute('data-task-image-delete'));
                showMessage('Image deleted.', false);
                await loadTaskImages(imageDeleteButton.getAttribute('data-task-id'));
            } catch (err) {
                showMessage(err.message, true);
            }
            return;
        }
    });

    document.addEventListener('change', async function (e) {
        if (e.target.id === 'createTaskChapterId') {
            var chapter = chapterById[String(e.target.value)];
            var assistantSelect = document.getElementById('createTaskAssistantId');
            if (!chapter) {
                assistantSelect.innerHTML = '<option value="">Select Chapter first</option>';
                updateCreateTaskDeadlineHint(null);
                return;
            }
            updateCreateTaskDeadlineHint(chapter);
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
                updateCreateTaskDeadlineHint(null);
                clearModalError();
                closeModals();
                await loadData();
            } catch (err) {
                showModalError(err.message);
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
                closeModals();
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }

        if (e.target.classList.contains('task-image-upload-form')) {
            e.preventDefault();
            try {
                var imageTaskId = e.target.getAttribute('data-task-id');
                var imageChapterId = e.target.getAttribute('data-chapter-id');
                await uploadMultipart('/api/v1/chapters/' + imageChapterId + '/images', e.target);
                showMessage('Task image uploaded.', false);
                e.target.reset();
                await loadTaskImages(imageTaskId);
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
