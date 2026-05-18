<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Audit Logs</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Audit Logs</h2>
<p class="page-sub">Append-only history of admin and workflow actions</p>

<div class="section-card audit-filter-card">
    <form method="get" action="${pageContext.request.contextPath}/main/audit-logs" class="audit-filter-form">
        <label>
            <span>Actor ID</span>
            <input type="number" name="actorId" value="${actorId}" min="1" placeholder="Any" />
        </label>
        <label>
            <span>Action</span>
            <select name="action">
                <option value="">Any</option>
                <c:forEach items="${availableActions}" var="availableAction">
                    <option value="${availableAction}" ${action == availableAction ? 'selected' : ''}>${availableAction}</option>
                </c:forEach>
            </select>
        </label>
        <label>
            <span>Entity</span>
            <select name="entityType">
                <option value="">Any</option>
                <option value="USER" ${entityType == 'USER' ? 'selected' : ''}>USER</option>
                <option value="TASK" ${entityType == 'TASK' ? 'selected' : ''}>TASK</option>
                <option value="MANUSCRIPT" ${entityType == 'MANUSCRIPT' ? 'selected' : ''}>MANUSCRIPT</option>
                <option value="PROPOSAL" ${entityType == 'PROPOSAL' ? 'selected' : ''}>PROPOSAL</option>
                <option value="SERIES" ${entityType == 'SERIES' ? 'selected' : ''}>SERIES</option>
            </select>
        </label>
        <label>
            <span>Limit</span>
            <input type="number" name="limit" value="${limit}" min="1" max="500" />
        </label>
        <div class="audit-filter-actions">
            <button class="btn primary" type="submit">Filter</button>
            <a class="btn" href="${pageContext.request.contextPath}/main/audit-logs">Reset</a>
        </div>
    </form>
</div>

<div class="section-card">
    <div class="section-head">
        <div>
            <h3 class="section-title compact-title">Recent Activity</h3>
            <p class="section-desc">${limit} latest matching records</p>
        </div>
        <a class="btn small" href="${pageContext.request.contextPath}/api/v1/audit-logs?limit=${limit}" target="_blank">Open API</a>
    </div>

    <table class="data-table audit-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Time</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Entity</th>
                <th>Detail</th>
            </tr>
        </thead>
        <tbody>
            <c:choose>
                <c:when test="${empty auditLogs}">
                    <tr>
                        <td colspan="6" class="muted">No audit records found.</td>
                    </tr>
                </c:when>
                <c:otherwise>
                    <c:forEach items="${auditLogs}" var="log">
                        <tr>
                            <td>#${log.id}</td>
                            <td class="audit-time">${log.performedAt}</td>
                            <td>
                                <c:choose>
                                    <c:when test="${empty log.actorId}">
                                        <span class="muted">System</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="audit-actor">User #${log.actorId}</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td><span class="audit-action">${log.action}</span></td>
                            <td><span class="status-chip status-draft">${log.entityType} #${log.entityId}</span></td>
                            <td><code class="audit-detail">${log.detail}</code></td>
                        </tr>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
