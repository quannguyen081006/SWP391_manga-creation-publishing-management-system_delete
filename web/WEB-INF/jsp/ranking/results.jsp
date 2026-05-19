<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ranking Results</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Ranking Results</h2>
<p class="page-sub">Period: ${period.name} (${period.status})</p>

<div class="section-card">
    <h3 class="section-title">Result Board</h3>
    <table class="data-table">
        <thead><tr><th>Rank</th><th>Series ID</th><th>Score</th><th>Bottom 20%</th><th>Calculated</th></tr></thead>
        <tbody>
            <c:forEach items="${results}" var="r">
                <tr>
                    <td>${r.rankPosition}</td>
                    <td>${r.seriesId}</td>
                    <td>${r.rankScore}</td>
                    <td>${r.isBottomTwenty}</td>
                    <td>${r.calculatedAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty results}"><tr><td colspan="5">No results yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<div class="section-card">
    <h3 class="section-title">Submitted Entries</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Series</th><th>Board Member</th><th>Vote</th><th>Reader</th><th>At</th></tr></thead>
        <tbody>
            <c:forEach items="${entries}" var="e">
                <tr>
                    <td>${e.id}</td>
                    <td>${e.seriesId}</td>
                    <td>${e.boardMemberId}</td>
                    <td>${e.voteCount}</td>
                    <td>${e.readerCount}</td>
                    <td>${e.submittedAt}</td>
                </tr>
            </c:forEach>
            <c:if test="${empty entries}"><tr><td colspan="6">No entries yet.</td></tr></c:if>
        </tbody>
    </table>
</div>

<div style="margin-top:10px;"><a class="btn" href="${pageContext.request.contextPath}/main/ranking/periods">Back</a></div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
