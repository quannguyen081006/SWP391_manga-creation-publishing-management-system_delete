<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Management</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/styles.css" />
</head>
<body>
<jsp:include page="../common/header.jsp" />

<h2 class="page-title">Users</h2>
<p class="page-sub">Admin user and role management</p>

<c:if test="${not empty error}"><div class="alert error">${error}</div></c:if>

<div class="section-head">
    <div></div>
    <a class="btn primary" href="${pageContext.request.contextPath}/main/users/new">+ New User</a>
</div>

<div class="section-card">
    <table class="data-table">
        <thead><tr><th>ID</th><th>Username</th><th>Name</th><th>Email</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
            <c:forEach items="${users}" var="u">
                <tr>
                    <td>${u.id}</td>
                    <td>${u.username}</td>
                    <td>${u.fullName}</td>
                    <td>${u.email}</td>
                    <td>${u.status}</td>
                    <td>
                        <a class="btn small" href="${pageContext.request.contextPath}/main/users/${u.id}/edit">Edit</a>
                        <form method="post" action="${pageContext.request.contextPath}/main/users/${u.id}/status" style="display:inline-block;">
                            <input type="hidden" name="status" value="${u.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE'}" />
                            <button class="btn small" type="submit">Toggle Status</button>
                        </form>
                        <form method="post" action="${pageContext.request.contextPath}/main/users/${u.id}/roles" style="display:inline-flex; gap:6px; align-items:center;">
                            <select name="role">
                                <option value="ADMIN">ADMIN</option>
                                <option value="MANGAKA">MANGAKA</option>
                                <option value="ASSISTANT">ASSISTANT</option>
                                <option value="TANTOU_EDITOR">TANTOU_EDITOR</option>
                                <option value="EDITORIAL_BOARD">EDITORIAL_BOARD</option>
                            </select>
                            <button class="btn small" type="submit">Add Role</button>
                        </form>
                    </td>
                </tr>
            </c:forEach>
        </tbody>
    </table>
</div>

<jsp:include page="../common/footer.jsp" />
</body>
</html>
