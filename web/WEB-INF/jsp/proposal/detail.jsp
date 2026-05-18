<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Proposal Detail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<main class="container">
    <h1>Proposal #${proposal.id} - ${proposal.title}</h1>

    <c:if test="${not empty error}">
        <div class="alert error">${error}</div>
    </c:if>

    <div class="panel">
        <p><strong>Genre:</strong> ${proposal.genre}</p>
        <p><strong>Status:</strong> <span class="chip">${proposal.status}</span></p>
        <p><strong>Synopsis:</strong></p>
        <p>${proposal.synopsis}</p>
        <p><strong>Votes:</strong> Approve ${proposal.approveVotes} | Reject ${proposal.rejectVotes} | Abstain ${proposal.abstainVotes}</p>
    </div>

    <c:if test="${canSubmit}">
        <div class="action-row">
            <form method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/submit">
                <button class="btn" type="submit">Submit To Editorial Board</button>
            </form>
        </div>
    </c:if>

    <c:if test="${canVote}">
        <div class="panel">
            <h2>Cast Vote (Editorial Board)</h2>
            <form method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/vote" class="form-grid">
                <label>Vote</label>
                <select name="voteType">
                    <option value="APPROVE">APPROVE</option>
                    <option value="REJECT">REJECT</option>
                    <option value="ABSTAIN">ABSTAIN</option>
                </select>

                <label>Reason (required for REJECT)</label>
                <textarea name="reason" rows="4"></textarea>

                <button type="submit" class="btn primary">Submit Vote</button>
            </form>
        </div>
    </c:if>

    <p><a href="${pageContext.request.contextPath}/main/proposals">Back to list</a></p>
</main>

<jsp:include page="../common/footer.jsp" />
</body>
</html>


