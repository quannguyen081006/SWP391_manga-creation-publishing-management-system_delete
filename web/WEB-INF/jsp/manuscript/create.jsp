<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Manuscript</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Create Manuscript</h2>
<p class="page-sub">Create a draft manuscript version</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>
<c:if test="${not empty success}"><div class="alert success">${success}</div></c:if>

<div class="section-card">
    <form method="post" action="${pageContext.request.contextPath}/main/manuscripts/create" class="form-grid" enctype="multipart/form-data">
        <label>Select Chapter</label>
        <select name="chapterId" required>
            <c:choose>
                <c:when test="${empty chapters}">
                    <option value="">No completed chapters available</option>
                </c:when>
                <c:otherwise>
                    <option value="">Select a completed chapter</option>
                    <c:forEach items="${chapters}" var="ch">
                        <option value="${ch.id}" ${selectedChapterId == ch.id ? 'selected' : ''}>
                            Series #${ch.seriesId} | Ch. ${ch.chapterNumber} - ${ch.title}
                        </option>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </select>

        <label>Manuscript File</label>
        <input type="file" name="manuscriptFile" accept=".pdf,.zip,.rar,.cbz" required />

        <label>Genre</label>
        <select name="genre" required>
            <option value="">Select genre</option>
            <c:forEach items="${genres}" var="g">
                <option value="${g}" ${g == genre ? 'selected' : ''}>${g}</option>
            </c:forEach>
        </select>

        <label>Notes</label>
        <textarea name="notes" rows="4" placeholder="Version notes for the Tantou Editor"></textarea>

        <button class="btn primary" type="submit">Create Draft</button>
    </form>
</div>

<a class="btn" href="${pageContext.request.contextPath}/main/manuscripts">Cancel</a>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
