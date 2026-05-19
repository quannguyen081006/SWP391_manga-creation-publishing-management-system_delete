<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ranking Periods</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Ranking Periods</h2>
<p class="page-sub">Manage ranking cycles and vote entries</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<c:if test="${sessionScope.AUTH_USER.hasRole('ADMIN')}">
<div class="section-card">
    <h3 class="section-title">Create Period (Admin)</h3>
    <form method="post" action="${pageContext.request.contextPath}/main/ranking/periods/create" style="display:grid;grid-template-columns:2fr 1fr 1fr auto;gap:10px;align-items:end;">
        <div><label>Name</label><input type="text" name="name" required /></div>
        <div><label>Start</label><input type="date" name="startDate" required /></div>
        <div><label>End</label><input type="date" name="endDate" required /></div>
        <div><button class="btn primary" type="submit">Create</button></div>
    </form>
</div>
</c:if>

<div class="section-card">
    <h3 class="section-title">Periods</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Name</th><th>Window</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
            <c:forEach items="${periods}" var="p">
                <tr>
                    <td>${p.id}</td>
                    <td>${p.name}</td>
                    <td>${p.startDate} → ${p.endDate}</td>
                    <td>${p.status}</td>
                    <td>
                        <a class="btn small" href="${pageContext.request.contextPath}/main/ranking/periods/${p.id}/results">Results</a>
                        <c:if test="${sessionScope.AUTH_USER.hasRole('ADMIN')}">
                            <form method="post" action="${pageContext.request.contextPath}/main/ranking/periods/${p.id}/close" style="display:inline-block;">
                                <button class="btn small" type="submit">Close</button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/main/ranking/periods/${p.id}/calculate" style="display:inline-block;">
                                <button class="btn small" type="submit">Calculate</button>
                            </form>
                        </c:if>
                    </td>
                </tr>
                <c:if test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}">
                <tr>
                    <td colspan="5">
                        <form method="post" action="${pageContext.request.contextPath}/main/ranking/periods/${p.id}/entries" style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:8px;align-items:end;">
                            <div>
                                <label>Series</label>
                                <select name="seriesId" required>
                                    <c:forEach items="${seriesList}" var="s">
                                        <option value="${s.id}">${s.title} (#${s.id})</option>
                                    </c:forEach>
                                </select>
                            </div>
                            <div><label>Vote Count</label><input type="number" min="0" name="voteCount" required /></div>
                            <div><label>Reader Count</label><input type="number" min="1" name="readerCount" required /></div>
                            <div><button class="btn" type="submit">Submit Entry</button></div>
                        </form>
                    </td>
                </tr>
                </c:if>
            </c:forEach>
            <c:if test="${empty periods}"><tr><td colspan="5">No ranking periods.</td></tr></c:if>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
