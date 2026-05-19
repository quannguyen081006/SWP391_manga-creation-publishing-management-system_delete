<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapters</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Chapters</h2>
<p class="page-sub">Track each chapter and current chapter progress</p>

<div id="chapterActions" class="section-card" style="display:none;">
    <div class="section-head">
        <div>
            <h3 class="section-title">Chapter Actions</h3>
            <p class="section-desc">Click an action button to open form</p>
        </div>
    </div>

    <div id="chapterResult" class="alert error" style="display:none;"></div>

    <div class="inline-meta" style="margin: 0 0 12px 0; gap: 10px;">
        <button class="btn" type="button" data-pane="chapterCreatePane">Create Chapter</button>
        <button class="btn" type="button" data-pane="chapterSubmitPane">Submit Review</button>
    </div>

    <form id="chapterCreateForm" class="panel form-grid chapter-pane" style="display:none; max-width:560px;" data-pane-id="chapterCreatePane">
        <strong>Create Chapter</strong>
        <select id="createSeriesId" name="seriesId" required>
            <option value="">Loading series...</option>
        </select>
        <input name="chapterNumber" type="number" min="1" placeholder="Chapter Number" required />
        <input name="title" type="text" placeholder="Title" required />
        <label class="field-label" for="chapterCreatePublicationDate">Publication Date</label>
        <input id="chapterCreatePublicationDate" name="publicationDate" type="date" aria-label="Publication Date" required />
        <button class="btn primary" type="submit">Create</button>
    </form>

    <form id="chapterSubmitForm" class="panel form-grid chapter-pane" style="display:none; max-width:560px;" data-pane-id="chapterSubmitPane">
        <strong>Submit For Review</strong>
        <select id="submitChapterId" name="chapterId" required>
            <option value="">Loading chapters...</option>
        </select>
        <button class="btn" type="submit">Submit Review</button>
        <small class="section-desc">Only owner Mangaka can submit, and chapter must be 100% complete with status In Progress or Complete.</small>
    </form>
</div>

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
                <th id="chapterActionHeader" style="display:none;">Actions</th>
            </tr>
        </thead>
        <tbody id="chapterRows">
            <tr><td colspan="8">Loading chapters...</td></tr>
        </tbody>
    </table>
