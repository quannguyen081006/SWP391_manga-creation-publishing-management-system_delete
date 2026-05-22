<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vote for Mangaka - ${period.name}</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
    <style>
        .vote-card { background: #f9f9f9; padding: 24px; border-radius: 12px; margin-bottom: 16px; }
        .vote-card h4 { margin: 0 0 16px 0; color: #333; }
        .score-input-group { margin-bottom: 16px; }
        .score-input-group label { display: block; margin-bottom: 8px; font-weight: 500; }
        .score-input-group input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        .score-input-group .range-hint { font-size: 12px; color: #666; margin-top: 4px; }
        .voted-badge { background: #4CAF50; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
    </style>
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Vote for Mangaka</h2>
<p class="page-sub">Period: ${period.name} (${period.startDate} - ${period.endDate})</p>

<div class="section-card">
    <h3 class="section-title compact-title">Evaluation Criteria</h3>
    <p class="muted">Rate each mangaka on a scale of 0-10 for each criterion.</p>
    
    <div style="margin: 24px 0;">
        <div style="margin-bottom: 16px;">
            <strong>Popularity (0-10):</strong> How popular is the mangaka's work among readers?
        </div>
        <div style="margin-bottom: 16px;">
            <strong>Reliability (0-10):</strong> How consistent is the mangaka in meeting deadlines and maintaining quality?
        </div>
        <div style="margin-bottom: 16px;">
            <strong>Quality (0-10):</strong> How is the overall quality of the mangaka's work?
        </div>
    </div>
</div>

<c:if test="${not empty mangakaList}">
    <div class="section-card">
        <h3 class="section-title compact-title">Mangaka List</h3>
        <p class="muted" style="margin-bottom: 16px;">Click on a mangaka to submit your evaluation</p>
        
        <table class="data-table">
            <thead><tr><th>Mangaka</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
                <c:forEach items="${mangakaList}" var="m">
                    <tr>
                        <td>${m.username}</td>
                        <td>
                            <c:if test="${not empty votesByMangaka[m.id]}">
                                <span class="voted-badge">Voted</span>
                            </c:if>
                            <c:if test="${empty votesByMangaka[m.id]}">
                                <span style="color: #999;">Not voted</span>
                            </c:if>
                        </td>
                        <td>
                            <c:if test="${empty votesByMangaka[m.id]}">
                                <button class="btn small" onclick="showVoteForm(${m.id}, '${m.username}')">Vote</button>
                            </c:if>
                            <c:if test="${not empty votesByMangaka[m.id]}">
                                <button class="btn small" onclick="showVoteForm(${m.id}, '${m.username}')">Edit</button>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</c:if>

<!-- Vote Form Modal -->
<div id="voteModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000;">
    <div style="position: relative; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 32px; border-radius: 12px; max-width: 500px; width: 90%;">
        <h3 style="margin: 0 0 24px 0;">Evaluate: <span id="mangakaName"></span></h3>
        <form method="post" action="${pageContext.request.contextPath}/main/analytics/periods/${period.id}/vote">
            <input type="hidden" name="mangakaId" id="mangakaId" />
            
            <div class="score-input-group">
                <label>Popularity Score (0-10)</label>
                <input type="number" name="popularityScore" min="0" max="10" required />
                <div class="range-hint">0 = Low popularity, 10 = Very popular</div>
            </div>
            
            <div class="score-input-group">
                <label>Reliability Score (0-10)</label>
                <input type="number" name="reliabilityScore" min="0" max="10" required />
                <div class="range-hint">0 = Unreliable, 10 = Very reliable</div>
            </div>
            
            <div class="score-input-group">
                <label>Quality Score (0-10)</label>
                <input type="number" name="qualityScore" min="0" max="10" required />
                <div class="range-hint">0 = Low quality, 10 = Excellent quality</div>
            </div>
            
            <div class="score-input-group">
                <label>Comment (Optional)</label>
                <input type="text" name="comment" placeholder="Add any additional notes..." />
            </div>
            
            <div style="display: flex; gap: 8px; margin-top: 24px;">
                <button class="btn primary" type="submit">Submit Evaluation</button>
                <button class="btn" type="button" onclick="hideVoteForm()">Cancel</button>
            </div>
        </form>
    </div>
</div>

<script>
function showVoteForm(mangakaId, mangakaName) {
    document.getElementById('mangakaId').value = mangakaId;
    document.getElementById('mangakaName').textContent = mangakaName;
    document.getElementById('voteModal').style.display = 'block';
}

function hideVoteForm() {
    document.getElementById('voteModal').style.display = 'none';
}
</script>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
