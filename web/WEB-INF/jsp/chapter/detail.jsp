<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chapter Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css?v=20260525" />
    <style>
        .chapter-workspace { display: grid; grid-template-columns: 3fr 1fr; gap: 20px; align-items: start; }
        @media (max-width: 960px) { .chapter-workspace { grid-template-columns: 1fr; } }
        .chapter-main-card { padding: 0; overflow: hidden; }
        .chapter-tab-bar { display: flex; border-bottom: 1px solid #e5e7eb; }
        .chapter-tab-btn {
            padding: 12px 18px; font-size: 14px; background: none; border: none; cursor: pointer;
            border-bottom: 2px solid transparent; color: #6b7280;
        }
        .chapter-tab-btn.active { border-bottom-color: #e11d48; color: #111827; font-weight: 500; }
        .chapter-tab-panel { padding: 20px; }
        .pages-toolbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; }
        .pages-hint {
            background: #f0f9ff; border: 1px solid #bae6fd; border-radius: 10px; padding: 10px 14px;
            font-size: 13px; color: #0369a1; margin-bottom: 12px;
        }
        .pages-selection-bar {
            display: none; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px;
            background: #f5f3ff; border: 1px solid #c4b5fd; border-radius: 10px; padding: 10px 14px; margin-bottom: 12px;
        }
        .pages-selection-bar.visible { display: flex; }
        .page-slot-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px; margin-bottom: 16px; }
        @media (max-width: 1100px) { .page-slot-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 720px) { .page-slot-grid { grid-template-columns: repeat(3, 1fr); } }
        .page-slot {
            position: relative; aspect-ratio: 3/4; border-radius: 10px; cursor: pointer;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            overflow: hidden; transition: box-shadow 0.15s, border-color 0.15s;
        }
        .page-slot-num { position: absolute; top: 6px; left: 8px; font-size: 11px; font-weight: 700; color: #374151; z-index: 2; }
        .page-slot.state-empty { border: 2px dashed #d1d5db; background: #f9fafb; color: #9ca3af; }
        .page-slot.state-empty:hover { border-color: #9ca3af; background: #f3f4f6; }
        .page-slot.state-uploaded { border: 2px solid #3b82f6; background: #eff6ff; }
        .page-slot.state-task { border: 2px solid #10b981; background: #ecfdf5; }
        .page-slot.state-selected { box-shadow: 0 0 0 3px #8b5cf6; border-color: #7c3aed !important; }
        .page-slot img { width: 100%; height: 100%; object-fit: cover; display: block; }
        .page-slot-initials {
            position: absolute; bottom: 8px; right: 8px; width: 28px; height: 28px; border-radius: 50%;
            background: #059669; color: #fff; font-size: 10px; font-weight: 700;
            display: flex; align-items: center; justify-content: center; z-index: 2;
        }
        .page-slot-add {
            border: 2px dashed #e11d48; background: #fff1f2; color: #e11d48; font-size: 24px; font-weight: 300;
        }
        .page-slot-add:hover { background: #ffe4e6; }
        .page-slot-upload-label { font-size: 11px; text-align: center; padding: 8px; }
        .sidebar-stepper { list-style: none; padding: 0; margin: 12px 0 0; }
        .sidebar-stepper li {
            display: flex; gap: 10px; padding: 10px 0; border-bottom: 1px solid #f3f4f6; font-size: 13px;
        }
        .sidebar-stepper li:last-child { border-bottom: none; }
        .step-num {
            flex-shrink: 0; width: 24px; height: 24px; border-radius: 50%; background: #e11d48; color: #fff;
            font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center;
        }
        .sidebar-task-mini { font-size: 12px; padding: 8px 0; border-bottom: 1px solid #f3f4f6; }
        .sidebar-task-mini:last-child { border-bottom: none; }
        .assign-chips { display: flex; flex-wrap: wrap; gap: 6px; min-height: 28px; }
        .assign-chip {
            background: #ede9fe; border: 1px solid #c4b5fd; color: #5b21b6; border-radius: 999px;
            padding: 4px 10px; font-size: 12px; font-weight: 600;
        }
        .task-actions-cell { position: relative; vertical-align: top; }
        .task-row-actions { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
        .task-action-popover {
            display: none; position: absolute; top: calc(100% + 8px); right: 0; width: 300px; z-index: 40;
            pointer-events: auto; background: #fff; border: 1px solid #e5e7eb; border-radius: 12px;
            padding: 14px; box-shadow: 0 10px 24px rgba(15, 23, 42, 0.12);
        }
        .task-action-popover.open { display: block; }
        .task-action-popover strong { display: block; font-size: 14px; margin-bottom: 10px; }
        .task-action-popover textarea {
            width: 100%; min-height: 72px; resize: vertical; border: 1px solid #e5e7eb;
            border-radius: 8px; padding: 8px 10px; font-size: 13px; box-sizing: border-box;
        }
        .task-action-popover .popover-helper { font-size: 12px; color: #6b7280; margin: 6px 0 10px; }
        .task-action-popover .popover-counter { font-size: 11px; color: #9ca3af; text-align: right; margin-top: 4px; }
        .task-action-popover .popover-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 10px; }
        .task-decision-label { font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 999px; }
        .task-decision-label.approved { color: #047857; background: #ecfdf5; border: 1px solid #a7f3d0; }
        .task-decision-label.rejected { color: #b91c1c; background: #fef2f2; border: 1px solid #fecaca; }
        #chapterTaskTableWrap { overflow: visible; }
    </style>
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

<div style="display:flex;justify-content:flex-end;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:8px;">
    <button id="btnDelete" class="btn small" type="button" style="color:#ef4444;border-color:#fecaca;display:none;">Delete chapter</button>
    <button id="btnSave" class="btn small" type="button" style="display:none;">Save changes</button>
    <button id="btnMarkDone" class="btn primary" type="button" style="display:none;">Submit for review</button>
</div>

<div class="chapter-workspace">
    <div class="section-card chapter-main-card">
        <div id="tabBar" class="chapter-tab-bar">
            <button class="chapter-tab-btn active" type="button" data-tab="pages">
                Pages <span id="tabPageCount" class="status-chip" style="font-size:11px;margin-left:4px;">0</span>
            </button>
            <button class="chapter-tab-btn" type="button" data-tab="tasks">
                Tasks <span id="tabTaskCount" class="status-chip" style="font-size:11px;margin-left:4px;">0</span>
            </button>
            <button class="chapter-tab-btn" type="button" data-tab="edit">Edit details</button>
        </div>

        <div id="tabPages" class="chapter-tab-panel">
            <div class="pages-toolbar">
                <span id="pageCountLabel" style="font-size:13px;color:#6b7280;font-weight:500;">Đang tải...</span>
                <div id="pagesOwnerActions" style="display:none;gap:8px;">
                    <button class="btn small primary" type="button" id="btnAddPage">+ Thêm trang</button>
                    <button class="btn small" type="button" id="btnBulkUpload">Upload bulk</button>
                    <input id="bulkFileInput" type="file" accept="image/*" multiple style="display:none;" />
                    <input id="singleFileInput" type="file" accept="image/*" style="display:none;" />
                </div>
            </div>
            <div class="pages-hint" id="pagesHint">
                Nhấp ô trang để <strong>chọn / bỏ chọn</strong> (nhấp lại lần nữa = bỏ chọn). Ô trống chưa chọn: nhấp để upload.
                Giữ <strong>Shift</strong> + nhấp để chọn dải trang, rồi <strong>Gán task</strong>.
                Ảnh lưu đường dẫn trên database; file nằm <code>web/img/chapter/</code> (không đi theo git pull).
            </div>
            <div id="selectionBar" class="pages-selection-bar">
                <span id="selectionLabel" style="font-size:13px;font-weight:500;color:#5b21b6;">0 trang đã chọn</span>
                <div style="display:flex;gap:8px;">
                    <button class="btn small primary" type="button" id="btnAssignFromSelection">Gán task</button>
                    <button class="btn small" type="button" id="btnClearSelection">Bỏ chọn</button>
                </div>
            </div>
            <div id="pageSlotGrid" class="page-slot-grid">
                <p style="color:#9ca3af;grid-column:1/-1;font-size:13px;">Đang tải trang...</p>
            </div>
            <div id="progressSection">
                <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px;">
                    <span style="color:#6b7280;">Tiến độ task trên trang</span>
                    <span id="progressLabel" style="font-weight:500;"></span>
                </div>
                <div class="progress"><span id="progressFill" style="width:0%;background:#8b5cf6;"></span></div>
            </div>
        </div>

        <div id="tabTasks" class="chapter-tab-panel" style="display:none;">
            <div id="chapterTaskTableWrap" class="section-card" style="padding:0;overflow:visible;border:none;box-shadow:none;">
                <table class="data-table" style="overflow:visible;">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Pages</th>
                            <th>Type</th>
                            <th>Assigned To</th>
                            <th>Status</th>
                            <th>Due Date</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody id="chapterTaskRows">
                        <tr><td colspan="7">Loading tasks...</td></tr>
                    </tbody>
                </table>
            </div>
            <div id="taskPopoverHost" style="position:absolute;left:-9999px;width:0;height:0;overflow:hidden;" aria-hidden="true">
                <div id="taskApprovePopover" class="task-action-popover" aria-hidden="true">
                    <strong id="approvePopoverTitle">Approve task</strong>
                    <label class="field-label" for="approvePopoverComment">Comment (optional)</label>
                    <textarea id="approvePopoverComment" maxlength="300" placeholder="Ghi chú cho assistant (tuỳ chọn)"></textarea>
                    <p class="popover-helper">Không điền vẫn có thể approve bình thường.</p>
                    <div class="popover-actions">
                        <button class="btn small" type="button" data-popover-cancel="approve">Cancel</button>
                        <button class="btn small success-soft" type="button" id="approvePopoverConfirm">Confirm approve</button>
                    </div>
                </div>
                <div id="taskRejectPopover" class="task-action-popover" aria-hidden="true">
                    <strong id="rejectPopoverTitle">Reject task</strong>
                    <label class="field-label" for="rejectPopoverReason">Lý do từ chối *</label>
                    <textarea id="rejectPopoverReason" maxlength="300" placeholder="Mô tả cần sửa gì..."></textarea>
                    <div class="popover-counter" id="rejectPopoverCounter">0 / 300</div>
                    <p class="popover-helper">Bắt buộc — người nhận task cần biết phải sửa gì.</p>
                    <div class="popover-actions">
                        <button class="btn small" type="button" data-popover-cancel="reject">Cancel</button>
                        <button class="btn small danger-soft" type="button" id="rejectPopoverConfirm" disabled>Confirm reject</button>
                    </div>
                </div>
            </div>
        </div>

        <div id="tabEdit" class="chapter-tab-panel" style="display:none;">
            <form id="chapterUpdateForm" class="form-grid chapter-inline-update-form" onsubmit="return false;">
                <input name="chapterId" type="hidden" id="updateChapterId" />
                <label class="field-label" for="updateTitle">Title</label>
                <input id="updateTitle" name="title" type="text" required />
                <label class="field-label" for="updateDeadline">Submission deadline</label>
                <input id="updateDeadline" name="submissionDeadline" type="date" required />
                <div id="updateError" class="alert error" style="display:none;"></div>
            </form>
        </div>
    </div>

    <aside>
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
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Pages</div>
                    <div id="metaPages" style="font-size:14px;font-weight:600;"></div>
                </div>
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Status</div>
                    <div id="metaStatus" style="margin-top:4px;"></div>
                </div>
                <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:10px;">
                    <div style="font-size:11px;color:#9ca3af;margin-bottom:3px;">Task progress</div>
                    <div id="metaProgress" style="font-size:14px;font-weight:600;"></div>
                </div>
            </div>
        </div>
        <div class="panel" style="margin-bottom:14px;">
            <strong style="font-size:13px;">Quy trình 3 bước</strong>
            <ol class="sidebar-stepper">
                <li><span class="step-num">1</span><span>Upload trang manuscript vào các ô trống</span></li>
                <li><span class="step-num">2</span><span>Chọn trang (Shift+click) và gán task cho assistant</span></li>
                <li><span class="step-num">3</span><span>Hoàn thành task → Submit chapter for review</span></li>
            </ol>
        </div>
        <div class="panel">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                <strong style="font-size:13px;">Tasks</strong>
                <button id="btnManualTask" class="btn small primary" type="button" style="display:none;font-size:11px;">Tạo task thủ công</button>
            </div>
            <div id="sidebarTaskList"><p class="section-desc" style="margin:0;">Loading...</p></div>
        </div>
    </aside>
</div>

<div id="assignTaskModal" class="modal-backdrop" aria-hidden="true">
    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="assignTaskTitle">
        <button class="modal-close" type="button" data-modal-close aria-label="Close">&times;</button>
        <h3 id="assignTaskTitle" class="section-title compact-title">Gán task cho trang</h3>
        <form id="assignTaskForm" class="form-grid">
            <label class="field-label">Trang đã chọn</label>
            <div id="assignPageChips" class="assign-chips"><span class="section-desc" style="margin:0;">Chưa chọn trang — chọn trên lưới Pages hoặc mở từ sidebar sau khi chọn.</span></div>
            <label class="field-label" for="assignTaskType">Task type</label>
            <select id="assignTaskType" name="taskType" required>
                <option value="">Select task type</option>
                <option value="SKETCHING">Sketching</option>
                <option value="INKING">Inking</option>
                <option value="COLORING">Coloring</option>
                <option value="LETTERING">Lettering</option>
                <option value="SCREENTONE">Screentone</option>
            </select>
            <label class="field-label" for="assignAssistantId">Assistant</label>
            <select id="assignAssistantId" name="assistantId" required>
                <option value="">Loading assistants...</option>
            </select>
            <label class="field-label" for="assignDueDate">Due date</label>
            <input id="assignDueDate" name="dueDate" type="date" required />
            <p id="assignDueHint" class="section-desc"></p>
            <label class="field-label" for="assignPriority">Priority</label>
            <select id="assignPriority" name="priority">
                <option value="NORMAL">Normal</option>
                <option value="HIGH">High</option>
                <option value="URGENT">Urgent</option>
            </select>
            <label class="field-label" for="assignNotes">Notes</label>
            <textarea id="assignNotes" name="notes" rows="3" placeholder="Hướng dẫn cho assistant..."></textarea>
            <div id="assignTaskError" class="alert error" style="display:none;"></div>
            <button class="btn primary" type="submit" id="assignTaskSubmit">Tạo task</button>
        </form>
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
    var pageSlots = [];
    var chapterTasks = [];
    var selectedPageIds = {};
    var lastSlotIndex = -1;
    var pendingUploadPageId = null;
    var activePopoverType = null;
    var activePopoverTaskId = null;
    var activePopoverCell = null;

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

    function initials(name) {
        if (!name) { return '?'; }
        var parts = String(name).trim().split(/\s+/).filter(Boolean);
        if (parts.length >= 2) {
            return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
        }
        return parts[0].substring(0, 2).toUpperCase();
    }

    function dateOnly(v) {
        var d = formatDate(v);
        return d ? new Date(d + 'T00:00:00') : null;
    }

    function daysUntilDate(value) {
        var due = dateOnly(value);
        if (!due) { return null; }
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        return Math.ceil((due - today) / 86400000);
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
        return currentUser && currentUser.roles && currentUser.roles.indexOf(role) !== -1;
    }

    function isOwner() {
        return hasRole('MANGAKA') && seriesData && Number(seriesData.mangakaId) === Number(currentUser.id);
    }

    async function callApi(method, path, data) {
        var opts = { method: method, headers: { 'Accept': 'application/json' } };
        var url = ctx + path;
        if (data) {
            var p = new URLSearchParams(data).toString();
            if (method === 'GET' || method === 'PUT' || method === 'PATCH') {
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

    async function uploadMultipart(path, formOrFile) {
        var fd;
        if (formOrFile instanceof FormData) {
            fd = formOrFile;
        } else if (formOrFile && formOrFile.tagName === 'FORM') {
            fd = new FormData(formOrFile);
        } else {
            fd = new FormData();
            fd.append('file', formOrFile);
        }
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

    function taskStatusClass(status) {
        status = String(status || '').toUpperCase();
        if (status === 'OVERDUE') { return 'status-overdue'; }
        if (status === 'IN_PROGRESS') { return 'status-progress'; }
        if (status === 'PENDING') { return 'status-pending'; }
        if (status === 'SUBMITTED') { return 'status-review'; }
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

    function imageUrl(fileUrl) {
        var url = String(fileUrl || '');
        if (url.indexOf('http://') === 0 || url.indexOf('https://') === 0) { return url; }
        if (url.indexOf(ctx + '/') === 0) { return url; }
        return ctx + url;
    }

    function findPageById(id) {
        for (var i = 0; i < pageSlots.length; i++) {
            if (Number(pageSlots[i].id) === Number(id)) { return pageSlots[i]; }
        }
        return null;
    }

    function getSelectedPages() {
        var ids = Object.keys(selectedPageIds);
        var out = [];
        for (var i = 0; i < ids.length; i++) {
            var p = findPageById(ids[i]);
            if (p) { out.push(p); }
        }
        out.sort(function (a, b) { return a.pageNumber - b.pageNumber; });
        return out;
    }

    function countUploaded() {
        var n = 0;
        for (var i = 0; i < pageSlots.length; i++) {
            if (String(pageSlots[i].status || '').toUpperCase() === 'UPLOADED') { n++; }
        }
        return n;
    }

    function countWithTask() {
        var n = 0;
        for (var i = 0; i < pageSlots.length; i++) {
            if (pageSlots[i].taskId) { n++; }
        }
        return n;
    }

    function slotStateClass(slot) {
        if (slot.taskId) { return 'state-task'; }
        if (String(slot.status || '').toUpperCase() === 'UPLOADED' || slot.imageUrl) { return 'state-uploaded'; }
        return 'state-empty';
    }

    function renderSelectionBar() {
        var selected = getSelectedPages();
        var bar = document.getElementById('selectionBar');
        if (!selected.length) {
            bar.classList.remove('visible');
            return;
        }
        bar.classList.add('visible');
        document.getElementById('selectionLabel').textContent = selected.length + ' trang đã chọn ('
            + selected[0].pageNumber + (selected.length > 1 ? '–' + selected[selected.length - 1].pageNumber : '') + ')';
    }

    function renderAssignChips() {
        var el = document.getElementById('assignPageChips');
        var selected = getSelectedPages();
        if (!selected.length) {
            el.innerHTML = '<span class="section-desc" style="margin:0;">Chưa chọn trang — chọn trên lưới Pages trước khi gán.</span>';
            document.getElementById('assignTaskSubmit').disabled = true;
            return;
        }
        document.getElementById('assignTaskSubmit').disabled = false;
        el.innerHTML = selected.map(function (p) {
            return '<span class="assign-chip">Trang ' + p.pageNumber + '</span>';
        }).join('');
    }

    function renderPageGrid() {
        var grid = document.getElementById('pageSlotGrid');
        var owner = isOwner();
        if (!pageSlots.length) {
            grid.innerHTML = '<p style="color:#9ca3af;grid-column:1/-1;font-size:13px;">Chưa có ô trang. '
                + (owner ? 'Nhấn + Thêm trang để bắt đầu.' : 'No page slots yet.') + '</p>'
                + (owner ? '<div class="page-slot page-slot-add" data-add-page="1" title="Thêm trang" style="grid-column:span 1;">+</div>' : '');
            return;
        }

        var html = pageSlots.map(function (slot, index) {
            var selected = !!selectedPageIds[String(slot.id)];
            var state = slotStateClass(slot);
            var cls = 'page-slot ' + state + (selected ? ' state-selected' : '');
            var num = '<span class="page-slot-num">' + slot.pageNumber + '</span>';
            var inner = '';
            if (state === 'state-empty') {
                inner = '<span class="page-slot-upload-label">+ Upload</span>';
            } else if (slot.imageUrl) {
                inner = '<img src="' + escapeHtml(imageUrl(slot.imageUrl)) + '" alt="Page ' + slot.pageNumber + '" />';
            }
            if (slot.taskId && slot.assistantName) {
                inner += '<span class="page-slot-initials" title="' + escapeHtml(slot.assistantName) + '">' + escapeHtml(initials(slot.assistantName)) + '</span>';
            }
            return '<div class="' + cls + '" data-page-id="' + slot.id + '" data-slot-index="' + index + '" data-page-number="' + slot.pageNumber + '">' + num + inner + '</div>';
        }).join('');

        if (owner) {
            html += '<div class="page-slot page-slot-add" data-add-page="1" title="Thêm trang">+</div>';
        }
        grid.innerHTML = html;
        renderSelectionBar();
    }

    function renderPageProgress() {
        var total = pageSlots.length;
        var withTask = countWithTask();
        var uploaded = countUploaded();
        var pct = total > 0 ? Math.round((withTask / total) * 100) : 0;
        document.getElementById('progressLabel').textContent = withTask + ' / ' + total + ' pages có task';
        document.getElementById('progressFill').style.width = pct + '%';
        document.getElementById('pageCountLabel').textContent = uploaded + ' / ' + total + ' đã upload';
        document.getElementById('tabPageCount').textContent = total;
        document.getElementById('metaPages').textContent = uploaded + ' / ' + total;
        document.getElementById('metaProgress').textContent = withTask + ' / ' + total + ' có task';
    }

    function renderSidebarTasks() {
        var el = document.getElementById('sidebarTaskList');
        if (!chapterTasks.length) {
            el.innerHTML = '<p class="section-desc" style="margin:0;">Chưa có task.</p>';
            return;
        }
        var preview = chapterTasks.slice(0, 5);
        el.innerHTML = preview.map(function (t) {
            return '<div class="sidebar-task-mini">'
                + '<strong>#' + t.id + '</strong> p.' + t.pageRangeStart + '-' + t.pageRangeEnd
                + ' · ' + escapeHtml(formatStatus(t.taskType))
                + '<br/><span class="status-chip ' + taskStatusClass(t.status) + '" style="font-size:10px;">' + formatStatus(t.status) + '</span>'
                + '</div>';
        }).join('')
            + (chapterTasks.length > 5 ? '<p class="section-desc" style="margin:8px 0 0;">+' + (chapterTasks.length - 5) + ' task khác — xem tab Tasks</p>' : '');
    }

    function renderMeta() {
        if (!chapter) { return; }
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
        document.getElementById('metaStatus').innerHTML =
            '<span class="status-chip chapter-status-chip ' + chapterStatusClass(chapter.status) + '">' + formatStatus(chapter.status) + '</span>';

        document.getElementById('updateChapterId').value = chapter.id;
        document.getElementById('updateTitle').value = chapter.title || '';
        document.getElementById('updateDeadline').value = formatDate(chapter.submissionDeadline) || '';

        var owner = isOwner();
        var canSubmit = owner && progress >= 100 && String(chapter.status || '').toUpperCase() === 'COMPLETE'
            && seriesData && String(seriesData.status || '').toUpperCase() !== 'CANCELLED';

        document.getElementById('btnDelete').style.display = (owner && String(chapter.status || '').toUpperCase() === 'PLANNING') ? '' : 'none';
        document.getElementById('btnSave').style.display = owner ? '' : 'none';
        document.getElementById('btnMarkDone').style.display = canSubmit ? '' : 'none';
        document.getElementById('pagesOwnerActions').style.display = owner ? 'flex' : 'none';
        document.getElementById('pagesOwnerActions').style.gap = '8px';
        document.getElementById('btnManualTask').style.display = owner ? '' : 'none';
        document.getElementById('pagesHint').style.display = owner ? '' : 'none';

        updateAssignDueConstraints();
        renderPageProgress();
    }

    function findTask(taskId) {
        for (var i = 0; i < chapterTasks.length; i++) {
            if (Number(chapterTasks[i].id) === Number(taskId)) { return chapterTasks[i]; }
        }
        return null;
    }

    function isTaskOverdue(task) {
        var st = String(task.status || '').toUpperCase();
        if (st === 'APPROVED') { return false; }
        if (st === 'OVERDUE') { return true; }
        if (!task.dueDate) { return false; }
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var due = dateOnly(task.dueDate);
        return due && due < today;
    }

    function formatDueDateCell(task) {
        var formatted = formatDate(task.dueDate);
        if (!formatted) { return '—'; }
        var done = String(task.status || '').toUpperCase() === 'APPROVED';
        var overdue = isTaskOverdue(task);
        return formatDeadlineCell(task.dueDate, done, overdue);
    }

    function renderTaskRowActions(task) {
        if (task._decisionLabel === 'approved') {
            return '<span class="task-decision-label approved">Approved</span>';
        }
        if (task._decisionLabel === 'rejected') {
            return '<span class="task-decision-label rejected">Rejected</span>';
        }
        var st = String(task.status || '').toUpperCase();
        var html = '<a class="btn small" href="' + ctx + '/main/tasks/' + task.id + '">View</a>';
        if (isOwner() && st === 'SUBMITTED') {
            html += ' <button class="btn small success-soft" type="button" data-task-approve-pop="' + task.id + '">Approve</button>';
            html += ' <button class="btn small danger-soft" type="button" data-task-reject-pop="' + task.id + '">Reject</button>';
        }
        return html;
    }

    function renderChapterTasks() {
        var tbody = document.getElementById('chapterTaskRows');
        document.getElementById('tabTaskCount').textContent = chapterTasks.length;
        if (!chapterTasks.length) {
            tbody.innerHTML = '<tr><td colspan="7">No tasks for this chapter.</td></tr>';
            renderSidebarTasks();
            return;
        }
        tbody.innerHTML = chapterTasks.map(function (task) {
            return '<tr>'
                + '<td>' + task.id + '</td>'
                + '<td>' + task.pageRangeStart + '-' + task.pageRangeEnd + '</td>'
                + '<td>' + formatStatus(task.taskType) + '</td>'
                + '<td>' + escapeHtml(task.assistantName || '') + '</td>'
                + '<td><span class="status-chip ' + taskStatusClass(task.status) + '">' + formatStatus(task.status) + '</span></td>'
                + '<td>' + formatDueDateCell(task) + '</td>'
                + '<td class="task-actions-cell"><div class="task-row-actions">' + renderTaskRowActions(task) + '</div></td>'
                + '</tr>';
        }).join('');
        renderSidebarTasks();
    }

    function switchTab(tab) {
        document.querySelectorAll('.chapter-tab-btn').forEach(function (b) {
            b.classList.toggle('active', b.getAttribute('data-tab') === tab);
        });
        document.getElementById('tabPages').style.display = tab === 'pages' ? '' : 'none';
        document.getElementById('tabTasks').style.display = tab === 'tasks' ? '' : 'none';
        document.getElementById('tabEdit').style.display = tab === 'edit' ? '' : 'none';
    }

    function openModal(id) {
        var modal = document.getElementById(id);
        if (modal) {
            modal.classList.add('open');
            modal.setAttribute('aria-hidden', 'false');
        }
    }

    function closeModals() {
        document.querySelectorAll('.modal-backdrop').forEach(function (m) {
            m.classList.remove('open');
            m.setAttribute('aria-hidden', 'true');
        });
    }

    function closePopovers() {
        var host = document.getElementById('taskPopoverHost');
        var approvePop = document.getElementById('taskApprovePopover');
        var rejectPop = document.getElementById('taskRejectPopover');
        if (approvePop) {
            approvePop.classList.remove('open');
            approvePop.setAttribute('aria-hidden', 'true');
            if (host) { host.appendChild(approvePop); }
        }
        if (rejectPop) {
            rejectPop.classList.remove('open');
            rejectPop.setAttribute('aria-hidden', 'true');
            if (host) { host.appendChild(rejectPop); }
        }
        activePopoverType = null;
        activePopoverTaskId = null;
        activePopoverCell = null;
    }

    function openPopover(type, taskId, anchorCell) {
        closePopovers();
        var task = findTask(taskId);
        if (!task || !anchorCell) { return; }
        var popId = type === 'approve' ? 'taskApprovePopover' : 'taskRejectPopover';
        var pop = document.getElementById(popId);
        if (!pop) { return; }
        anchorCell.appendChild(pop);
        pop.classList.add('open');
        pop.setAttribute('aria-hidden', 'false');
        activePopoverType = type;
        activePopoverTaskId = taskId;
        activePopoverCell = anchorCell;
        if (type === 'approve') {
            document.getElementById('approvePopoverTitle').textContent = 'Approve task #' + task.id;
            document.getElementById('approvePopoverComment').value = '';
        } else {
            document.getElementById('rejectPopoverTitle').textContent = 'Reject task #' + task.id;
            document.getElementById('rejectPopoverReason').value = '';
            updateRejectConfirmState();
        }
    }

    function updateRejectConfirmState() {
        var reasonEl = document.getElementById('rejectPopoverReason');
        var counterEl = document.getElementById('rejectPopoverCounter');
        var confirmBtn = document.getElementById('rejectPopoverConfirm');
        if (!reasonEl || !confirmBtn) { return; }
        var len = reasonEl.value.length;
        if (counterEl) { counterEl.textContent = len + ' / 300'; }
        confirmBtn.disabled = len < 5;
    }

    function openAssignModal() {
        renderAssignChips();
        var err = document.getElementById('assignTaskError');
        err.style.display = 'none';
        err.textContent = '';
        openModal('assignTaskModal');
    }

    async function fillAssistantSelect() {
        var select = document.getElementById('assignAssistantId');
        if (!chapter || !select) { return; }
        select.innerHTML = '<option value="">Loading assistants...</option>';
        try {
            var res = await callApi('GET', '/api/v1/series/' + chapter.seriesId + '/assistants');
            var assistants = res.data || [];
            select.innerHTML = '<option value="">Select Assistant</option>' + assistants.map(function (a) {
                return '<option value="' + a.id + '">#' + a.id + ' - ' + escapeHtml(a.fullName || a.username) + '</option>';
            }).join('');
        } catch (err) {
            select.innerHTML = '<option value="">Cannot load assistants</option>';
            showError(err.message);
        }
    }

    function updateAssignDueConstraints() {
        var dueInput = document.getElementById('assignDueDate');
        var hint = document.getElementById('assignDueHint');
        if (!dueInput) { return; }
        dueInput.min = todayIso();
        dueInput.removeAttribute('max');
        var latest = chapter && chapter.submissionDeadline ? addDaysIso(chapter.submissionDeadline, -3) : '';
        if (latest) {
            dueInput.max = latest;
        }
        if (hint) {
            hint.textContent = chapter && chapter.submissionDeadline
                ? ('Chapter deadline: ' + formatDate(chapter.submissionDeadline) + '. Task due date: today → ' + (latest || formatDate(chapter.submissionDeadline)) + '.')
                : '';
        }
    }

    async function loadPages() {
        var res = await callApi('GET', '/api/v1/chapters/' + chapterId + '/pages');
        pageSlots = res.data || [];
        renderPageGrid();
        renderPageProgress();
        renderMeta();
    }

    async function loadTasks() {
        var res = await callApi('GET', '/api/v1/chapters/' + chapterId + '/tasks');
        chapterTasks = res.data || [];
        renderChapterTasks();
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
            await Promise.all([loadPages(), loadTasks(), fillAssistantSelect()]);
            renderMeta();
        } catch (err) {
            showError(err.message);
        }
    }

    document.getElementById('tabBar').addEventListener('click', function (e) {
        var btn = e.target.closest('.chapter-tab-btn');
        if (!btn) { return; }
        switchTab(btn.getAttribute('data-tab'));
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
            showError('');
        } catch (err) { showError(err.message); }
    });

    document.getElementById('btnAddPage').addEventListener('click', async function () {
        try {
            await callApi('POST', '/api/v1/pages', { chapterId: chapterId });
            await loadPages();
        } catch (err) { showError(err.message); }
    });

    document.getElementById('btnBulkUpload').addEventListener('click', function () {
        document.getElementById('bulkFileInput').click();
    });

    document.getElementById('bulkFileInput').addEventListener('change', async function (e) {
        var files = Array.prototype.slice.call(e.target.files || []);
        e.target.value = '';
        if (!files.length) { return; }
        files.sort(function (a, b) {
            return String(a.name).localeCompare(String(b.name), undefined, { numeric: true, sensitivity: 'base' });
        });
        var emptySlots = pageSlots.filter(function (p) {
            return String(p.status || '').toUpperCase() === 'EMPTY' && !p.imageUrl;
        }).sort(function (a, b) { return a.pageNumber - b.pageNumber; });
        try {
            var count = Math.min(files.length, emptySlots.length);
            for (var i = 0; i < count; i++) {
                var fd = new FormData();
                fd.append('file', files[i]);
                await uploadMultipart('/api/v1/pages/' + emptySlots[i].id + '/upload', fd);
            }
            if (files.length > emptySlots.length) {
                showError('Chỉ upload được ' + emptySlots.length + ' file — hết ô trống. Thêm trang hoặc bỏ bớt file.');
            } else {
                showError('');
            }
            await loadPages();
        } catch (err) {
            showError(err.message);
        }
    });

    document.getElementById('singleFileInput').addEventListener('change', async function (e) {
        var file = e.target.files && e.target.files[0];
        e.target.value = '';
        if (!file || !pendingUploadPageId) { return; }
        try {
            var fd = new FormData();
            fd.append('file', file);
            await uploadMultipart('/api/v1/pages/' + pendingUploadPageId + '/upload', fd);
            pendingUploadPageId = null;
            showError('');
            await loadPages();
        } catch (err) {
            showError(err.message);
        }
    });

    document.getElementById('pageSlotGrid').addEventListener('click', function (e) {
        var addBtn = e.target.closest('[data-add-page]');
        if (addBtn && isOwner()) {
            document.getElementById('btnAddPage').click();
            return;
        }
        var slotEl = e.target.closest('[data-page-id]');
        if (!slotEl) { return; }
        var pageId = slotEl.getAttribute('data-page-id');
        var index = Number(slotEl.getAttribute('data-slot-index'));
        var slot = findPageById(pageId);
        if (!slot) { return; }

        if (e.shiftKey) {
            if (lastSlotIndex < 0) {
                selectedPageIds[String(pageId)] = true;
            } else {
                var start = Math.min(lastSlotIndex, index);
                var end = Math.max(lastSlotIndex, index);
                for (var i = start; i <= end; i++) {
                    selectedPageIds[String(pageSlots[i].id)] = true;
                }
            }
            lastSlotIndex = index;
            renderPageGrid();
            return;
        }

        lastSlotIndex = index;

        if (!isOwner()) {
            return;
        }

        if (selectedPageIds[String(pageId)]) {
            delete selectedPageIds[String(pageId)];
            renderPageGrid();
            return;
        }

        var isEmpty = String(slot.status || '').toUpperCase() === 'EMPTY' && !slot.imageUrl;
        if (isEmpty) {
            pendingUploadPageId = pageId;
            document.getElementById('singleFileInput').click();
            return;
        }

        selectedPageIds[String(pageId)] = true;
        renderPageGrid();
    });

    document.getElementById('btnClearSelection').addEventListener('click', function () {
        selectedPageIds = {};
        lastSlotIndex = -1;
        renderPageGrid();
    });

    document.getElementById('btnAssignFromSelection').addEventListener('click', function () {
        if (!getSelectedPages().length) { return; }
        openAssignModal();
    });

    document.getElementById('btnManualTask').addEventListener('click', function () {
        openAssignModal();
    });

    document.getElementById('assignTaskForm').addEventListener('submit', async function (e) {
        e.preventDefault();
        var errEl = document.getElementById('assignTaskError');
        errEl.style.display = 'none';
        var selected = getSelectedPages();
        if (!selected.length) {
            errEl.style.display = 'block';
            errEl.textContent = 'Chọn ít nhất một trang trên lưới Pages.';
            return;
        }
        var pageNums = selected.map(function (p) { return p.pageNumber; });
        var minPage = Math.min.apply(null, pageNums);
        var maxPage = Math.max.apply(null, pageNums);
        try {
            await callApi('POST', '/api/v1/chapters/' + chapterId + '/tasks', {
                assistantId: document.getElementById('assignAssistantId').value,
                pageRangeStart: minPage,
                pageRangeEnd: maxPage,
                taskType: document.getElementById('assignTaskType').value,
                dueDate: document.getElementById('assignDueDate').value,
                priority: document.getElementById('assignPriority').value,
                notes: document.getElementById('assignNotes').value
            });
            selectedPageIds = {};
            e.target.reset();
            closeModals();
            showError('');
            await Promise.all([loadPages(), loadTasks()]);
        } catch (err) {
            errEl.style.display = 'block';
            errEl.textContent = err.message;
        }
    });

    document.addEventListener('click', function (e) {
        var approvePopBtn = e.target.closest('[data-task-approve-pop]');
        if (approvePopBtn) {
            openPopover('approve', approvePopBtn.getAttribute('data-task-approve-pop'), approvePopBtn.closest('.task-actions-cell'));
            return;
        }
        var rejectPopBtn = e.target.closest('[data-task-reject-pop]');
        if (rejectPopBtn) {
            openPopover('reject', rejectPopBtn.getAttribute('data-task-reject-pop'), rejectPopBtn.closest('.task-actions-cell'));
            return;
        }
        if (e.target.closest('[data-popover-cancel]')) {
            closePopovers();
            return;
        }
        var insidePopover = e.target.closest('.task-action-popover');
        var insideActions = e.target.closest('.task-row-actions');
        if (!insidePopover && !insideActions && activePopoverType) {
            closePopovers();
        }
        if (e.target.closest('[data-modal-close]')) {
            closeModals();
            return;
        }
        if (e.target.classList.contains('modal-backdrop')) {
            closeModals();
        }
    });

    document.getElementById('approvePopoverConfirm').addEventListener('click', async function () {
        if (!activePopoverTaskId) { return; }
        try {
            var comment = document.getElementById('approvePopoverComment').value.trim();
            var payload = comment ? { comment: comment } : {};
            await callApi('POST', '/api/v1/tasks/' + activePopoverTaskId + '/approve', payload);
            closePopovers();
            var t = findTask(activePopoverTaskId);
            if (t) { t._decisionLabel = 'approved'; t.status = 'APPROVED'; }
            renderChapterTasks();
            await loadPages();
            showError('');
        } catch (err) { showError(err.message); }
    });

    document.getElementById('rejectPopoverConfirm').addEventListener('click', async function () {
        if (!activePopoverTaskId) { return; }
        var reason = document.getElementById('rejectPopoverReason').value.trim();
        if (reason.length < 5) { return; }
        try {
            await callApi('POST', '/api/v1/tasks/' + activePopoverTaskId + '/reject', { reason: reason });
            closePopovers();
            var t = findTask(activePopoverTaskId);
            if (t) { t._decisionLabel = 'rejected'; t.status = 'IN_PROGRESS'; }
            renderChapterTasks();
            await loadPages();
            showError('');
        } catch (err) { showError(err.message); }
    });

    document.getElementById('rejectPopoverReason').addEventListener('input', updateRejectConfirmState);

    if (urlError) {
        showError(decodeURIComponent(urlError));
    }

    loadData();
})();
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
