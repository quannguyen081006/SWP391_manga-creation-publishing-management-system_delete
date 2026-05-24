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
<p id="chapterFilterSubtitle" class="section-desc" style="display:none;"></p>

<div id="chapterResult" class="alert error" style="display:none;"></div>

<div id="chapterActions" class="section-card" style="display:none;">
    <div class="section-head">
        <div>
            <h3 class="section-title">Chapter Actions</h3>
            <p class="section-desc">Create chapter. Submit review is inside View.</p>
        </div>
        <button class="btn primary" type="button" data-modal-open="chapterCreateModal">Create Chapter</button>
    </div>
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
                <th>No. <button class="btn small" style="padding:2px 6px;" type="button" data-sort="no" title="Sort by chapter number" aria-label="Sort by chapter number">↕</button></th>
                <th>Title
                    <button class="btn small" style="padding:2px 6px;margin-left:6px;" type="button" data-sort="title" title="Sort by title" aria-label="Sort by title">↕</button>
                </th>
                <th>Status <button class="btn small" style="padding:2px 6px;" type="button" data-sort="status" title="Sort by status" aria-label="Sort by status">↕</button></th>
                <th>Current Chapter Progress</th>
                <th>At Risk</th>
                <th>Deadline <button class="btn small" style="padding:2px 6px;" type="button" data-sort="deadline" title="Sort by deadline" aria-label="Sort by deadline">↕</button></th>
                <th id="chapterActionHeader" style="display:none;">Actions</th>
            </tr>
        </thead>
        <tbody id="chapterRows">
            <tr><td colspan="7">Loading chapters...</td></tr>
        </tbody>
    </table>
</div>

<div id="chapterCreateModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="chapterCreateTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="chapterCreateTitle" class="section-title compact-title">Create Chapter</h3>
        <form id="chapterCreateForm" class="form-grid">
            <select id="createSeriesId" name="seriesId" required>
                <option value="">Loading series...</option>
            </select>
            <p class="section-desc" id="nextChapterHint">Chapter number will be assigned automatically.</p>
            <p class="section-desc" id="createSeriesDeadlineHint"></p>
            <input name="title" type="text" placeholder="Title" required />
            <label class="field-label" for="chapterCreateDeadline">Submission Deadline</label>
            <input id="chapterCreateDeadline" name="submissionDeadline" type="date" required />
            <div id="chapterCreateError" class="alert error" style="display:none;margin-bottom:8px;"></div>
            <button class="btn primary" type="submit">Create</button>
        </form>
    </div>
</div>

<div id="chapterViewModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card modal-card-wide" role="dialog" aria-modal="true" aria-labelledby="chapterViewTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="chapterViewTitle" class="section-title compact-title">Chapter Detail</h3>
        <p id="chapterViewSubtitle" class="section-desc"></p>
        <div id="chapterViewMessage" class="alert error" style="display:none;margin-bottom:10px;"></div>
        <div id="chapterViewMeta" class="detail-grid"></div>
        <div id="chapterOwnerTools" style="margin-top:14px;"></div>
        <div class="section-head" style="margin-top:16px;">
            <div>
                <strong>Chapter Images</strong>
                <p class="section-desc">Cover and reference files for this chapter</p>
            </div>
        </div>
        <div id="chapterImageList">Loading images...</div>
        <div class="detail-actions modal-actions modal-actions-bottom">
            <button id="chapterSubmitReviewButton" class="btn small primary" type="button">Submit Review</button>
            <button class="btn small" type="button" data-modal-close>Close</button>
        </div>
        <p id="chapterSubmitHint" class="section-desc"></p>
    </div>
