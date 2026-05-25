<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapter Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css?v=20260525" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<div id="detailResult" class="alert error" style="display:none;margin-bottom:12px;"></div>

<div id="breadcrumb" style="font-size:14px;color:#6b7280;margin-bottom:16px;display:flex;align-items:center;gap:6px;flex-wrap:wrap;">
    <a href="${pageContext.request.contextPath}/main/series" style="color:#6b7280;">My Series</a>
    <span>›</span>
    <a id="breadcrumbSeries" href="#" style="color:#6b7280;"></a>
    <span>›</span>
    <span id="breadcrumbChapter" style="color:#111827;font-weight:500;"></span>
    <span id="breadcrumbStatusPill" style="margin-left:6px;"></span>
</div>

<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:10px;">
    <div></div>
    <div style="display:flex;gap:8px;">
        <button id="btnDelete" class="btn small" type="button" style="color:#ef4444;border-color:#fecaca;display:none;">Delete chapter</button>
        <button id="btnSave" class="btn small" type="button" style="display:none;">Save changes</button>
        <button id="btnMarkDone" class="btn primary" type="button" style="display:none;">Submit for review</button>
    </div>
</div>

<div style="display:grid;grid-template-columns:1fr 280px;gap:20px;align-items:start;">
    <div class="section-card" style="padding:0;overflow:hidden;">
        <div id="tabBar" style="display:flex;border-bottom:1px solid #e5e7eb;">
            <button class="tab-btn active" type="button" data-tab="pages" style="padding:12px 18px;font-size:14px;font-weight:500;background:none;border:none;cursor:pointer;border-bottom:2px solid #e11d48;color:#111827;">
                Pages <span id="tabPageCount" style="font-size:11px;background:#f3f4f6;border:1px solid #e5e7eb;border-radius:999px;padding:1px 6px;margin-left:4px;">0</span>
            </button>
            <button class="tab-btn" type="button" data-tab="edit" style="padding:12px 18px;font-size:14px;background:none;border:none;cursor:pointer;border-bottom:2px solid transparent;color:#6b7280;">
                Edit details
            </button>
        </div>

        <div id="tabPages" style="padding:20px;">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;flex-wrap:wrap;gap:8px;">
                <span id="pageCountLabel" style="font-size:13px;color:#6b7280;">Loading...</span>
                <button class="btn small primary" type="button" id="triggerUpload" style="display:none;">Upload pages</button>
            </div>
            <div id="imageGrid" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:10px;margin-bottom:16px;">
                <p style="color:#9ca3af;grid-column:1/-1;">Loading images...</p>
            </div>
            <div id="progressSection" style="margin-bottom:16px;">
                <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px;">
                    <span style="color:#6b7280;">Progress</span>
                    <span id="progressLabel" style="font-weight:500;"></span>
                </div>
                <div class="progress"><span id="progressFill" style="width:0%;background:#8b5cf6;"></span></div>
            </div>
            <form id="uploadForm" class="chapter-image-upload-form panel form-grid" style="display:none;" data-chapter-id="">
                <strong>Upload image</strong>
                <select name="imageType" required>
                    <option value="COVER">Cover</option>
                    <option value="REFERENCE">Reference</option>
                </select>
                <input name="file" type="file" accept="image/*" required />
                <div style="display:flex;gap:8px;">
                    <button class="btn small primary" type="submit">Upload</button>
                    <button class="btn small" type="button" id="cancelUpload">Cancel</button>
                </div>
            </form>
        </div>

        <div id="tabEdit" style="padding:20px;display:none;">
            <form id="chapterUpdateForm" class="form-grid chapter-inline-update-form">
                <input name="chapterId" type="hidden" id="updateChapterId" />
                <label class="field-label" for="updateTitle">Title</label>
                <input id="updateTitle" name="title" type="text" required />
                <label class="field-label" for="updateDeadline">Submission deadline</label>
                <input id="updateDeadline" name="submissionDeadline" type="date" required />
                <div id="updateError" class="alert error" style="display:none;"></div>
            </form>
        </div>
    </div>

    <div>
        <div class="panel" style="margin-bottom:14px;">
            <strong id="panelChapterTitle" style="font-size:15px;"></strong>
            <p id="panelSeriesName" class="section-desc" style="margin:4px 0 14px;"></p>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Deadline</div>
                    <div id="metaDeadline"></div>
                    <div id="metaDeadlineSub" style="font-size:11px;margin-top:4px;"></div>
                </div>
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Images</div>
                    <div id="metaImages" style="font-size:14px;font-weight:600;"></div>
                </div>
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Status</div>
                    <div id="metaStatus" style="margin-top:4px;"></div>
                </div>
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Progress</div>
                    <div id="metaProgress" style="font-size:14px;font-weight:600;"></div>
                </div>
            </div>
        </div>
        <div class="panel">
            <strong style="font-size:13px;">At risk</strong>
            <div id="metaAtRisk" style="margin-top:8px;"></div>
        </div>
    </div>
