<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapters</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />
<c:set var="isMangaka" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('MANGAKA')}" />

<h2 class="page-title">Chapters</h2>
<p class="page-sub">Track each chapter and current chapter progress</p>

<c:if test="${isMangaka}">
<div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title">Chapter Actions</h3>
            <p class="section-desc">Click an action button to open form</p>
        </div>
    </div>

    <div id="chapterResult" class="alert error" style="display:none;"></div>

    <div class="inline-meta" style="margin: 0 0 12px 0; gap: 10px;">
        <button class="btn" type="button" data-pane="chapterCreatePane">Create Chapter</button>
        <button class="btn" type="button" data-pane="chapterUpdatePane">Update Metadata</button>
        <button class="btn" type="button" data-pane="chapterSubmitPane">Submit Review</button>
    </div>

    <form id="chapterCreateForm" class="panel form-grid chapter-pane" style="display:none; max-width:560px;" data-pane-id="chapterCreatePane">
        <strong>Create Chapter</strong>
        <input name="seriesId" type="number" min="1" placeholder="Series ID" required />
        <input name="chapterNumber" type="number" min="1" placeholder="Chapter Number" required />
        <input name="title" type="text" placeholder="Title" required />
        <input name="publicationDate" type="date" required />
        <button class="btn primary" type="submit">Create</button>
    </form>

    <form id="chapterUpdateForm" class="panel form-grid chapter-pane" style="display:none; max-width:560px;" data-pane-id="chapterUpdatePane">
        <strong>Update Chapter Metadata</strong>
        <input name="chapterId" type="number" min="1" placeholder="Chapter ID" required />
        <input name="title" type="text" placeholder="New Title" required />
        <input name="publicationDate" type="date" required />
        <button class="btn" type="submit">Update</button>
    </form>

    <form id="chapterSubmitForm" class="panel form-grid chapter-pane" style="display:none; max-width:560px;" data-pane-id="chapterSubmitPane">
        <strong>Submit For Review</strong>
        <input name="chapterId" type="number" min="1" placeholder="Chapter ID" required />
        <button class="btn" type="submit">Submit Review</button>
        <small class="section-desc">Only owner Mangaka, and chapter must be 100% complete.</small>
    </form>
</div>
</c:if>

<div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title">Chapter Tracker</h3>
            <p class="section-desc">Current chapter progress across your series</p>
        </div>
    </div>

    <table class="data-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Series</th>
                <th>No.</th>
                <th>Title</th>
                <th>Status</th>
                <th>Current Chapter Progress</th>
                <th>At Risk</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${chapters}" var="c">
                <tr>
                    <td>${c.id}</td>
                    <td>${c.seriesId}</td>
                    <td>${c.chapterNumber}</td>
                    <td>${c.title}</td>
                    <td>${c.status}</td>
                    <td style="min-width: 220px;">
                        <div class="inline-meta" style="justify-content:space-between; margin-bottom:6px;">
                            <span>${c.completionPct}%</span>
                        </div>
                        <div class="progress ${c.completionPct lt 40 ? 'red' : ''}" style="margin-top:0;">
                            <span style="width:${c.completionPct}%;"></span>
                        </div>
                    </td>
                    <td>
                        <span class="status-chip ${c.atRisk ? 'status-rejected' : 'status-approved'}">${c.atRisk ? 'AT RISK' : 'NORMAL'}</span>
                    </td>
                </tr>
            </c:forEach>
            <c:if test="${empty chapters}">
                <tr>
                    <td colspan="7">No chapters found.</td>
                </tr>
            </c:if>
        </tbody>
    </table>
</div>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var box = document.getElementById('chapterResult');

    function showMessage(msg, isError) {
        if (!box) {
            return;
        }
        box.style.display = 'block';
        box.className = isError ? 'alert error' : 'panel';
        box.textContent = msg;
    }

    function formToObject(form) {
        var data = {};
        var fd = new FormData(form);
        fd.forEach(function (v, k) { data[k] = v; });
        return data;
    }

    var currentPaneId = '';

    function togglePane(targetPaneId) {
        currentPaneId = (currentPaneId === targetPaneId) ? '' : targetPaneId;
        var panes = document.querySelectorAll('.chapter-pane');
        for (var i = 0; i < panes.length; i++) {
            var pane = panes[i];
            pane.style.display = (currentPaneId && pane.getAttribute('data-pane-id') === currentPaneId) ? 'grid' : 'none';
        }
    }

    var actionButtons = document.querySelectorAll('[data-pane]');
    for (var i = 0; i < actionButtons.length; i++) {
        actionButtons[i].addEventListener('click', function () {
            togglePane(this.getAttribute('data-pane'));
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

    var createForm = document.getElementById('chapterCreateForm');
    if (createForm) {
        createForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var data = formToObject(createForm);
                await callApi('POST', '/api/v1/series/' + data.seriesId + '/chapters', {
                    chapterNumber: data.chapterNumber,
                    title: data.title,
                    publicationDate: data.publicationDate
                });
                showMessage('Chapter created successfully.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var updateForm = document.getElementById('chapterUpdateForm');
    if (updateForm) {
        updateForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var data = formToObject(updateForm);
                await callApi('PUT', '/api/v1/chapters/' + data.chapterId, {
                    title: data.title,
                    publicationDate: data.publicationDate
                });
                showMessage('Chapter metadata updated.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    var submitForm = document.getElementById('chapterSubmitForm');
    if (submitForm) {
        submitForm.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var data = formToObject(submitForm);
                await callApi('POST', '/api/v1/chapters/' + data.chapterId + '/submit-review');
                showMessage('Chapter submitted for review.', false);
                setTimeout(function () { location.reload(); }, 600);
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
