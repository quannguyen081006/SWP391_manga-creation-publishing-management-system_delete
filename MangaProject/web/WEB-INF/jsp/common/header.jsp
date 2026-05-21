<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<c:set var="uri" value="${pageContext.request.requestURI}" />
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="backUri" value="${fn:substringAfter(uri, ctx)}" />
<c:if test="${empty backUri or backUri eq '/' or fn:contains(backUri, '/main/switch-role')}">
    <c:set var="backUri" value="/main/dashboard" />
</c:if>

<c:set var="displayRole" value="User" />
<c:set var="roleKey" value="user" />
<c:set var="currentUsername" value="${empty sessionScope.AUTH_USER.username ? '' : sessionScope.AUTH_USER.username}" />
<c:choose>
    <c:when test="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('ADMIN')}">
        <c:set var="displayRole" value="Admin" />
        <c:set var="roleKey" value="admin" />
    </c:when>
    <c:when test="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('MANGAKA')}">
        <c:set var="displayRole" value="Mangaka" />
        <c:set var="roleKey" value="mangaka" />
    </c:when>
    <c:when test="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('ASSISTANT')}">
        <c:set var="displayRole" value="Assistant" />
        <c:set var="roleKey" value="assistant" />
    </c:when>
    <c:when test="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('TANTOU_EDITOR')}">
        <c:set var="displayRole" value="Tantou Editor" />
        <c:set var="roleKey" value="tantou" />
    </c:when>
    <c:when test="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}">
        <c:set var="displayRole" value="Editorial Board" />
        <c:set var="roleKey" value="board" />
    </c:when>
</c:choose>

<c:set var="displayName" value="${empty sessionScope.AUTH_USER.fullName ? 'Yuki Tanaka' : sessionScope.AUTH_USER.fullName}" />
<c:set var="isAdmin" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('ADMIN')}" />
<c:set var="isMangaka" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('MANGAKA')}" />
<c:set var="isAssistant" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('ASSISTANT')}" />
<c:set var="isTantou" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('TANTOU_EDITOR')}" />
<c:set var="isBoard" value="${sessionScope.AUTH_USER != null && sessionScope.AUTH_USER.hasRole('EDITORIAL_BOARD')}" />
<c:set var="trimmedName" value="${fn:trim(displayName)}" />
<c:set var="nameParts" value="${fn:split(trimmedName, ' ')}" />
<c:set var="firstPart" value="${nameParts[0]}" />
<c:set var="lastPart" value="${nameParts[fn:length(nameParts)-1]}" />
<c:set var="avatarText" value="${fn:toUpperCase(fn:substring(firstPart, 0, 1))}" />
<c:choose>
    <c:when test="${fn:length(nameParts) > 1}">
        <c:set var="avatarText" value="${avatarText}${fn:toUpperCase(fn:substring(lastPart, 0, 1))}" />
    </c:when>
    <c:when test="${fn:length(firstPart) >= 2}">
        <c:set var="avatarText" value="${avatarText}${fn:toUpperCase(fn:substring(firstPart, 1, 2))}" />
    </c:when>
    <c:otherwise>
        <c:set var="avatarText" value="${avatarText}X" />
    </c:otherwise>
</c:choose>

