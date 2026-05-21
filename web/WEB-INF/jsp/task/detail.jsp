<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Task Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Task #${task.id}</h2>
<p class="page-sub">${task.seriesTitle} - Ch. ${task.chapterNumber} ${task.chapterTitle}</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card detail-grid">
    <div><span class="detail-label">Type</span><strong>${task.taskType}</strong></div>
    <div><span class="detail-label">Pages</span><strong>${task.pageRangeStart}-${task.pageRangeEnd}</strong></div>
    <div><span class="detail-label">Assigned To</span><strong>${task.assistantName}</strong></div>
    <div><span class="detail-label">Due Date</span><strong>${task.dueDate}</strong></div>
    <div><span class="detail-label">Status</span><span class="status-chip ${task.status=='APPROVED' ? 'status-approved' : (task.status=='OVERDUE' ? 'status-overdue' : 'status-progress')}">${task.status}</span></div>
</div>

<c:if test="${canAssistantUpdate}">
    <div class="section-card">
        <h3 class="section-title compact-title">Assistant Update</h3>
        <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/assistant-status" class="inline-form">
            <select name="status">
                <option value="IN_PROGRESS">IN_PROGRESS</option>
                <option value="SUBMITTED">SUBMITTED</option>
            </select>
            <button class="btn primary" type="submit">Update Status</button>
        </form>
    </div>
</c:if>

<c:if test="${canMangakaReview}">
    <div class="section-card">
        <h3 class="section-title compact-title">Mangaka Review</h3>
        <div class="detail-actions">
            <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/approve">
                <button class="btn success-soft" type="submit">Approve</button>
            </form>
            <form method="post" action="${pageContext.request.contextPath}/main/tasks/${task.id}/reject">
                <button class="btn danger-soft" type="submit" onclick="return confirm('Reject this task?');">Reject</button>
            </form>
        </div>
    </div>
</c:if>

<div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title compact-title">Task Images</h3>
            <p class="section-desc">Page images uploaded for this task</p>
        </div>
    </div>

    <c:if test="${canAssistantUpdate}">
        <form id="taskImageUploadForm" class="form-grid" style="max-width:680px;margin-bottom:12px;">
            <input name="imageType" type="hidden" value="PAGE" />
            <input name="pageTaskId" type="hidden" value="${task.id}" />
            <input name="pageNumber" type="number" min="1" placeholder="Page Number" required />
            <input name="file" type="file" accept="image/*" required />
            <button class="btn primary" type="submit">Upload Image</button>
        </form>
    </c:if>
    <c:if test="${!canAssistantUpdate}">
        <p class="section-desc">
            PAGE images can be uploaded only by the assistant assigned to this task.
            Mangaka can upload cover/reference images from Chapters &gt; Images.
        </p>
    </c:if>

    <div id="taskImageResult" class="alert error" style="display:none;"></div>
    <div id="taskImageList">Loading images...</div>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/tasks">Back to Tasks</a>

<script>
(function () {
    var ctx = '${pageContext.request.contextPath}';
    var taskId = '${task.id}';
    var chapterId = '${task.chapterId}';
    var canDeleteImages = ${canAssistantUpdate || canMangakaReview};
    var resultBox = document.getElementById('taskImageResult');
    var listBox = document.getElementById('taskImageList');

    function escapeHtml(value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value).replace(/[&<>"]/g, function (ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[ch];
        });
    }

    function showMessage(msg, isError) {
        if (!resultBox) {
            return;
        }
        resultBox.style.display = 'block';
        resultBox.className = isError ? 'alert error' : 'panel';
        resultBox.textContent = msg;
    }

    async function readJson(res) {
        var text = await res.text();
        var body = null;
        try { body = text ? JSON.parse(text) : null; } catch (e) {}
        if (!res.ok || (body && body.success === false)) {
            var msg = (body && (body.message || (body.errors && body.errors[0]))) || text || ('HTTP ' + res.status);
            throw new Error(msg);
        }
        return body;
    }

    function renderImages(images) {
        if (!images.length) {
            return '<p class="section-desc">No images uploaded yet.</p>';
        }
        return '<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px;">' + images.map(function (img) {
            var url = imageUrl(img.fileUrl);
            var deleteButton = canDeleteImages
                ? '<button class="btn small danger-soft" type="button" data-image-delete="' + img.id + '">Delete</button>'
                : '';
            return '<div class="panel" style="margin:0;padding:10px;">'
                + '<a href="' + escapeHtml(url) + '" target="_blank"><img src="' + escapeHtml(url) + '" alt="' + escapeHtml(img.originalFileName || ('Page ' + img.pageNumber)) + '" style="width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:8px;border:1px solid #e5e7eb;" /></a>'
                + '<div style="margin-top:8px;font-weight:700;">Page ' + escapeHtml(img.pageNumber || '') + '</div>'
                + '<div class="section-desc">' + escapeHtml(img.originalFileName || '') + '</div>'
                + deleteButton
                + '</div>';
        }).join('') + '</div>';
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

    async function loadImages() {
        listBox.innerHTML = 'Loading images...';
        try {
            var body = await readJson(await fetch(ctx + '/api/v1/tasks/' + taskId + '/images', { headers: { 'Accept': 'application/json' } }));
            listBox.innerHTML = renderImages(body.data || []);
        } catch (err) {
            listBox.innerHTML = '<div class="alert error">' + escapeHtml(err.message) + '</div>';
        }
    }

    var form = document.getElementById('taskImageUploadForm');
    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            try {
                var fd = new FormData(form);
                var file = form.querySelector('input[type="file"]');
                if (file && (!file.files || file.files.length === 0)) {
                    fd.delete('file');
                }
                await readJson(await fetch(ctx + '/api/v1/chapters/' + chapterId + '/images', {
                    method: 'POST',
                    headers: { 'Accept': 'application/json' },
                    body: fd
                }));
                showMessage('Task image uploaded.', false);
                form.reset();
                await loadImages();
            } catch (err) {
                showMessage(err.message, true);
            }
        });
    }

    document.addEventListener('click', async function (e) {
        var button = e.target.closest ? e.target.closest('[data-image-delete]') : null;
        if (!button) {
            return;
        }
        if (!confirm('Delete this image?')) return;
        try {
            await readJson(await fetch(ctx + '/api/v1/images/' + button.getAttribute('data-image-delete'), {
                method: 'DELETE',
                headers: { 'Accept': 'application/json' }
            }));
            showMessage('Image deleted.', false);
            await loadImages();
        } catch (err) {
            showMessage(err.message, true);
        }
    });

    loadImages();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