</div>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var params = new URLSearchParams(window.location.search);
    var chapterId = params.get('id');
    var urlError = params.get('error');
    var currentUser = null;
    var chapter = null;
    var seriesData = null;
    var imageList = [];

    function escapeHtml(v) {
        if (v === null || v === undefined) { return ''; }
        return String(v).replace(/[&<>"]/g, function (c) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c];
        });
    }

    function formatDate(v) {
        if (!v) { return ''; }
        var s = String(v);
        if (/^\d+$/.test(s)) {
            var date = new Date(Number(s));
            if (!isNaN(date.getTime())) {
                var month = String(date.getMonth() + 1);
                var day = String(date.getDate());
                return date.getFullYear() + '-' + (month.length < 2 ? '0' + month : month) + '-' + (day.length < 2 ? '0' + day : day);
            }
        }
        if (s.indexOf('T') > -1) { return s.substring(0, 10); }
        return s;
    }

    function dateOnly(v) {
        var d = formatDate(v);
        return d ? new Date(d + 'T00:00:00') : null;
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
        return series && series.publicationDate ? addDaysIso(series.publicationDate, -14) : '';
    }

    function daysUntilDate(value) {
        var due = dateOnly(value);
        if (!due) { return null; }
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        return Math.ceil((due - today) / 86400000);
    }

    function hasRole(role) {
        return currentUser && currentUser.roles && currentUser.roles.indexOf(role) !== -1;
    }

    function isOwner() {
        return hasRole('MANGAKA') && seriesData && Number(seriesData.mangakaId) === Number(currentUser.id);
    }

    function formatStatus(s) {
        return String(s || '').toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, function (c) { return c.toUpperCase(); });
    }

    function chapterStatusClass(status) {
        status = String(status || '').toUpperCase();
        if (status === 'PLANNING') { return 'status-draft'; }
        if (status === 'IN_PROGRESS') { return 'status-progress'; }
        if (status === 'COMPLETE') { return 'status-approved'; }
        if (status === 'EDITORIAL_REVIEW') { return 'status-review'; }
        if (status === 'APPROVED') { return 'status-approved'; }
        if (status === 'REJECTED') { return 'status-rejected'; }
        return 'status-draft';
    }

    function isChapterDone(ch) {
        var st = String(ch.status || '').toUpperCase();
        return st === 'COMPLETE' || st === 'APPROVED' || Number(ch.completionPct || 0) >= 100;
    }

    function isChapterOverdue(ch) {
        if (isChapterDone(ch)) { return false; }
        var daysLeft = daysUntilDate(ch.submissionDeadline);
        return daysLeft !== null && daysLeft < 0;
    }

    function deadlineSuffixText(daysLeft, isDone, isOverdue) {
        if (isDone) { return 'Done'; }
        if (isOverdue) {
            if (daysLeft !== null && daysLeft < 0) {
                var n = Math.abs(daysLeft);
                return n === 1 ? '1 day overdue' : (n + ' days overdue');
            }
            return 'Overdue';
        }
        if (daysLeft === null) { return ''; }
        if (daysLeft === 0) { return 'Due today'; }
        if (daysLeft === 1) { return '1 day left'; }
        return daysLeft + ' days left';
    }

    function formatDeadlineCell(dateValue, isDone, isOverdue) {
        var formatted = formatDate(dateValue);
        if (!formatted) { return '<span style="color:#9ca3af;">—</span>'; }
        var daysLeft = daysUntilDate(dateValue);
        if (!isDone && !isOverdue && daysLeft !== null && daysLeft < 0) { isOverdue = true; }
        var suffix = deadlineSuffixText(daysLeft, isDone, isOverdue);
        suffix = suffix ? ' (' + suffix + ')' : '';
        if (isDone) {
            return '<span class="due-date-done">' + escapeHtml(formatted) + suffix + '</span>';
        }
        if (isOverdue) {
            return '<span class="due-date-overdue">&#9888; ' + escapeHtml(formatted) + suffix + '</span>';
        }
        if (daysLeft !== null && daysLeft <= 3) {
            return '<span class="due-date-urgent">' + escapeHtml(formatted) + suffix + '</span>';
        }
        return '<span class="due-date-active">' + escapeHtml(formatted) + suffix + '</span>';
    }

    async function callApi(method, path, data) {
        var opts = { method: method, headers: { 'Accept': 'application/json' } };
        var url = ctx + path;
        if (data) {
            var p = new URLSearchParams(data).toString();
            if (method === 'GET' || method === 'PUT') {
                url += (url.indexOf('?') === -1 ? '?' : '&') + p;
            } else {
                opts.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
                opts.body = p;
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

    function showError(msg) {
        var el = document.getElementById('detailResult');
        el.style.display = msg ? 'block' : 'none';
        el.textContent = msg || '';
    }

    function imageUrl(fileUrl) {
        var url = String(fileUrl || '');
        if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0) { return url; }
        if (url.indexOf(ctx + '/') === 0) { return url; }
        return ctx + url;
    }

    function renderMeta() {
        var progress = Math.max(0, Math.min(100, Number(chapter.completionPct || 0)));
        var done = isChapterDone(chapter);
        var overdue = isChapterOverdue(chapter);
        var seriesTitle = seriesData ? seriesData.title : ('#' + chapter.seriesId);

        document.getElementById('breadcrumbSeries').textContent = seriesTitle;
        document.getElementById('breadcrumbSeries').href = ctx + '/main/chapters?seriesId=' + chapter.seriesId;
        document.getElementById('breadcrumbChapter').textContent = 'Ch.' + chapter.chapterNumber + ' — ' + chapter.title;
        document.getElementById('breadcrumbStatusPill').innerHTML =
            '<span class="status-chip chapter-status-chip ' + chapterStatusClass(chapter.status) + '">' + formatStatus(chapter.status) + '</span>';

        document.getElementById('panelChapterTitle').textContent = 'Ch.' + chapter.chapterNumber + ' — ' + chapter.title;
        document.getElementById('panelSeriesName').textContent = seriesTitle + ' · Chapter ' + chapter.chapterNumber;

        document.getElementById('metaDeadline').innerHTML = formatDeadlineCell(chapter.submissionDeadline, done, overdue);
        document.getElementById('metaDeadlineSub').textContent = '';
        document.getElementById('metaImages').textContent = imageList.length + ' uploaded';
        document.getElementById('metaStatus').innerHTML =
            '<span class="status-chip chapter-status-chip ' + chapterStatusClass(chapter.status) + '">' + formatStatus(chapter.status) + '</span>';
        document.getElementById('metaProgress').textContent = Math.round(progress) + '%';
        document.getElementById('metaAtRisk').innerHTML = chapter.atRisk
            ? '<span class="status-chip status-rejected">AT RISK</span>'
            : '<span class="status-chip status-approved">NORMAL</span>';

        document.getElementById('progressLabel').textContent = Math.round(progress) + '%';
        document.getElementById('progressFill').style.width = progress + '%';
        document.getElementById('tabPageCount').textContent = imageList.length;
        document.getElementById('pageCountLabel').textContent = imageList.length + ' images uploaded';

        var owner = isOwner();
        var canSubmit = owner && progress >= 100 && String(chapter.status || '').toUpperCase() === 'COMPLETE'
            && seriesData && String(seriesData.status || '').toUpperCase() !== 'CANCELLED';

        document.getElementById('btnDelete').style.display = (owner && String(chapter.status || '').toUpperCase() === 'PLANNING') ? '' : 'none';
        document.getElementById('btnSave').style.display = owner ? '' : 'none';
        document.getElementById('btnMarkDone').style.display = canSubmit ? '' : 'none';
        document.getElementById('triggerUpload').style.display = owner ? '' : 'none';

        document.getElementById('updateChapterId').value = chapter.id;
        document.getElementById('updateTitle').value = chapter.title || '';
        var updateDeadline = document.getElementById('updateDeadline');
        var maxDeadline = latestChapterDeadline(seriesData);
        updateDeadline.value = formatDate(chapter.submissionDeadline) || '';
        updateDeadline.min = todayIso();
        updateDeadline.removeAttribute('max');
        updateDeadline.disabled = false;
        document.getElementById('btnSave').disabled = false;
        document.getElementById('updateError').style.display = 'none';
        document.getElementById('updateError').textContent = '';
        if (maxDeadline) {
            updateDeadline.max = maxDeadline;
        } else if (owner) {
            updateDeadline.disabled = true;
            document.getElementById('btnSave').disabled = true;
            document.getElementById('updateError').style.display = 'block';
            document.getElementById('updateError').textContent = 'Series deadline must be set by Tantou before updating chapter deadline.';
        }
        document.getElementById('uploadForm').setAttribute('data-chapter-id', chapter.id);
    }

    function renderImages() {
        var grid = document.getElementById('imageGrid');
        if (!imageList.length) {
            grid.innerHTML = '<p style="color:#9ca3af;grid-column:1/-1;font-size:13px;">No images uploaded yet.</p>';
            return;
        }
        var owner = isOwner();
        grid.innerHTML = imageList.map(function (img) {
            var url = imageUrl(img.fileUrl);
            var deleteBtn = owner
                ? '<button class="btn small danger-soft" type="button" data-chapter-image-delete="' + img.id + '" style="margin-top:6px;width:100%;font-size:11px;">Delete</button>'
                : '';
            return '<div style="border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;background:#f9fafb;">'
                + '<a href="' + escapeHtml(url) + '" target="_blank">'
                + '<img src="' + escapeHtml(url) + '" alt="' + escapeHtml(img.imageType) + '" style="width:100%;aspect-ratio:3/4;object-fit:cover;display:block;" /></a>'
                + '<div style="padding:6px 8px;">'
                + '<div style="font-size:11px;font-weight:600;">' + escapeHtml(img.imageType) + '</div>'
                + '<div style="font-size:10px;color:#9ca3af;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + escapeHtml(img.originalFileName || '') + '</div>'
                + deleteBtn
                + '</div></div>';
        }).join('');
    }

    document.getElementById('tabBar').addEventListener('click', function (e) {
        var btn = e.target.closest('.tab-btn');
        if (!btn) { return; }
        document.querySelectorAll('.tab-btn').forEach(function (b) {
            b.style.borderBottomColor = 'transparent';
            b.style.color = '#6b7280';
            b.style.fontWeight = '';
        });
        btn.style.borderBottomColor = '#e11d48';
        btn.style.color = '#111827';
        btn.style.fontWeight = '500';
        document.getElementById('tabPages').style.display = btn.getAttribute('data-tab') === 'pages' ? '' : 'none';
        document.getElementById('tabEdit').style.display = btn.getAttribute('data-tab') === 'edit' ? '' : 'none';
    });

    document.getElementById('triggerUpload').addEventListener('click', function () {
        document.getElementById('uploadForm').style.display = '';
    });
    document.getElementById('cancelUpload').addEventListener('click', function () {
        document.getElementById('uploadForm').style.display = 'none';
        document.getElementById('uploadForm').reset();
    });

    document.getElementById('btnSave').addEventListener('click', async function () {
        var updateError = document.getElementById('updateError');
        updateError.style.display = 'none';
        try {
            var title = document.getElementById('updateTitle').value;
            var deadline = document.getElementById('updateDeadline').value;
            var qs = new URLSearchParams({
                title: title,
                submissionDeadline: deadline,
                publicationDate: deadline,
                deadline: deadline,
                chapterDeadline: deadline
            }).toString();
            await callApi('PUT', '/api/v1/chapters/' + chapterId + '?' + qs);
            chapter.title = title;
            chapter.submissionDeadline = deadline;
            renderMeta();
            showError('');
        } catch (err) {
            updateError.style.display = 'block';
            updateError.textContent = err.message;
        }
    });

    document.getElementById('btnDelete').addEventListener('click', async function () {
        if (!confirm('Delete this chapter? This cannot be undone.')) { return; }
        try {
            await callApi('DELETE', '/api/v1/chapters/' + chapterId);
            window.location.href = ctx + '/main/chapters?seriesId=' + chapter.seriesId;
        } catch (err) { showError(err.message); }
    });

    document.getElementById('btnMarkDone').addEventListener('click', async function () {
        try {
            await callApi('POST', '/api/v1/chapters/' + chapterId + '/submit-review');
            await loadData();
        } catch (err) { showError(err.message); }
    });

    document.addEventListener('click', async function (e) {
        var delBtn = e.target.closest('[data-chapter-image-delete]');
        if (delBtn) {
            if (!confirm('Delete this image?')) { return; }
            try {
                await callApi('DELETE', '/api/v1/images/' + delBtn.getAttribute('data-chapter-image-delete'));
                await loadImages();
            } catch (err) { showError(err.message); }
        }
    });

    document.addEventListener('submit', async function (e) {
        if (e.target.id === 'uploadForm') {
            e.preventDefault();
            try {
                await uploadMultipart('/api/v1/chapters/' + chapterId + '/images', e.target);
                e.target.reset();
                e.target.style.display = 'none';
                await loadImages();
            } catch (err) { showError(err.message); }
        }
    });

    async function loadImages() {
        try {
            var res = await callApi('GET', '/api/v1/chapters/' + chapterId + '/images');
            imageList = res.data || [];
            renderImages();
            renderMeta();
        } catch (err) {
            document.getElementById('imageGrid').innerHTML = '<div class="alert error">' + escapeHtml(err.message) + '</div>';
        }
    }

    async function loadData() {
        if (!chapterId) {
            showError('No chapter ID specified.');
            return;
        }
        try {
            var userRes = await callApi('GET', '/api/v1/auth/me');
            currentUser = userRes.data;
            var chRes = await callApi('GET', '/api/v1/chapters/' + chapterId);
            chapter = chRes.data;
            var sListRes = await callApi('GET', '/api/v1/series');
            var sList = sListRes.data || [];
            for (var i = 0; i < sList.length; i++) {
                if (Number(sList[i].id) === Number(chapter.seriesId)) {
                    seriesData = sList[i];
                    break;
                }
            }
            await loadImages();
        } catch (err) {
            showError(err.message);
        }
    }

    if (urlError) {
        showError(decodeURIComponent(urlError));
    }

    loadData();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
