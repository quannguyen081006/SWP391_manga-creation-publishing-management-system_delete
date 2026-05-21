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
                <th>ID</th>
                <th>Series</th>
                <th>No.</th>
                <th>Title</th>
                <th>Status</th>
                <th>Current Chapter Progress</th>
                <th>At Risk</th>
                <th>Deadline</th>
                <th id="chapterActionHeader" style="display:none;">Actions</th>
            </tr>
        </thead>
        <tbody id="chapterRows">
            <tr><td colspan="9">Loading chapters...</td></tr>
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
            <input name="title" type="text" placeholder="Title" required />
            <label class="field-label" for="chapterCreatePublicationDate">Publication Date</label>
            <input id="chapterCreatePublicationDate" name="publicationDate" type="date" aria-label="Publication Date" required />
            <button class="btn primary" type="submit">Create</button>
        </form>
    </div>
</div>

<div id="chapterViewModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card modal-card-wide" role="dialog" aria-modal="true" aria-labelledby="chapterViewTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="chapterViewTitle" class="section-title compact-title">Chapter Detail</h3>
        <p id="chapterViewSubtitle" class="section-desc"></p>
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
        if (!select || !hint) { return; }
        var selected = select.options[select.selectedIndex];
        var next = selected ? selected.getAttribute('data-next-chapter') : '';
        hint.textContent = next ? ('Next chapter will be Ch. ' + next + '.') : 'Chapter number will be assigned automatically.';
    }

    function findChapter(chapterId) {
        for (var i = 0; i < chapters.length; i++) {
            if (Number(chapters[i].id) === Number(chapterId)) { return chapters[i]; }
        }
        return null;
    }

    function renderChapters() {
        var tbody = document.getElementById('chapterRows');
        if (!chapters.length) {
            tbody.innerHTML = '<tr><td colspan="9">No chapters found.</td></tr>';
            return;
        }
        tbody.innerHTML = chapters.map(function (ch) {
            var progress = Math.max(0, Math.min(100, Number(ch.completionPct || 0)));
            var formattedDeadline = formatDate(ch.submissionDeadline);
            var deadlineDate = dateOnly(ch.submissionDeadline);
            var today = new Date(); today.setHours(0,0,0,0);
            var daysLeft = deadlineDate ? Math.ceil((deadlineDate - today) / 86400000) : null;
            var deadlineStyle = (daysLeft !== null && daysLeft <= 3) ? 'color:var(--danger,#e53e3e);font-weight:600;' : '';
            var deadlineText = formattedDeadline
                ? ('<span style="' + deadlineStyle + '">' + escapeHtml(formattedDeadline) + (daysLeft !== null ? ' (' + daysLeft + 'd)' : '') + '</span>')
                : '-';
            return '<tr>'
                + '<td>' + ch.id + '</td>'
                + '<td>' + ch.seriesId + '</td>'
                + '<td>' + ch.chapterNumber + '</td>'
                + '<td>' + escapeHtml(ch.title) + '</td>'
                + '<td>' + formatStatus(ch.status) + '</td>'
                + '<td style="min-width: 220px;"><div class="inline-meta" style="justify-content:space-between; margin-bottom:6px;"><span>' + progress.toFixed(1) + '%</span></div><div class="progress ' + (progress < 40 ? 'red' : '') + '" style="margin-top:0;"><span style="width:' + progress + '%;"></span></div></td>'
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
        return '<form class="panel form-grid chapter-inline-update-form" style="max-width:720px;">'
            + '<strong>Update Ch.' + ch.chapterNumber + ' - ' + escapeHtml(ch.title) + '</strong>'
            + '<input name="chapterId" type="hidden" value="' + ch.id + '" />'
            + '<input name="title" type="text" value="' + escapeHtml(ch.title) + '" placeholder="New Title" required />'
            + '<label class="field-label" for="chapterUpdatePublicationDate' + ch.id + '">Publication Date</label>'
            + '<input id="chapterUpdatePublicationDate' + ch.id + '" name="publicationDate" type="date" value="' + escapeHtml(formatDate(ch.publicationDate)) + '" aria-label="Publication Date" required />'
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
        var progress = Math.max(0, Math.min(100, Number(ch.completionPct || 0)));
        document.getElementById('chapterViewTitle').textContent = 'Ch. ' + ch.chapterNumber + ' - ' + ch.title;
        document.getElementById('chapterViewSubtitle').textContent = 'Series #' + ch.seriesId;
        document.getElementById('chapterViewMeta').innerHTML = ''
            + '<div><span class="detail-label">Status</span><strong>' + formatStatus(ch.status) + '</strong></div>'
            + '<div><span class="detail-label">Progress</span><strong>' + progress.toFixed(1) + '%</strong></div>'
            + '<div><span class="detail-label">Publication</span><strong>' + escapeHtml(formatDate(ch.publicationDate)) + '</strong></div>'
            + '<div><span class="detail-label">Deadline</span><strong>' + escapeHtml(formatDate(ch.submissionDeadline)) + '</strong></div>'
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
                callApi('GET', '/api/v1/chapters')
            ]);
            seriesList = results[0].data || [];
            chapters = results[1].data || [];
            seriesById = {};
            for (var i = 0; i < seriesList.length; i++) { seriesById[String(seriesList[i].id)] = seriesList[i]; }
            renderChapterActions();
            renderChapters();
        } catch (err) {
            document.getElementById('chapterRows').innerHTML = '<tr><td colspan="9">' + escapeHtml(err.message) + '</td></tr>';
        }
    }

    document.addEventListener('click', async function (e) {
        var openButton = e.target.closest ? e.target.closest('[data-modal-open]') : null;
        if (openButton) { openModal(openButton.getAttribute('data-modal-open')); return; }
        if (e.target.closest && e.target.closest('[data-modal-close]')) { closeModals(); return; }
        if (e.target.classList && e.target.classList.contains('modal-backdrop')) { closeModals(); return; }

        var deleteButton = e.target.closest ? e.target.closest('[data-chapter-delete]') : null;
        if (deleteButton) {
            var chId = deleteButton.getAttribute('data-chapter-delete');
            if (!confirm('Delete chapter #' + chId + '? This cannot be undone.')) return;
            try {
                await callApi('DELETE', '/api/v1/chapters/' + chId);
                showMessage('Chapter deleted.', false);
                closeModals();
                await loadData();
            } catch (err) { showMessage(err.message, true); }
            return;
        }

        var viewButton = e.target.closest ? e.target.closest('[data-chapter-view]') : null;
        if (viewButton) { await openChapterView(viewButton.getAttribute('data-chapter-view')); return; }

        var imageDeleteButton = e.target.closest ? e.target.closest('[data-chapter-image-delete]') : null;
        if (imageDeleteButton) {
            if (!confirm('Delete this image?')) return;
            try {
                await callApi('DELETE', '/api/v1/images/' + imageDeleteButton.getAttribute('data-chapter-image-delete'));
                showMessage('Image deleted.', false);
                await loadChapterImages(imageDeleteButton.getAttribute('data-chapter-id'));
            } catch (err) { showMessage(err.message, true); }
            return;
        }

        if (e.target.id === 'chapterSubmitReviewButton') {
            if (!selectedChapter || e.target.disabled) { return; }
            try {
                await callApi('POST', '/api/v1/chapters/' + selectedChapter.id + '/submit-review');
                showMessage('Chapter submitted for review.', false);
                closeModals();
                await loadData();
            } catch (err) { showMessage(err.message, true); }
        }
    });

    document.addEventListener('change', function (e) {
        if (e.target.id === 'createSeriesId') { updateNextChapterHint(); }
    });

    document.addEventListener('submit', async function (e) {
        if (e.target.id === 'chapterCreateForm') {
            e.preventDefault();
            try {
                var createData = formToObject(e.target);
                await callApi('POST', '/api/v1/series/' + createData.seriesId + '/chapters', {
                    title: createData.title,
                    publicationDate: createData.publicationDate
                });
                showMessage('Chapter created successfully.', false);
                e.target.reset();
                closeModals();
                await loadData();
            } catch (err) { showMessage(err.message, true); }
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
                closeModals();
                await loadData();
            } catch (err) { showMessage(err.message, true); }
        }

        if (e.target.classList.contains('chapter-image-upload-form')) {
            e.preventDefault();
            try {
                var chapterImageId = e.target.getAttribute('data-chapter-id');
                await uploadMultipart('/api/v1/chapters/' + chapterImageId + '/images', e.target);
                showMessage('Chapter image uploaded.', false);
                e.target.reset();
                await loadChapterImages(chapterImageId);
            } catch (err) { showMessage(err.message, true); }
        }
    });

    loadData();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
