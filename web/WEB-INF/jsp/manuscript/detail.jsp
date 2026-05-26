<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manuscript Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Manuscript #${manuscript.id}</h2>
<p class="page-sub">${manuscript.seriesTitle} - Ch. ${manuscript.chapterNumber} ${manuscript.chapterTitle}</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card detail-grid">
    <div><span class="detail-label">Current Version</span><strong>v${manuscript.version} ${isCurrentVersion ? '(current)' : '(history)'}</strong></div>
    <div><span class="detail-label">Mangaka</span><strong>${manuscript.mangakaName}</strong></div>
    <div><span class="detail-label">Version</span><strong>v${manuscript.version}</strong></div>
    <div><span class="detail-label">Submitted</span><strong>${manuscript.submittedAt}</strong></div>
    <div><span class="detail-label">SLA Deadline</span><strong>${manuscript.reviewDeadline}</strong></div>
    <div><span class="detail-label">Status</span><span class="status-chip ${manuscript.status=='APPROVED' ? 'status-approved' : (manuscript.status=='REJECTED' ? 'status-rejected' : 'status-voting')}">${manuscript.status}</span></div>
    <div><span class="detail-label">File / Path</span><strong>${manuscript.fileUrl}</strong></div>
    <div><span class="detail-label">Synopsis</span><strong>${manuscript.synopsis}</strong></div>
    <c:if test="${not empty manuscript.revisionDeadline}">
        <div><span class="detail-label">Revision Deadline</span><strong>${manuscript.revisionDeadline}</strong></div>
    </c:if>
    <c:if test="${not empty manuscript.feedback}">
        <div><span class="detail-label">Feedback</span><strong>${manuscript.feedback}</strong></div>
    </c:if>
</div>

<!-- VERSION HISTORY -->
<div class="section-card">
    <h3 class="section-title compact-title">Version History</h3>
    <table class="data-table">
        <thead><tr><th>Version</th><th>Status</th><th>Submitted</th><th>Reviewer</th><th>Action</th></tr></thead>
        <tbody>
            <c:forEach items="${versionHistory}" var="v">
                <tr class="${v.id == manuscript.id ? 'row-current' : ''}">
                    <td>v${v.version} ${v.id == manuscript.id ? '(current)' : ''}</td>
                    <td><span class="status-chip ${v.status=='APPROVED' ? 'status-approved' : (v.status=='REJECTED' ? 'status-rejected' : 'status-voting')}">${v.status}</span></td>
                    <td>${v.submittedAt}</td>
                    <td>${v.reviewerName}</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/manuscripts/${v.id}">View Detail</a></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
</div>

<!-- MANGAKA: Manuscript Actions -->
<c:if test="${isMangakaOwner}">
    <div class="section-card">
        <h3 class="section-title compact-title">Manuscript Actions</h3>
        <div class="row-actions">
            <!-- SUBMIT TO EDITOR button -->
            <c:if test="${canSubmitToEditor}">
                <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/submit" style="display: inline;">
                    <button class="btn small primary" type="submit">Submit to Editor</button>
                </form>
            </c:if>
            <!-- EDIT button -->
            <c:if test="${canEdit}">
                <a class="btn small" href="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/edit">Edit</a>
            </c:if>
            <!-- DELETE button -->
            <c:if test="${canDelete}">
                <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/delete" style="display: inline;">
                    <button class="btn small danger-soft" type="submit" onclick="return confirm('Delete this manuscript? This cannot be undone.');">Delete</button>
                </form>
            </c:if>
            <c:if test="${canCreateNextVersion}">
                <a class="btn small primary" href="${pageContext.request.contextPath}/main/manuscripts/create?chapterId=${manuscript.chapterId}">Create Next Version</a>
            </c:if>
        </div>
    </div>
</c:if>

<!-- TANTOU EDITOR: Start Review button -->
<c:if test="${canStartReview}">
    <div class="section-card">
        <h3 class="section-title compact-title">Start Review</h3>
        <div class="row-actions">
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/start-review" style="display: inline;">
                <button class="btn small primary" type="submit">Start Review</button>
            </form>
        </div>
    </div>
</c:if>

<!-- TANTOU EDITOR: Approve/Reject buttons -->
<c:if test="${canApproveReject}">
    <div class="section-card">
        <h3 class="section-title compact-title">Tantou Review</h3>
        <div class="row-actions">
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/approve" style="display: inline;">
                <button class="btn small success-soft" type="submit">Approve</button>
            </form>
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/reject" style="display: inline;">
                <input type="text" name="feedback" placeholder="Feedback (required)" required style="margin-right: 5px; padding: 4px 8px;" />
                <button class="btn small danger-soft" type="submit" onclick="return confirm('Reject this manuscript?');">Reject</button>
            </form>
            <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/request-revision" style="display: inline;">
                <input type="text" name="feedback" placeholder="Revision note (required)" required style="margin-right: 5px; padding: 4px 8px;" />
                <button class="btn small" type="submit">Request Revision</button>
            </form>
        </div>
    </div>
</c:if>

<!-- TANTOU EDITOR: Add Annotation button -->
<c:if test="${canAddAnnotation}">
    <div class="section-card">
        <h3 class="section-title compact-title">Add Annotation</h3>
        <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/${manuscript.id}/annotate" class="form-grid">
            <label>Page Number</label>
            <input type="number" name="pageNumber" min="1" required />
            <label>Content</label>
            <textarea name="content" rows="4" required></textarea>
            <button class="btn primary" type="submit">Add Annotation</button>
        </form>
    </div>
</c:if>

<!-- Annotations -->
<div class="section-card">
    <h3 class="section-title compact-title">Annotations (v${manuscript.version})</h3>
    <table class="data-table">
        <thead><tr><th>Page</th><th>Content</th><th>Created</th></tr></thead>
        <tbody>
            <c:forEach items="${annotations}" var="a">
                <tr><td>${a.pageNumber}</td><td>${a.content}</td><td>${a.createdAt}</td></tr>
            </c:forEach>
            <c:if test="${empty annotations}"><tr><td colspan="3" class="muted">No annotations yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<div class="section-card">
    <h3 class="section-title compact-title">Review History</h3>
    <table class="data-table">
        <thead><tr><th>Action</th><th>Actor</th><th>Detail</th><th>Performed</th></tr></thead>
        <tbody>
            <c:forEach items="${reviewHistory}" var="h">
                <tr><td>${h.action}</td><td>${h.actorId}</td><td>${h.detail}</td><td>${h.performedAt}</td></tr>
            </c:forEach>
            <c:if test="${empty reviewHistory}"><tr><td colspan="4" class="muted">No review history yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/manuscripts">Back to Manuscripts</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
