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
<c:set var="isMangaka" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('MANGAKA')}" />
<c:set var="isAssistant" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('ASSISTANT')}" />

<h2 class="page-title">Tasks</h2>
<p class="page-sub">Manage page tasks for your series</p>

<c:if test="${overdueTasks > 0}">
    <div class="alert-box"><strong>${overdueTasks} Overdue Task</strong><br/>These tasks have passed their due date and need immediate attention.</div>
</c:if>

<section class="metric-grid">
    <article class="metric-card"><div class="metric-value">${activeTasks}</div><div class="metric-label">Active</div></article>
    <article class="metric-card"><div class="metric-value metric-violet">${submittedTasks}</div><div class="metric-label">Submitted</div></article>
    <article class="metric-card"><div class="metric-value metric-danger">${overdueTasks}</div><div class="metric-label">Overdue</div></article>
    <article class="metric-card"><div class="metric-value metric-ok">${completedTasks}</div><div class="metric-label">Completed</div></article>
</section>

<c:if test="${isMangaka || isAssistant}"><div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title">Task Actions</h3>
            <p class="section-desc">Click an action button to open form</p>
        </div>
    </div>

    <div id="taskResult" class="alert error" style="display:none;"></div>

    <div class="inline-meta" style="margin: 0 0 12px 0; gap: 10px;">
        <c:if test="${isMangaka}">
            <button class="btn" type="button" data-task-pane="taskCreatePane">Create Task</button>
            <button class="btn" type="button" data-task-pane="taskUpdatePane">Reassign / Update</button>
            <button class="btn" type="button" data-task-pane="taskDecisionPane">Approve / Reject</button>
        </c:if>
        <c:if test="${isAssistant}">
            <button class="btn" type="button" data-task-pane="taskStatusPane">Update Status</button>
        </c:if>
        <button class="btn" type="button" data-task-pane="taskDetailPane">Task Detail</button>
    </div>

    <c:if test="${isMangaka}">
        <form id="taskCreateForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskCreatePane">
            <strong>Create Task</strong>
            <input name="chapterId" type="number" min="1" placeholder="Chapter ID" required />
            <input name="assistantId" type="number" min="1" placeholder="Assistant ID" required />
            <input name="pageRangeStart" type="number" min="1" placeholder="Page Start" required />
            <input name="pageRangeEnd" type="number" min="1" placeholder="Page End" required />
            <input name="taskType" type="text" placeholder="Task Type" required />
            <input name="dueDate" type="date" required />
            <button class="btn primary" type="submit">Create</button>
        </form>

        <form id="taskUpdateForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskUpdatePane">
            <strong>Reassign / Update Task</strong>
            <input name="taskId" type="number" min="1" placeholder="Task ID" required />
            <input name="assistantId" type="number" min="1" placeholder="Assistant ID" required />
            <input name="pageRangeStart" type="number" min="1" placeholder="Page Start" required />
            <input name="pageRangeEnd" type="number" min="1" placeholder="Page End" required />
            <input name="taskType" type="text" placeholder="Task Type" required />
            <input name="dueDate" type="date" required />
            <button class="btn" type="submit">Update</button>
        </form>

        <form id="taskDecisionForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskDecisionPane">
            <strong>Mangaka Decision</strong>
            <input name="taskId" type="number" min="1" placeholder="Task ID" required />
            <button class="btn" type="button" id="approveTaskBtn">Approve</button>
            <button class="btn" type="button" id="rejectTaskBtn">Reject</button>
        </form>
    </c:if>

    <c:if test="${isAssistant}">
        <form id="taskStatusForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskStatusPane">
            <strong>Assistant Update Status</strong>
            <input name="taskId" type="number" min="1" placeholder="Task ID" required />
            <select name="status" required>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="SUBMITTED">Submitted</option>
            </select>
            <button class="btn" type="submit">Update Status</button>
        </form>
    </c:if>

    <form id="taskDetailForm" class="panel form-grid task-pane" style="display:none; max-width:640px;" data-task-pane-id="taskDetailPane">
        <strong>Task Detail</strong>
        <input name="taskId" type="number" min="1" placeholder="Task ID" required />
        <button class="btn" type="submit">Load Detail</button>
        <pre id="taskDetailOutput" style="white-space:pre-wrap;background:#f8fafc;border:1px solid #e5e7eb;border-radius:8px;padding:8px;font-size:12px;min-height:70px;"></pre>
    </form>
</div>

