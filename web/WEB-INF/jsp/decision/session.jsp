<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Decision Sessions</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Decision Sessions</h2>
<p class="page-sub">Review sessions and cast board decisions</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<c:if test="${not empty sessions}">
<div class="section-card">
    <h3 class="section-title">All Sessions</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Series</th><th>Status</th><th>Result</th><th>Opened</th><th></th></tr></thead>
        <tbody>
            <c:forEach items="${sessions}" var="s">
                <tr>
                    <td>${s.id}</td>
                    <td>${s.seriesId}</td>
                    <td>${s.status}</td>
                    <td>${s.result}</td>
                    <td>${s.openedAt}</td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/decisions/${s.id}">Detail</a></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
</div>
</c:if>

<c:if test="${not empty sessionDetail}">
<div class="section-card">
    <h3 class="section-title">Session #${sessionDetail.id}</h3>
    <div class="inline-meta">
        <span>Series: ${sessionDetail.seriesId}</span>
        <span>Status: ${sessionDetail.status}</span>
        <span>Result: ${sessionDetail.result}</span>
    </div>

    <c:if test="${sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}">
        <form method="post" action="${pageContext.request.contextPath}/main/decisions/${sessionDetail.id}/votes" class="decision-vote-form">
            <div>
                <label>Decision</label>
                <select name="decision">
                    <option value="CONTINUE">CONTINUE</option>
                    <option value="CANCEL">CANCEL</option>
                    <option value="CHANGE_TYPE">CHANGE_TYPE</option>
                </select>
            </div>
            <div>
                <label>Justification (required for CANCEL)</label>
                <input type="text" name="justification" />
            </div>
            <div><button class="btn primary" type="submit">Cast Vote</button></div>
        </form>
    </c:if>
</div>

<div class="section-card">
    <h3 class="section-title">Votes</h3>
    <table class="data-table">
        <thead><tr><th>Voter</th><th>Decision</th><th>Justification</th><th>At</th></tr></thead>
        <tbody>
            <c:forEach items="${sessionDetail.votes}" var="v">
                <tr>
                    <td>${v.voterId}</td>
                    <td>${v.decision}</td>
                    <td>${v.justification}</td>
                    <td>${v.votedAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty sessionDetail.votes}"><tr><td colspan="4">No votes yet.</td></tr></c:if>
        </tbody>
    </table>
</div>
</c:if>

<jsp:include page="../common/footer.jsp" />
</body>
</html>