<div class="app-shell">
    <aside class="side-nav">
        <a class="side-brand" href="${ctx}/main/dashboard" title="Back to Dashboard">
            <div class="brand-icon">MF</div>
            <div>
                <div class="brand-name">MangaFlow</div>
                <div class="brand-sub">Manga Studio Ops</div>
            </div>
        </a>

        <div class="side-title">Navigation</div>
        <a class="nav-item ${fn:contains(uri, '/main/dashboard') ? 'active' : ''}" href="${ctx}/main/dashboard">Dashboard</a>
        <c:if test="${isAdmin || isMangaka || isTantou || isBoard}">
            <a class="nav-item ${fn:contains(uri, '/main/proposals') ? 'active' : ''}" href="${ctx}/main/proposals">Proposals</a>
        </c:if>
        <c:if test="${isAdmin || isMangaka || isTantou}">
            <a class="nav-item ${fn:contains(uri, '/main/series') ? 'active' : ''}" href="${ctx}/main/series">Series</a>
            <a class="nav-item ${fn:contains(uri, '/main/chapters') ? 'active' : ''}" href="${ctx}/main/chapters">Chapters</a>
        </c:if>
        <c:if test="${isAdmin || isMangaka || isAssistant || isTantou}">
            <a class="nav-item ${fn:contains(uri, '/main/tasks') ? 'active' : ''}" href="${ctx}/main/tasks">Tasks</a>
        </c:if>
        <c:if test="${isAdmin || isMangaka || isTantou}">
            <a class="nav-item ${fn:contains(uri, '/main/manuscripts') ? 'active' : ''}" href="${ctx}/main/manuscripts">Manuscripts</a>
        </c:if>
        <c:if test="${isAdmin || isBoard}">
            <a class="nav-item ${fn:contains(uri, '/main/decisions') ? 'active' : ''}" href="${ctx}/main/decisions">Decisions</a>
            <a class="nav-item ${fn:contains(uri, '/main/ranking') ? 'active' : ''}" href="${ctx}/main/ranking/periods">Ranking</a>
        </c:if>

        <c:if test="${isAdmin}">
            <a class="nav-item ${fn:contains(uri, '/main/users') ? 'active' : ''}" href="${ctx}/main/users">Users</a>
            <a class="nav-item ${fn:contains(uri, '/main/audit-logs') ? 'active' : ''}" href="${ctx}/main/audit-logs">Audit Logs</a>
        </c:if>

    </aside>

    <section class="main-shell">
        <header class="top-shell">
            <div class="page-head">
                <h1>${displayRole} Dashboard</h1>
                <span class="role-pill role-${roleKey}">${displayRole}</span>
            </div>
            <div class="top-user">
                <details class="notify-switcher">
                    <summary class="notify-toggle" title="Notifications">
    <svg class="notify-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
        <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2a2 2 0 0 1-.6 1.4L4 17h11"></path>
        <path d="M9 21a3 3 0 0 0 6 0"></path>
    </svg>
    <c:if test="${headerUnreadNotificationCount gt 0}">
        <span class="notify-count">${headerUnreadNotificationCount}</span>
    </c:if>
</summary>
                    <div class="notify-menu">
                        <div class="notify-menu-head">
                            <span>Notifications</span>
                            <a href="${ctx}/main/notifications">View all</a>
                        </div>
                        <c:choose>
                            <c:when test="${empty headerNotifications}">
                                <div class="notify-empty">No notifications yet.</div>
                            </c:when>
                            <c:otherwise>
                                <c:forEach items="${headerNotifications}" var="n">
                                    <div class="notify-item ${n.read ? 'is-read' : 'is-unread'}">
                                        <div class="notify-type">${n.type}</div>
                                        <div class="notify-message">${n.message}</div>
                                        <c:if test="${!n.read}">
                                            <form method="post" action="${ctx}/main/notifications/${n.id}/read" class="notify-read-form">
                                                <button type="submit">Mark read</button>
                                            </form>
                                        </c:if>
                                    </div>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </details>

                <div class="avatar role-${roleKey}" title="${displayName}">${avatarText}</div>
                <div>
                    <div class="user-name"><c:out value="${displayName}" default="Yuki Tanaka"/></div>
                    <!-- DEV_SWITCH_ROLE_START: remove this block when feature is no longer needed -->
                    <div class="user-actions">
                        <details class="role-switcher">
                            <summary class="user-sub switch-toggle">Switch role</summary>
                            <div class="role-switch-menu">
                                <a class="role-switch-item ${currentUsername eq 'admin' ? 'active' : ''}" href="${ctx}/main/switch-role?username=admin">Admin</a>
                                <a class="role-switch-item ${currentUsername eq 'mangaka1' ? 'active' : ''}" href="${ctx}/main/switch-role?username=mangaka1">Mangaka</a>
                                <a class="role-switch-item ${currentUsername eq 'assistant1' ? 'active' : ''}" href="${ctx}/main/switch-role?username=assistant1">Assistant</a>
                                <a class="role-switch-item ${currentUsername eq 'tantou1' ? 'active' : ''}" href="${ctx}/main/switch-role?username=tantou1">Tantou Editor</a>
                                <a class="role-switch-item ${currentUsername eq 'board1' ? 'active' : ''}" href="${ctx}/main/switch-role?username=board1">Board 1</a>
                                <a class="role-switch-item ${currentUsername eq 'board2' ? 'active' : ''}" href="${ctx}/main/switch-role?username=board2">Board 2</a>
                                <a class="role-switch-item ${currentUsername eq 'board3' ? 'active' : ''}" href="${ctx}/main/switch-role?username=board3">Board 3</a>
                                <a class="role-switch-item ${currentUsername eq 'board4' ? 'active' : ''}" href="${ctx}/main/switch-role?username=board4">Board 4</a>
                                <a class="role-switch-item ${currentUsername eq 'board5' ? 'active' : ''}" href="${ctx}/main/switch-role?username=board5">Board 5</a>
                            </div>
                        </details>
                        <a class="logout-link" href="${ctx}/main/logout">Logout</a>
                    </div>
                    <!-- DEV_SWITCH_ROLE_END -->
                </div>
            </div>
        </header>
        <main class="page-wrap">
