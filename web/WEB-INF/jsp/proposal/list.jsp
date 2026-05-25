<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Proposals</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<div class="section-head">
    <div>
        <h2 class="page-title">Proposals</h2>
        <p class="page-sub">Manage manga proposals and Tantou review</p>
    </div>
    <c:if test="${isMangaka}">
        <a class="btn primary" href="${pageContext.request.contextPath}/main/proposals/create">+ New Proposal</a>
    </c:if>
</div>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-card">
    <h3 class="section-title">Proposals</h3>
    <table class="data-table">
        <thead>
            <tr>
                <th>Title</th>
                <th>Genre</th>
                <th>Approx. Chapter</th>
                <th>Status</th>
                <th>Board Votes</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
            <c:forEach items="${proposals}" var="p">
                <tr>
                    <td><strong>${p.title}</strong></td>
                    <td>${p.genre}</td>
                    <td>${p.approximateChapter}</td>
                    <td>
                        <span class="status-chip ${p.status=='UNDER_REVIEW' || p.status=='BOARD_REVIEW' ? 'status-review' : (p.status=='DRAFT' || p.status=='REVISION_REQUESTED' ? 'status-draft' : (p.status=='APPROVED' ? 'status-approved' : 'status-rejected'))}">${p.status}</span>
                    </td>
                    <td>
                        <c:choose>
                            <c:when test="${p.status == 'BOARD_REVIEW'}">
                                <strong>${p.boardTotalVotes}/3</strong>
                                <span style="color:#6b7280;font-size:12px;">(${p.boardApproveVotes} approve, ${p.boardReviseVotes} revise, ${p.boardRejectVotes} reject)</span>
                            </c:when>
                            <c:when test="${p.boardTotalVotes > 0}">
                                <strong>${p.boardTotalVotes}/3</strong>
                                <span style="color:#6b7280;font-size:12px;">(${p.boardApproveVotes} approve, ${p.boardReviseVotes} revise, ${p.boardRejectVotes} reject)</span>
                            </c:when>
                            <c:otherwise>
                                <span style="color:#9ca3af;">Not started</span>
                            </c:otherwise>
                        </c:choose>
                    </td>
                    <td><a class="btn small" href="${pageContext.request.contextPath}/main/proposals/${p.id}">View</a></td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