</c:if>
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
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${tasks}" var="t">
                <tr>
                    <td>${t.id}</td>
                    <td><strong>${t.seriesTitle}</strong><br/>Ch. ${t.chapterNumber} - ${t.chapterTitle}</td>
                    <td>${t.pageRangeStart}-${t.pageRangeEnd}</td>
                    <td>${t.taskType}</td>
                    <td>${t.assistantName}</td>
                    <td>
                        <span class="status-chip ${t.status=='OVERDUE' ? 'status-overdue' : (t.status=='IN_PROGRESS' ? 'status-progress' : (t.status=='PENDING' ? 'status-pending' : (t.status=='APPROVED' ? 'status-approved' : 'status-draft')))}">${t.status=='IN_PROGRESS' ? 'In Progress' : (t.status=='PENDING' ? 'Pending' : (t.status=='SUBMITTED' ? 'Submitted' : (t.status=='APPROVED' ? 'Approved' : (t.status=='REJECTED' ? 'Rejected' : (t.status=='OVERDUE' ? 'Overdue' : t.status)))) )}</span>
                    </td>
                    <td>${t.dueDate}</td>
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

    function showMessage(msg, isError) {
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

    var currentTaskPaneId = '';

    function toggleTaskPane(targetPaneId) {
        currentTaskPaneId = (currentTaskPaneId === targetPaneId) ? '' : targetPaneId;
        var panes = document.querySelectorAll('.task-pane');
        for (var i = 0; i < panes.length; i++) {
            var pane = panes[i];
            pane.style.display = (currentTaskPaneId && pane.getAttribute('data-task-pane-id') === currentTaskPaneId) ? 'grid' : 'none';
        }
    }

    var actionButtons = document.querySelectorAll('[data-task-pane]');
    for (var i = 0; i < actionButtons.length; i++) {
        actionButtons[i].addEventListener('click', function () {
            toggleTaskPane(this.getAttribute('data-task-pane'));
        });
    }

    async function callApi(method, path, data) {
        var opts = { method: method, headers: { 'Accept': 'application/json' } };
        if (data) {
            opts.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
            opts.body = new URLSearchParams(data).toString();
        }

        var res = await fetch(ctx + path, opts);
        var body = null;
        try { body = await res.json(); } catch (e) {}

        if (!res.ok || (body && body.success === false)) {
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || ('Request failed: HTTP ' + res.status);
            throw new Error(msg);
        }

        return body;
    }

    var createForm = document.getElementById('taskCreateForm');
    if (createForm) {
        createForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var d = formToObject(createForm);
                await callApi('POST', '/api/v1/chapters/' + d.chapterId + '/tasks', {
                    assistantId: d.assistantId,
                    pageRangeStart: d.pageRangeStart,
                    pageRangeEnd: d.pageRangeEnd,
                    taskType: d.taskType,
                    dueDate: d.dueDate
                });
                showMessage('Task created successfully.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var updateForm = document.getElementById('taskUpdateForm');
    if (updateForm) {
        updateForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var d = formToObject(updateForm);
                await callApi('PUT', '/api/v1/tasks/' + d.taskId, {
                    assistantId: d.assistantId,
                    pageRangeStart: d.pageRangeStart,
                    pageRangeEnd: d.pageRangeEnd,
                    taskType: d.taskType,
                    dueDate: d.dueDate
                });
                showMessage('Task updated successfully.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var statusForm = document.getElementById('taskStatusForm');
    if (statusForm) {
        statusForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var d = formToObject(statusForm);
                await callApi('PATCH', '/api/v1/tasks/' + d.taskId + '/status', { status: d.status });
                showMessage('Task status updated.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var decisionForm = document.getElementById('taskDecisionForm');
    if (decisionForm) {
        document.getElementById('approveTaskBtn').addEventListener('click', async function () {
            try {
                var d = formToObject(decisionForm);
                await callApi('POST', '/api/v1/tasks/' + d.taskId + '/approve');
                showMessage('Task approved.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });

        document.getElementById('rejectTaskBtn').addEventListener('click', async function () {
            try {
                var d = formToObject(decisionForm);
                await callApi('POST', '/api/v1/tasks/' + d.taskId + '/reject');
                showMessage('Task rejected.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var detailForm = document.getElementById('taskDetailForm');
    var detailOut = document.getElementById('taskDetailOutput');
    if (detailForm) {
        detailForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var d = formToObject(detailForm);
                var body = await callApi('GET', '/api/v1/tasks/' + d.taskId);
                detailOut.textContent = JSON.stringify(body.data, null, 2);
                showMessage('Task detail loaded.', false);
            } catch (err) {
                detailOut.textContent = '';
                showMessage(err.message, true);
            }
        });
    }
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>