</div>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var box = document.getElementById('chapterResult');
    var currentUser = null;
    var seriesList = [];
    var chapters = [];
    var seriesById = {};
    var currentPaneId = '';

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

    function isOwnSeries(seriesId) {
        var s = seriesById[String(seriesId)];
        return hasRole('MANGAKA') && s && Number(s.mangakaId) === Number(currentUser.id);
    }

    function formatStatus(status) {
        if (!status) {
            return '';
        }
        return String(status).toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, function (ch) { return ch.toUpperCase(); });
    }

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

    function togglePane(targetPaneId) {
        currentPaneId = (currentPaneId === targetPaneId) ? '' : targetPaneId;
        var panes = document.querySelectorAll('.chapter-pane');
        for (var i = 0; i < panes.length; i++) {
            var pane = panes[i];
            pane.style.display = (currentPaneId && pane.getAttribute('data-pane-id') === currentPaneId) ? 'grid' : 'none';
        }
    }

    function canSubmitChapter(ch) {
        var status = String(ch.status || '').toUpperCase();
        return Number(ch.completionPct || 0) >= 100 && (status === 'IN_PROGRESS' || status === 'COMPLETE');
    }

    function renderChapterActions() {
        var actions = document.getElementById('chapterActions');
        var header = document.getElementById('chapterActionHeader');
        if (!hasRole('MANGAKA')) {
            actions.style.display = 'none';
            header.style.display = 'none';
            return;
        }

        actions.style.display = 'block';
        header.style.display = '';

        var seriesSelect = document.getElementById('createSeriesId');
        var ownSeries = seriesList.filter(function (s) { return Number(s.mangakaId) === Number(currentUser.id); });
        seriesSelect.innerHTML = '<option value="">Select Series</option>' + ownSeries.map(function (s) {
            return '<option value="' + s.id + '">#' + s.id + ' - ' + escapeHtml(s.title) + '</option>';
        }).join('');

        var submitSelect = document.getElementById('submitChapterId');
        var ownChapters = chapters.filter(function (ch) { return isOwnSeries(ch.seriesId); });
        submitSelect.innerHTML = '<option value="">Select Chapter</option>' + ownChapters.map(function (ch) {
            var ready = canSubmitChapter(ch);
            return '<option value="' + ch.id + '" ' + (ready ? '' : 'disabled') + '>#' + ch.id + ' - S' + ch.seriesId + ' - Ch.' + ch.chapterNumber + ' - ' + escapeHtml(ch.title) + (ready ? '' : ' (Not ready: must be 100% complete)') + '</option>';
        }).join('');
    }

    function renderChapters() {
        var tbody = document.getElementById('chapterRows');
        var showActions = hasRole('MANGAKA');
        if (!chapters.length) {
            tbody.innerHTML = '<tr><td colspan="8">No chapters found.</td></tr>';
            return;
        }

        tbody.innerHTML = chapters.map(function (ch) {
            var progress = Math.max(0, Math.min(100, Number(ch.completionPct || 0)));
            var own = isOwnSeries(ch.seriesId);
            var actionCell = showActions ? '<td>' + (own ? '<button class="btn small" type="button" data-inline-update="chapterUpdateRow' + ch.id + '">Update</button>' : '') + '</td>' : '';
            var updateRow = '';
            if (showActions && own) {
                updateRow = '<tr id="chapterUpdateRow' + ch.id + '" class="chapter-update-row" style="display:none;">'
                    + '<td colspan="8"><form class="panel form-grid chapter-inline-update-form" style="max-width:720px;">'
                    + '<strong>Update Ch.' + ch.chapterNumber + ' - ' + escapeHtml(ch.title) + '</strong>'
                    + '<input name="chapterId" type="hidden" value="' + ch.id + '" />'
                    + '<input name="title" type="text" value="' + escapeHtml(ch.title) + '" placeholder="New Title" required />'
                    + '<label class="field-label" for="chapterUpdatePublicationDate' + ch.id + '">Publication Date</label>'
                    + '<input id="chapterUpdatePublicationDate' + ch.id + '" name="publicationDate" type="date" value="' + escapeHtml(ch.publicationDate || '') + '" aria-label="Publication Date" required />'
                    + '<button class="btn" type="submit">Update</button>'
                    + '</form></td></tr>';
            }

            return '<tr>'
                + '<td>' + ch.id + '</td>'
                + '<td>' + ch.seriesId + '</td>'
                + '<td>' + ch.chapterNumber + '</td>'
                + '<td>' + escapeHtml(ch.title) + '</td>'
                + '<td>' + formatStatus(ch.status) + '</td>'
                + '<td style="min-width: 220px;"><div class="inline-meta" style="justify-content:space-between; margin-bottom:6px;"><span>' + progress.toFixed(1) + '%</span></div><div class="progress ' + (progress < 40 ? 'red' : '') + '" style="margin-top:0;"><span style="width:' + progress + '%;"></span></div></td>'
                + '<td><span class="status-chip ' + (ch.atRisk ? 'status-rejected' : 'status-approved') + '">' + (ch.atRisk ? 'AT RISK' : 'NORMAL') + '</span></td>'
                + actionCell
                + '</tr>' + updateRow;
        }).join('');
    }

    async function loadData() {
        try {
            var userRes = await callApi('GET', '/api/v1/auth/me');
            currentUser = userRes.data;
            var results = await Promise.all([
                callApi('GET', '/api/v1/series'),
                callApi('GET', '/api/v1/chapters')
            ]);
            seriesList = results[0].data || [];
            chapters = results[1].data || [];
            seriesById = {};
            for (var i = 0; i < seriesList.length; i++) {
                seriesById[String(seriesList[i].id)] = seriesList[i];
            }
            renderChapterActions();
            renderChapters();
        } catch (err) {
            document.getElementById('chapterRows').innerHTML = '<tr><td colspan="8">' + escapeHtml(err.message) + '</td></tr>';
        }
    }

    document.addEventListener('click', function (e) {
        var paneButton = e.target.closest ? e.target.closest('[data-pane]') : null;
        if (paneButton) {
            togglePane(paneButton.getAttribute('data-pane'));
            return;
        }

        var updateButton = e.target.closest ? e.target.closest('[data-inline-update]') : null;
        if (updateButton) {
            var targetId = updateButton.getAttribute('data-inline-update');
            var targetRow = document.getElementById(targetId);
            var shouldShow = targetRow && targetRow.style.display !== 'table-row';
            var rows = document.querySelectorAll('.chapter-update-row');
            for (var i = 0; i < rows.length; i++) {
                rows[i].style.display = 'none';
            }
            if (shouldShow) {
                targetRow.style.display = 'table-row';
            }
        }
    });

    document.addEventListener('submit', async function (e) {
        if (e.target.id === 'chapterCreateForm') {
            e.preventDefault();
            try {
                var createData = formToObject(e.target);
                await callApi('POST', '/api/v1/series/' + createData.seriesId + '/chapters', {
                    chapterNumber: createData.chapterNumber,
                    title: createData.title,
                    publicationDate: createData.publicationDate
                });
                showMessage('Chapter created successfully.', false);
                e.target.reset();
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }

        if (e.target.classList.contains('chapter-inline-update-form')) {
            e.preventDefault();
            try {
                var updateData = formToObject(e.target);
                await callApi('PUT', '/api/v1/chapters/' + updateData.chapterId, {
                    title: updateData.title,
                    publicationDate: updateData.publicationDate
                });
                showMessage('Chapter metadata updated.', false);
                await loadData();
            } catch (err) {
                showMessage(err.message, true);
            }
        }

        if (e.target.id === 'chapterSubmitForm') {
            e.preventDefault();
            try {
                var submitData = formToObject(e.target);
                await callApi('POST', '/api/v1/chapters/' + submitData.chapterId + '/submit-review');
                showMessage('Chapter submitted for review.', false);
                e.target.reset();
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