</div>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var box = document.getElementById('chapterResult');
    var currentUser = null;
    var seriesList = [];
    var chapters = [];
    var seriesById = {};
    var selectedChapter = null;
    var filterSeriesId = new URLSearchParams(window.location.search).get('seriesId');
    var sortField = null; // 'no' | 'title' | 'status' | 'deadline'
    var sortDir = 'asc';

    function escapeHtml(value) {
        if (value === null || value === undefined) { return ''; }
        return String(value).replace(/[&<>\"]/g, function (ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[ch];
        });
    }

    function formatDate(value) {
        if (value === null || value === undefined || value === '') { return ''; }
        var text = String(value);
        if (/^\d+$/.test(text)) {
            var date = new Date(Number(text));
            if (isNaN(date.getTime())) { return text; }
            var month = String(date.getMonth() + 1);
            var day = String(date.getDate());
            return date.getFullYear() + '-' + (month.length < 2 ? '0' + month : month) + '-' + (day.length < 2 ? '0' + day : day);
        }
        if (text.indexOf('T') > -1) { return text.substring(0, 10); }
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

    function latestChapterDeadline(series) {
        return series && series.publicationDate ? addDaysIso(series.publicationDate, -7) : '';
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
        if (!status) { return ''; }
        return String(status).toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, function (ch) { return ch.toUpperCase(); });
    }

    function showMessage(msg, isError) {
        if (!box) { return; }
        box.style.display = 'block';
        box.className = isError ? 'alert error' : 'panel';
        box.textContent = msg;
    }

    function showCreateError(msg) {
        var el = document.getElementById('chapterCreateError');
        if (!el) { return; }
        el.style.display = msg ? 'block' : 'none';
        el.textContent = msg || '';
    }

    function showViewMessage(msg, isError) {
        var el = document.getElementById('chapterViewMessage');
        if (!el) { return; }
        el.style.display = msg ? 'block' : 'none';
        el.className = isError ? 'alert error' : 'panel';
        el.textContent = msg || '';
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
            if (method === 'GET') {
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
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || text || ('HTTP ' + res.status);
            throw new Error(msg);
        }
        return body;
    }

    async function uploadMultipart(path, form) {
        var fd = new FormData(form);
        var res = await fetch(ctx + path, { method: 'POST', headers: { 'Accept': 'application/json' }, body: fd });
        var text = await res.text();
        var body = null;
        try { body = text ? JSON.parse(text) : null; } catch (e) {}
        if (!res.ok || (body && body.success === false)) {
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || text || ('HTTP ' + res.status);
            throw new Error(msg);
        }
        return body;
    }

    function openModal(id) {
        var modal = document.getElementById(id);
        if (modal) {
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
        showCreateError('');
        showViewMessage('');
    }

    function canSubmitChapter(ch) {
        var status = String(ch.status || '').toUpperCase();
        var series = seriesById[String(ch.seriesId)];
        // ADD MANUSCRIPT button: MANGAKA owner + chapter COMPLETE + no active review cycle + series not CANCELLED
        return isOwnSeries(ch.seriesId) 
            && Number(ch.completionPct || 0) >= 100 
            && status === 'COMPLETE'
            && series && String(series.status || '').toUpperCase() !== 'CANCELLED';
    }

    function submitHint(ch) {
        if (!isOwnSeries(ch.seriesId)) { return 'Only the owner Mangaka can submit this chapter.'; }
        if (Number(ch.completionPct || 0) < 100) { return 'Chapter must be 100% complete before submit review.'; }
        var status = String(ch.status || '').toUpperCase();
        if (status !== 'COMPLETE') { return 'Chapter status must be Complete.'; }
        var series = seriesById[String(ch.seriesId)];
        if (series && String(series.status || '').toUpperCase() === 'CANCELLED') { return 'Cannot submit manuscript for cancelled series.'; }
        return 'Ready to submit manuscript for editorial review.';
    }

    function renderChapterActions() {
        var actions = document.getElementById('chapterActions');
        var header = document.getElementById('chapterActionHeader');
        header.style.display = '';
        if (!hasRole('MANGAKA')) {
            actions.style.display = 'none';
            return;
        }
        actions.style.display = 'block';
        var seriesSelect = document.getElementById('createSeriesId');
        var ownSeries = seriesList.filter(function (s) { return Number(s.mangakaId) === Number(currentUser.id); });
        seriesSelect.innerHTML = '<option value="">Select Series</option>' + ownSeries.map(function (s) {
            return '<option value="' + s.id + '" data-next-chapter="' + nextChapterNumber(s.id) + '">#' + s.id + ' - ' + escapeHtml(s.title) + '</option>';
        }).join('');
        if (filterSeriesId) {
            seriesSelect.style.display = 'none';
            seriesSelect.innerHTML = '<option value="' + escapeHtml(filterSeriesId) + '" data-next-chapter="' + nextChapterNumber(filterSeriesId) + '" selected></option>';

            var existingLabel = document.getElementById('createSeriesLabel');
            if (!existingLabel) {
                existingLabel = document.createElement('p');
                existingLabel.id = 'createSeriesLabel';
                existingLabel.className = 'section-desc';
                seriesSelect.parentNode.insertBefore(existingLabel, seriesSelect);
            }
            var fs = seriesById[String(filterSeriesId)];
            existingLabel.textContent = 'Tạo chapter cho series: '
                + (fs ? fs.title : '#' + filterSeriesId);
        } else {
            seriesSelect.style.display = '';
            var oldLabel = document.getElementById('createSeriesLabel');
            if (oldLabel) { oldLabel.remove(); }
        }
        updateNextChapterHint();
    }

    function nextChapterNumber(seriesId) {
        var next = 1;
        for (var i = 0; i < chapters.length; i++) {
            if (Number(chapters[i].seriesId) === Number(seriesId)) {
                next = Math.max(next, Number(chapters[i].chapterNumber || 0) + 1);
            }
        }
        return next;
    }

    function updateNextChapterHint() {
        var select = document.getElementById('createSeriesId');
        var hint = document.getElementById('nextChapterHint');
        var deadlineHint = document.getElementById('createSeriesDeadlineHint');
        var deadlineInput = document.getElementById('chapterCreateDeadline');
        if (!select || !hint) { return; }
        var selected = select.options[select.selectedIndex];
        var next = selected ? selected.getAttribute('data-next-chapter') : '';
        hint.textContent = next ? ('Next chapter will be Ch. ' + next + '.') : 'Chapter number will be assigned automatically.';
        if (deadlineInput) {
            deadlineInput.min = todayIso();
            deadlineInput.removeAttribute('max');
        }
        if (deadlineHint) {
            var selectedSeriesId = select.value || filterSeriesId;
            var series = seriesById[String(selectedSeriesId)];
            var maxDeadline = latestChapterDeadline(series);
            if (deadlineInput && maxDeadline) {
                deadlineInput.max = maxDeadline;
            }
            deadlineHint.textContent = series && series.publicationDate
                ? ('Series deadline: ' + formatDate(series.publicationDate) + '. Chapter deadline must be on or before ' + maxDeadline + '.')
                : (selectedSeriesId ? 'Series deadline is not set. Chapter deadline cannot be in the past.' : '');
        }
    }

    function findChapter(chapterId) {
        for (var i = 0; i < chapters.length; i++) {
            if (Number(chapters[i].id) === Number(chapterId)) { return chapters[i]; }
        }
        return null;
    }

    function getSortedChapters() {
        if (!sortField) { return chapters.slice(); }
        return chapters.slice().sort(function (a, b) {
            var av, bv;
            if (sortField === 'no') {
                av = Number(a.chapterNumber || 0);
                bv = Number(b.chapterNumber || 0);
            } else if (sortField === 'title') {
                av = String(a.title || '').toLowerCase();
                bv = String(b.title || '').toLowerCase();
            } else if (sortField === 'status') {
                av = String(a.status || '');
                bv = String(b.status || '');
            } else if (sortField === 'deadline') {
                av = a.submissionDeadline ? String(a.submissionDeadline) : 'zzz';
                bv = b.submissionDeadline ? String(b.submissionDeadline) : 'zzz';
            }
            if (av < bv) { return sortDir === 'asc' ? -1 : 1; }
            if (av > bv) { return sortDir === 'asc' ? 1 : -1; }
            return 0;
        });
    }

    function renderChapters() {
        var tbody = document.getElementById('chapterRows');
        if (!chapters.length) {
            tbody.innerHTML = '<tr><td colspan="7">No chapters found.</td></tr>';
            return;
        }
        tbody.innerHTML = getSortedChapters().map(function (ch) {
            var progress = Math.max(0, Math.min(100, Number(ch.completionPct || 0)));
            var formattedDeadline = formatDate(ch.submissionDeadline);
            var deadlineDate = dateOnly(ch.submissionDeadline);
            var today = new Date(); today.setHours(0,0,0,0);
            var daysLeft = deadlineDate ? Math.ceil((deadlineDate - today) / 86400000) : null;
            var isComplete = String(ch.status || '').toUpperCase() === 'COMPLETE' || Number(ch.completionPct || 0) >= 100;
            var deadlineStyle = (!isComplete && daysLeft !== null && daysLeft <= 3) ? 'color:var(--danger,#e53e3e);font-weight:600;' : '';
            var deadlineSuffix = isComplete ? ' (Done)' : (daysLeft !== null ? ' (' + daysLeft + 'd)' : '');
            var deadlineText = formattedDeadline
                ? ('<span style="' + deadlineStyle + '">' + escapeHtml(formattedDeadline) + deadlineSuffix + '</span>')
                : '-';
            return '<tr>'
                + '<td>' + ch.chapterNumber + '</td>'
                + '<td>' + escapeHtml(ch.title) + '</td>'
                + '<td>' + formatStatus(ch.status) + '</td>'
                + '<td style="min-width: 220px;"><div class="inline-meta" style="justify-content:space-between; margin-bottom:6px;"><span>' + Math.round(progress) + '%</span></div><div class="progress ' + (progress < 40 ? 'red' : '') + '" style="margin-top:0;"><span style="width:' + progress + '%;"></span></div></td>'
                + '<td><span class="status-chip ' + (ch.atRisk ? 'status-rejected' : 'status-approved') + '">' + (ch.atRisk ? 'AT RISK' : 'NORMAL') + '</span></td>'
                + '<td>' + deadlineText + '</td>'
                + '<td><button class="btn small" type="button" data-chapter-view="' + ch.id + '">View</button></td>'
                + '</tr>';
        }).join('');
    }

    function renderOwnerTools(ch) {
        if (!isOwnSeries(ch.seriesId)) {
            return '<p class="section-desc">Only the owner Mangaka can update metadata or upload cover/reference images.</p>';
        }
        var deleteButton = String(ch.status || '').toUpperCase() === 'PLANNING'
            ? '<button class="btn small danger-soft" type="button" data-chapter-delete="' + ch.id + '">Delete Chapter</button>'
            : '';
        var series = seriesById[String(ch.seriesId)];
        var maxDeadline = latestChapterDeadline(series);
        var deadlineAttrs = ' min="' + todayIso() + '"' + (maxDeadline ? ' max="' + escapeHtml(maxDeadline) + '"' : '');
        var deadlineHelp = series && series.publicationDate
            ? '<p class="section-desc">Series deadline: ' + escapeHtml(formatDate(series.publicationDate)) + '. Chapter deadline must be on or before ' + escapeHtml(maxDeadline) + '.</p>'
            : '<p class="section-desc">Chapter deadline cannot be in the past.</p>';
        return '<form class="panel form-grid chapter-inline-update-form" style="max-width:720px;">'
            + '<strong>Update Ch.' + ch.chapterNumber + ' - ' + escapeHtml(ch.title) + '</strong>'
            + '<input name="chapterId" type="hidden" value="' + ch.id + '" />'
            + '<input name="title" type="text" value="' + escapeHtml(ch.title) + '" placeholder="New Title" required />'
            + '<label class="field-label" for="chapterUpdateDeadline' + ch.id + '">Submission Deadline</label>'
            + deadlineHelp
            + '<input id="chapterUpdateDeadline' + ch.id + '" name="submissionDeadline" type="date" value="' + escapeHtml(formatDate(ch.submissionDeadline)) + '"' + deadlineAttrs + ' required />'
            + '<button class="btn small" type="submit">Update</button>'
            + '</form>'
            + '<form class="panel form-grid chapter-image-upload-form" style="max-width:680px;margin-bottom:12px;" data-chapter-id="' + ch.id + '">'
            + '<strong>Upload Cover / Reference</strong>'
            + '<select name="imageType" required><option value="COVER">Cover</option><option value="REFERENCE">Reference</option></select>'
            + '<input name="file" type="file" accept="image/*" required />'
            + '<button class="btn small primary" type="submit">Upload Image</button>'
            + '</form>'
            + deleteButton;
    }

    async function openChapterView(chapterId) {
        var ch = findChapter(chapterId);
        if (!ch) { return; }
        selectedChapter = ch;
        showViewMessage('');
        var progress = Math.max(0, Math.min(100, Number(ch.completionPct || 0)));
        var deadlineDate = dateOnly(ch.submissionDeadline);
        var today = new Date(); today.setHours(0,0,0,0);
        var daysLeft = deadlineDate ? Math.ceil((deadlineDate - today) / 86400000) : null;
        var isComplete = String(ch.status || '').toUpperCase() === 'COMPLETE' || progress >= 100;
        var deadlineStyle = (!isComplete && daysLeft !== null && daysLeft <= 3) ? 'color:var(--danger,#e53e3e);font-weight:600;' : '';
        document.getElementById('chapterViewTitle').textContent = 'Ch. ' + ch.chapterNumber + ' - ' + ch.title;
        document.getElementById('chapterViewSubtitle').textContent = 'Series #' + ch.seriesId;
        document.getElementById('chapterViewMeta').innerHTML = ''
            + '<div><span class="detail-label">Status</span><strong>' + formatStatus(ch.status) + '</strong></div>'
            + '<div><span class="detail-label">Progress</span><strong>' + Math.round(progress) + '%</strong></div>'
            + '<div><span class="detail-label">Deadline</span><strong style="' + deadlineStyle + '">' + escapeHtml(formatDate(ch.submissionDeadline)) + '</strong></div>'
            + '<div><span class="detail-label">At Risk</span><strong>' + (ch.atRisk ? 'AT RISK' : 'NORMAL') + '</strong></div>';
        document.getElementById('chapterOwnerTools').innerHTML = renderOwnerTools(ch);
        var submitButton = document.getElementById('chapterSubmitReviewButton');
        var ready = canSubmitChapter(ch);
        submitButton.disabled = !ready;
        submitButton.className = ready ? 'btn small primary' : 'btn small disabled-soft';
        document.getElementById('chapterSubmitHint').textContent = submitHint(ch);
        document.getElementById('chapterImageList').innerHTML = 'Loading images...';
        openModal('chapterViewModal');
        await loadChapterImages(ch.id);
    }

    function renderImages(images) {
        if (!images.length) { return '<p class="section-desc">No images uploaded yet.</p>'; }
        return '<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px;">' + images.map(function (img) {
            var url = imageUrl(img.fileUrl);
            var deleteButton = canDeleteImage(img)
                ? '<button class="btn small danger-soft" type="button" data-chapter-image-delete="' + img.id + '" data-chapter-id="' + img.chapterId + '">Delete</button>'
                : '';
            return '<div class="panel" style="margin:0;padding:10px;">'
                + '<a href="' + escapeHtml(url) + '" target="_blank"><img src="' + escapeHtml(url) + '" alt="' + escapeHtml(img.originalFileName || img.imageType) + '" style="width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:8px;border:1px solid #e5e7eb;" /></a>'
                + '<div style="margin-top:8px;font-weight:700;">' + escapeHtml(img.imageType) + '</div>'
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
        if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0) { return url; }
        if (url.indexOf(ctx + '/') === 0) { return url; }
        return ctx + url;
    }

    async function loadChapterImages(chapterId) {
        var target = document.getElementById('chapterImageList');
        if (!target) { return; }
        target.innerHTML = 'Loading images...';
        try {
            var res = await callApi('GET', '/api/v1/chapters/' + chapterId + '/images');
            target.innerHTML = renderImages(res.data || []);
        } catch (err) {
            target.innerHTML = '<div class="alert error">' + escapeHtml(err.message) + '</div>';
        }
    }

    async function loadData() {
        try {
            var userRes = await callApi('GET', '/api/v1/auth/me');
            currentUser = userRes.data;
            var results = await Promise.all([
                callApi('GET', '/api/v1/series'),
                callApi('GET', filterSeriesId ? ('/api/v1/series/' + encodeURIComponent(filterSeriesId) + '/chapters') : '/api/v1/chapters')
            ]);
            seriesList = results[0].data || [];
            chapters = results[1].data || [];
            seriesById = {};
            for (var i = 0; i < seriesList.length; i++) { seriesById[String(seriesList[i].id)] = seriesList[i]; }
            var filterSubtitle = document.getElementById('chapterFilterSubtitle');
            if (filterSubtitle && filterSeriesId) {
                var filteredSeries = seriesById[String(filterSeriesId)];
                filterSubtitle.style.display = 'block';
                filterSubtitle.textContent = filteredSeries
                    ? ('Viewing chapters for series #' + filterSeriesId + ' - ' + filteredSeries.title)
                    : ('Viewing chapters for series #' + filterSeriesId);
            }
            renderChapterActions();
            renderChapters();
        } catch (err) {
            document.getElementById('chapterRows').innerHTML = '<tr><td colspan="7">' + escapeHtml(err.message) + '</td></tr>';
        }
    }

    document.addEventListener('click', async function (e) {
        var sortBtn = e.target.closest ? e.target.closest('[data-sort]') : null;
        if (sortBtn) {
            var field = sortBtn.getAttribute('data-sort');
            if (sortField === field) {
                sortDir = (sortDir === 'asc' ? 'desc' : 'asc');
            } else {
                sortField = field;
                sortDir = 'asc';
            }
            renderChapters();
            return;
        }

        var openButton = e.target.closest ? e.target.closest('[data-modal-open]') : null;
        if (openButton) { openModal(openButton.getAttribute('data-modal-open')); return; }
        if (e.target.closest && e.target.closest('[data-modal-close]')) { closeModals(); return; }
        if (e.target.classList && e.target.classList.contains('modal-backdrop')) { closeModals(); return; }

        var deleteButton = e.target.closest ? e.target.closest('[data-chapter-delete]') : null;
        if (deleteButton) {
            var chId = deleteButton.getAttribute('data-chapter-delete');
            if (!confirm('Delete chapter #' + chId + '? This cannot be undone.')) return;
            try {
                showViewMessage('');
                await callApi('DELETE', '/api/v1/chapters/' + chId);
                showMessage('Chapter deleted.', false);
                closeModals();
                await loadData();
            } catch (err) { showViewMessage(err.message, true); }
            return;
        }

        var viewButton = e.target.closest ? e.target.closest('[data-chapter-view]') : null;
        if (viewButton) { await openChapterView(viewButton.getAttribute('data-chapter-view')); return; }

        var imageDeleteButton = e.target.closest ? e.target.closest('[data-chapter-image-delete]') : null;
        if (imageDeleteButton) {
            if (!confirm('Delete this image?')) return;
            try {
                showViewMessage('');
                await callApi('DELETE', '/api/v1/images/' + imageDeleteButton.getAttribute('data-chapter-image-delete'));
                showViewMessage('Image deleted.', false);
                await loadChapterImages(imageDeleteButton.getAttribute('data-chapter-id'));
            } catch (err) { showViewMessage(err.message, true); }
            return;
        }

        if (e.target.id === 'chapterSubmitReviewButton') {
            if (!selectedChapter || e.target.disabled) { return; }
            try {
                showViewMessage('');
                await callApi('POST', '/api/v1/chapters/' + selectedChapter.id + '/submit-review');
                showViewMessage('Chapter submitted for review.', false);
                await loadData();
                var refreshed = findChapter(selectedChapter.id);
                if (refreshed) { await openChapterView(refreshed.id); showViewMessage('Chapter submitted for review.', false); }
            } catch (err) { showViewMessage(err.message, true); }
        }
    });

    document.addEventListener('change', function (e) {
        if (e.target.id === 'createSeriesId') { updateNextChapterHint(); }
    });

    document.addEventListener('submit', async function (e) {
        if (e.target.id === 'chapterCreateForm') {
            e.preventDefault();
            try {
                showCreateError('');
                var createData = formToObject(e.target);
                var targetSeriesId = createData.seriesId || filterSeriesId;
                if (!targetSeriesId) { showCreateError('Vui lòng chọn series.'); return; }
                await callApi('POST', '/api/v1/series/' + targetSeriesId + '/chapters', {
                    title: createData.title,
                    submissionDeadline: createData.submissionDeadline
                });
                showMessage('Chapter created successfully.', false);
                e.target.reset();
                closeModals();
                await loadData();
            } catch (err) { showCreateError(err.message); }
        }

        if (e.target.classList.contains('chapter-inline-update-form')) {
            e.preventDefault();
            try {
                showViewMessage('');
                var updateData = formToObject(e.target);
                var deadlineInput = e.target.querySelector('[name="submissionDeadline"]') || e.target.querySelector('[name="publicationDate"]');
                var deadlineValue = deadlineInput ? deadlineInput.value : '';
                if (!deadlineValue) {
                    showViewMessage('Submission deadline is required.', true);
                    return;
                }
                // Spring @RequestParam on PUT may not bind x-www-form-urlencoded body unless HttpPutFormContentFilter is enabled.
                // Send data as query string (same pattern as series deadline update).
                var qs = new URLSearchParams({
                    title: updateData.title,
                    submissionDeadline: deadlineValue,
                    publicationDate: deadlineValue,
                    deadline: deadlineValue,
                    chapterDeadline: deadlineValue
                }).toString();
                await callApi('PUT', '/api/v1/chapters/' + updateData.chapterId + '?' + qs);
                showViewMessage('Chapter metadata updated.', false);
                await loadData();
                var updated = findChapter(updateData.chapterId);
                if (updated) { await openChapterView(updated.id); showViewMessage('Chapter metadata updated.', false); }
            } catch (err) { showViewMessage(err.message, true); }
        }

        if (e.target.classList.contains('chapter-image-upload-form')) {
            e.preventDefault();
            try {
                showViewMessage('');
                var chapterImageId = e.target.getAttribute('data-chapter-id');
                await uploadMultipart('/api/v1/chapters/' + chapterImageId + '/images', e.target);
                showViewMessage('Chapter image uploaded.', false);
                e.target.reset();
                await loadChapterImages(chapterImageId);
            } catch (err) { showViewMessage(err.message, true); }
        }
    });

    loadData();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
