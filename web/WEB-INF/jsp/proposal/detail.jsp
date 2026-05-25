<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
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
        <p><strong>Approximate Chapter:</strong> ${proposal.approximateChapter}</p>
        <p><strong>Submit Attempts:</strong> ${proposal.submitAttemptCount}/2</p>
        <p><strong>Assigned Tantou Editor:</strong> <c:out value="${proposal.assignedEditorId}" default="Not assigned" /></p>
        <p><strong>Board Votes:</strong>
            <c:choose>
                <c:when test="${proposal.status == 'BOARD_REVIEW' || proposal.boardTotalVotes > 0}">
                    ${proposal.boardTotalVotes}/3 total
                    <span style="color:#6b7280;">(${proposal.boardApproveVotes} approve, ${proposal.boardReviseVotes} request revision, ${proposal.boardRejectVotes} reject)</span>
                </c:when>
                <c:otherwise>Not started</c:otherwise>
            </c:choose>
        </p>
        <p><strong>File Upload:</strong>
            <c:choose>
                <c:when test="${not empty proposal.originalFileName}">
                    <a class="btn small" href="${pageContext.request.contextPath}/main/proposals/${proposal.id}/file">${proposal.originalFileName}</a>
                </c:when>
                <c:otherwise>No file uploaded</c:otherwise>
            </c:choose>
        </p>
        <p><strong>Synopsis:</strong></p>
        <p>${proposal.synopsis}</p>
    </div>

    <c:if test="${canEdit || canSubmit}">
        <div class="action-row detail-actions">
            <c:if test="${canEdit}">
                <a class="btn" href="${pageContext.request.contextPath}/main/proposals/${proposal.id}/edit">Edit Draft</a>
            </c:if>
            <c:if test="${canSubmit}">
                <form method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/submit">
                    <button class="btn" type="submit">Submit To Tantou Review</button>
                </form>
            </c:if>
        </div>
    </c:if>

    <c:if test="${canReview}">
        <div class="panel">
            <h2>Tantou Editor Review</h2>
            <form method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/review" class="form-grid">
                <label>Decision</label>
                <select name="decision">
                    <option value="APPROVE">APPROVE</option>
                    <option value="REJECT">REJECT</option>
                    <option value="REVISE">REVISE</option>
                </select>

                <label>Reason / Revision Notes</label>
                <textarea id="reviewNote" name="note" rows="4" placeholder="Required for REJECT or REVISE"></textarea>

                <button type="submit" class="btn primary">Submit Review</button>
            </form>
        </div>
        <script>
            (function () {
                var decision = document.querySelector('select[name="decision"]');
                var note = document.getElementById('reviewNote');
                function syncNoteRequired() {
                    note.required = decision.value === 'REJECT' || decision.value === 'REVISE';
                }
                decision.addEventListener('change', syncNoteRequired);
                syncNoteRequired();
            }());
        </script>
    </c:if>

    <c:if test="${canBoardVote}">
        <div class="panel">
            <h2>Editorial Board Vote</h2>
            <form method="post" action="${pageContext.request.contextPath}/main/proposals/${proposal.id}/board-vote" class="form-grid">
                <label>Decision</label>
                <select name="decision">
                    <option value="APPROVE">APPROVE FOR PUBLICATION</option>
                    <option value="REVISE">REQUEST REVISION</option>
                    <option value="REJECT">REJECT</option>
                </select>

                <label>Reason / Revision Notes</label>
                <textarea id="boardVoteNote" name="note" rows="4" placeholder="Required when requesting revision or rejecting"></textarea>

                <button type="submit" class="btn primary">Submit Vote</button>
            </form>
        </div>
        <script>
            (function () {
                var decision = document.querySelector('form[action$="/board-vote"] select[name="decision"]');
                var note = document.getElementById('boardVoteNote');
                function syncNoteRequired() {
                    note.required = decision.value === 'REVISE' || decision.value === 'REJECT';
                }
                decision.addEventListener('change', syncNoteRequired);
                syncNoteRequired();
            }());
        </script>
    </c:if>

    <div class="panel">
        <h2>Revision History</h2>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Actor</th>
                    <th>Role</th>
                    <th>Action</th>
                    <th>Attempt</th>
                    <th>Note</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach items="${history}" var="h">
                    <tr>
                        <td><fmt:formatDate value="${h.createdAt}" pattern="yyyy-MM-dd HH:mm" /></td>
                        <td><c:out value="${empty h.actorName ? 'System' : h.actorName}" /></td>
                        <td>${h.actorRole}</td>
                        <td>${h.actionType}</td>
                        <td>${h.submitAttemptNumber}</td>
                        <td>${h.note}</td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>

    <p><a href="${pageContext.request.contextPath}/main/proposals">Back to list</a></p>
</main>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
