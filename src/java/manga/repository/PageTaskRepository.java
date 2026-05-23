package manga.repository;

import manga.model.AuthenticatedUser;
import manga.model.TaskSummary;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class PageTaskRepository {

    @Autowired
    private DataSource dataSource;

    public List<TaskSummary> listVisible(AuthenticatedUser user) {
        return listVisible(user, null, null);
    }

    public List<TaskSummary> listVisible(AuthenticatedUser user, String status, Long chapterId) {
        String baseSql =
            "SELECT t.id, t.chapterId, t.assistantId, t.pageRangeStart, t.pageRangeEnd, t.taskType, t.dueDate, t.status, t.rejectionCount, "
            + "c.title AS chapterTitle, c.chapterNumber, s.title AS seriesTitle, u.fullName AS assistantName "
            + "FROM PageTask t "
            + "JOIN Chapter c ON c.id = t.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "LEFT JOIN [User] u ON u.id = t.assistantId";

        List<TaskSummary> rows = new ArrayList<TaskSummary>();
        List<String> conditions = new ArrayList<String>();
        List<Object> params = new ArrayList<Object>();
        if (!user.hasRole("ADMIN")) {
            if (user.hasRole("MANGAKA")) {
                conditions.add("s.mangakaId = ?");
                params.add(user.getId());
            }
            if (user.hasRole("TANTOU_EDITOR")) {
                conditions.add("s.tantouEditorId = ?");
                params.add(user.getId());
            }
            if (user.hasRole("ASSISTANT")) {
                conditions.add("t.assistantId = ?");
                params.add(user.getId());
            }
            if (conditions.isEmpty()) {
                return rows;
            }
        }

        StringBuilder sql = new StringBuilder(baseSql);
        if (!user.hasRole("ADMIN")) {
            sql.append(" WHERE (");
            for (int i = 0; i < conditions.size(); i++) {
                if (i > 0) {
                    sql.append(" OR ");
                }
                sql.append(conditions.get(i));
            }
            sql.append(")");
        }
        boolean hasWhere = !user.hasRole("ADMIN");
        if (status != null && !status.trim().isEmpty()) {
            sql.append(hasWhere ? " AND" : " WHERE");
            sql.append(" t.status = ?");
            params.add(status.trim().toUpperCase(Locale.ENGLISH));
            hasWhere = true;
        }
        if (chapterId != null) {
            sql.append(hasWhere ? " AND" : " WHERE");
            sql.append(" t.chapterId = ?");
            params.add(chapterId);
        }
        sql.append(" ORDER BY t.updatedAt DESC");

        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object param = params.get(i);
                if (param instanceof Long) {
                    ps.setLong(i + 1, ((Long) param).longValue());
                } else {
                    ps.setString(i + 1, String.valueOf(param));
                }
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapDetailed(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list tasks", ex);
        }
        return rows;
    }
    public List<TaskSummary> listByChapter(long chapterId) {
        String sql =
            "SELECT t.id, t.chapterId, t.assistantId, t.pageRangeStart, t.pageRangeEnd, t.taskType, t.dueDate, t.status, t.rejectionCount, "
            + "c.title AS chapterTitle, c.chapterNumber, s.title AS seriesTitle, u.fullName AS assistantName "
            + "FROM PageTask t "
            + "JOIN Chapter c ON c.id = t.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "LEFT JOIN [User] u ON u.id = t.assistantId "
            + "WHERE t.chapterId = ? "
            + "ORDER BY t.id DESC";
        List<TaskSummary> rows = new ArrayList<TaskSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapDetailed(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list tasks", ex);
        }
        return rows;
    }

    public TaskSummary findById(long taskId) {
        String sql =
            "SELECT t.id, t.chapterId, t.assistantId, t.pageRangeStart, t.pageRangeEnd, t.taskType, t.dueDate, t.status, t.rejectionCount, "
            + "c.title AS chapterTitle, c.chapterNumber, s.title AS seriesTitle, u.fullName AS assistantName "
            + "FROM PageTask t "
            + "JOIN Chapter c ON c.id = t.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "LEFT JOIN [User] u ON u.id = t.assistantId "
            + "WHERE t.id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return mapDetailed(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task", ex);
        }
    }

    public long create(long chapterId, long assistantId, int start, int end, String taskType, Date dueDate) {
        String overlapSql = "SELECT COUNT(1) FROM PageTask WHERE chapterId = ? AND NOT (pageRangeEnd < ? OR pageRangeStart > ?)";
        String chapterSql = "SELECT c.submissionDeadline, c.seriesId, s.mangakaId FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?";
        String enrollmentSql = "SELECT COUNT(1) FROM MangakaAssistant WHERE mangakaId = ? AND assistantId = ?";
        String insertSql = "INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount, assignedAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, 'IN_PROGRESS', 0, GETDATE(), GETDATE())";

        try (Connection conn = dataSource.getConnection()) {
            taskType = normalizeTaskType(taskType);
            validateTaskAssignment(conn, 0L, chapterId, assistantId, start, end, taskType, dueDate, overlapSql, chapterSql, enrollmentSql);

            long newId;
            try (PreparedStatement insert = conn.prepareStatement(insertSql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                insert.setLong(1, chapterId);
                insert.setLong(2, assistantId);
                insert.setInt(3, start);
                insert.setInt(4, end);
                insert.setString(5, taskType);
                insert.setDate(6, dueDate);
                insert.executeUpdate();
                try (ResultSet rs = insert.getGeneratedKeys()) {
                    if (!rs.next()) {
                        throw new IllegalStateException("Cannot create task");
                    }
                    newId = rs.getLong(1);
                }
            }

            refreshChapterProgress(chapterId);
            createNotification(
                    assistantId,
                    "TASK_ASSIGNED",
                    "You have been assigned task #" + newId + ".",
                    newId,
                    "TASK");
            return newId;
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create task", ex);
        }
    }

    public void updateTaskByMangaka(long taskId, long mangakaId, long assistantId, int start, int end, String taskType, Date dueDate) {
        String taskInfoSql = "SELECT t.chapterId, t.assistantId, t.status FROM PageTask t WHERE t.id = ?";
        String updateSql = "UPDATE PageTask SET assistantId = ?, pageRangeStart = ?, pageRangeEnd = ?, taskType = ?, dueDate = ?, status = 'IN_PROGRESS', rejectionCount = 0, updatedAt = GETDATE(), assignedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection()) {
            taskType = normalizeTaskType(taskType);
            long chapterId;
            long currentAssistantId;
            String currentStatus;
            try (PreparedStatement ps = conn.prepareStatement(taskInfoSql)) {
                ps.setLong(1, taskId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Task not found");
                    }
                    chapterId = rs.getLong("chapterId");
                    currentAssistantId = rs.getLong("assistantId");
                    currentStatus = rs.getString("status");
                }
            }

            long ownerId = findChapterOwnerMangaka(chapterId);
            if (ownerId != mangakaId) {
                throw new IllegalArgumentException("Only chapter owner can update task");
            }

            if ("APPROVED".equalsIgnoreCase(currentStatus)) {
                throw new IllegalArgumentException("Approved task cannot be edited. Create a new task instead (BR-TSK-06)");
            }

            validateTaskAssignment(
                    conn,
                    taskId,
                    chapterId,
                    assistantId,
                    start,
                    end,
                    taskType,
                    dueDate,
                    "SELECT COUNT(1) FROM PageTask WHERE chapterId = ? AND id <> ? AND NOT (pageRangeEnd < ? OR pageRangeStart > ?)",
                    "SELECT c.submissionDeadline, c.seriesId, s.mangakaId FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?",
                    "SELECT COUNT(1) FROM MangakaAssistant WHERE mangakaId = ? AND assistantId = ?");

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setLong(1, assistantId);
                ps.setInt(2, start);
                ps.setInt(3, end);
                ps.setString(4, taskType);
                ps.setDate(5, dueDate);
                ps.setLong(6, taskId);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Task not found");
                }
            }

            refreshChapterProgress(chapterId);
            boolean reassigned = currentAssistantId != assistantId;
            createNotification(
                    assistantId,
                    reassigned ? "TASK_REASSIGNED" : "TASK_UPDATED",
                    reassigned
                            ? "Task #" + taskId + " has been assigned to you."
                            : "Task #" + taskId + " has been updated.",
                    taskId,
                    "TASK");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update task", ex);
        }
    }

    private String normalizeTaskType(String taskType) {
        if (taskType == null || taskType.trim().isEmpty()) {
            throw new IllegalArgumentException("taskType is required");
        }
        String normalized = taskType.trim().toUpperCase(Locale.ENGLISH);
        if (!"SKETCHING".equals(normalized)
                && !"INKING".equals(normalized)
                && !"COLORING".equals(normalized)
                && !"LETTERING".equals(normalized)) {
            throw new IllegalArgumentException("taskType must be SKETCHING, INKING, COLORING, or LETTERING");
        }
        return normalized;
    }
    private void validateTaskAssignment(
            Connection conn,
            long taskId,
            long chapterId,
            long assistantId,
            int start,
            int end,
            String taskType,
            Date dueDate,
            String overlapSql,
            String chapterSql,
            String enrollmentSql) throws SQLException {

        if (assistantId <= 0) {
            throw new IllegalArgumentException("assistantId is required");
        }
        if (taskType == null || taskType.trim().isEmpty()) {
            throw new IllegalArgumentException("taskType is required");
        }
        if (dueDate == null) {
            throw new IllegalArgumentException("dueDate is required");
        }
        if (dueDate.before(Date.valueOf(LocalDate.now()))) {
            throw new IllegalArgumentException("Task dueDate cannot be in the past");
        }
        if (end < start) {
            throw new IllegalArgumentException("pageRangeEnd must be >= pageRangeStart");
        }

        if (taskId == 0L) {
            try (PreparedStatement overlap = conn.prepareStatement(overlapSql)) {
                overlap.setLong(1, chapterId);
                overlap.setInt(2, start);
                overlap.setInt(3, end);
                try (ResultSet rs = overlap.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Page range overlaps existing task (BR-33)");
                    }
                }
            }
        } else {
            try (PreparedStatement overlap = conn.prepareStatement(overlapSql)) {
                overlap.setLong(1, chapterId);
                overlap.setLong(2, taskId);
                overlap.setInt(3, start);
                overlap.setInt(4, end);
                try (ResultSet rs = overlap.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Page range overlaps existing task (BR-33)");
                    }
                }
            }
        }

        long mangakaId;
        Date submissionDeadline;
        try (PreparedStatement chapter = conn.prepareStatement(chapterSql)) {
            chapter.setLong(1, chapterId);
            try (ResultSet rs = chapter.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                submissionDeadline = rs.getDate("submissionDeadline");
                mangakaId = rs.getLong("mangakaId");
            }
        }

        if (assistantId == mangakaId) {
            throw new IllegalArgumentException("Mangaka cannot self-assign page task (BR-35)");
        }

        Date deadline3DaysBefore = new Date(submissionDeadline.getTime() - (3L * 24L * 60L * 60L * 1000L));
        if (dueDate.after(deadline3DaysBefore)) {
            throw new IllegalArgumentException("Task dueDate must be at least 3 days before chapter submissionDeadline (BR-34)");
        }

        try (PreparedStatement enrollment = conn.prepareStatement(enrollmentSql)) {
            enrollment.setLong(1, mangakaId);
            enrollment.setLong(2, assistantId);
            try (ResultSet rs = enrollment.executeQuery()) {
                rs.next();
                if (rs.getInt(1) == 0) {
                    throw new IllegalArgumentException("Assistant must be assigned to mangaka (BR-36)");
                }
            }
        }
    }

    public void updateStatusByAssistant(long taskId, long assistantId, String status) {
        String normalized = status == null ? "" : status.trim().toUpperCase();
        if (!"SUBMITTED".equals(normalized)) {
            throw new IllegalArgumentException("Assistant can only submit task for review");
        }

        String readSql = "SELECT chapterId, assistantId, status FROM PageTask WHERE id = ?";
        String updateSql = "UPDATE PageTask SET status = ?, updatedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement read = conn.prepareStatement(readSql)) {
            read.setLong(1, taskId);
            long chapterId;
            long ownerAssistantId;
            String currentStatus;
            try (ResultSet rs = read.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                chapterId = rs.getLong("chapterId");
                ownerAssistantId = rs.getLong("assistantId");
                currentStatus = rs.getString("status");
            }

            if (ownerAssistantId != assistantId) {
                throw new IllegalArgumentException("Task not assigned to this assistant (BR-42)");
            }

            if (!("IN_PROGRESS".equalsIgnoreCase(currentStatus)
                    || "REJECTED".equalsIgnoreCase(currentStatus)
                    || "OVERDUE".equalsIgnoreCase(currentStatus))) {
                throw new IllegalArgumentException("Assistant can submit only from active/rework task state (BR-TSK-01)");
            }

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, normalized);
                ps.setLong(2, taskId);
                ps.executeUpdate();
            }

            refreshChapterProgress(chapterId);
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update task status", ex);
        }
    }

    public void approveByMangaka(long taskId, long mangakaId) {
        String readSql = "SELECT chapterId, status FROM PageTask WHERE id = ?";
        String updateSql = "UPDATE PageTask SET status = 'APPROVED', updatedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement read = conn.prepareStatement(readSql)) {
            read.setLong(1, taskId);
            long chapterId;
            String currentStatus;
            try (ResultSet rs = read.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                chapterId = rs.getLong("chapterId");
                currentStatus = rs.getString("status");
            }

            long ownerId = findChapterOwnerMangaka(chapterId);
            if (ownerId != mangakaId) {
                throw new IllegalArgumentException("Only chapter owner Mangaka can approve (BR-39)");
            }

            if (!"SUBMITTED".equalsIgnoreCase(currentStatus)) {
                throw new IllegalArgumentException("Only SUBMITTED task can be approved (BR-39)");
            }

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setLong(1, taskId);
                ps.executeUpdate();
            }

            refreshChapterProgress(chapterId);
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot approve task", ex);
        }
    }

    public int rejectByMangaka(long taskId, long mangakaId) {
        String readSql = "SELECT chapterId, status, rejectionCount FROM PageTask WHERE id = ?";
        String updateSql = "UPDATE PageTask SET status = 'REJECTED', rejectionCount = ?, updatedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement read = conn.prepareStatement(readSql)) {
            read.setLong(1, taskId);
            long chapterId;
            String currentStatus;
            int currentReject;
            try (ResultSet rs = read.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                chapterId = rs.getLong("chapterId");
                currentStatus = rs.getString("status");
                currentReject = rs.getInt("rejectionCount");
            }

            long ownerId = findChapterOwnerMangaka(chapterId);
            if (ownerId != mangakaId) {
                throw new IllegalArgumentException("Only chapter owner Mangaka can reject (BR-38)");
            }

            if (!"SUBMITTED".equalsIgnoreCase(currentStatus)) {
                throw new IllegalArgumentException("Only SUBMITTED task can be rejected (BR-38)");
            }
            if (currentReject >= 3) {
                throw new IllegalArgumentException("Task already reached reject limit (max 3)");
            }

            int next = currentReject + 1;
            try (PreparedStatement update = conn.prepareStatement(updateSql)) {
                update.setInt(1, next);
                update.setLong(2, taskId);
                update.executeUpdate();
            }

            refreshChapterProgress(chapterId);

            if (next == 3) {
                long tantouId = findChapterTantouEditor(chapterId);
                createNotification(
                        tantouId,
                        "TASK_ESCALATED",
                        "Task #" + taskId + " reached 3 rejections and requires intervention.",
                        taskId,
                        "TASK");
            }

            return next;
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot reject task", ex);
        }
    }

    public long findChapterOwnerMangaka(long chapterId) {
        String sql = "SELECT s.mangakaId FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load chapter owner", ex);
        }
    }

    public long findChapterTantouEditor(long chapterId) {
        String sql = "SELECT s.tantouEditorId FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load chapter tantou", ex);
        }
    }

    public long findTaskAssistantId(long taskId) {
        String sql = "SELECT assistantId FROM PageTask WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                return rs.getLong("assistantId");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task assistant", ex);
        }
    }

    public long findTaskChapterId(long taskId) {
        String sql = "SELECT chapterId FROM PageTask WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                return rs.getLong("chapterId");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task chapter", ex);
        }
    }

    public long getTaskOwnerMangaka(long taskId) {
        return findChapterOwnerMangaka(findTaskChapterId(taskId));
    }

    public long getTaskTantouEditor(long taskId) {
        return findChapterTantouEditor(findTaskChapterId(taskId));
    }

    public int markOverdueTasks() {
        String selectSql =
            "SELECT t.id, t.chapterId, s.mangakaId "
            + "FROM PageTask t "
            + "JOIN Chapter c ON c.id = t.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "WHERE t.dueDate < CAST(GETDATE() AS DATE) AND t.status NOT IN ('APPROVED','OVERDUE')";
        String updateSql = "UPDATE PageTask SET status = 'OVERDUE', updatedAt = GETDATE() WHERE id = ?";

        int changed = 0;
        Set<Long> chapters = new HashSet<Long>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement select = conn.prepareStatement(selectSql);
             ResultSet rs = select.executeQuery()) {

            List<long[]> rows = new ArrayList<long[]>();
            while (rs.next()) {
                rows.add(new long[] { rs.getLong("id"), rs.getLong("chapterId"), rs.getLong("mangakaId") });
            }

            for (long[] row : rows) {
                try (PreparedStatement update = conn.prepareStatement(updateSql)) {
                    update.setLong(1, row[0]);
                    if (update.executeUpdate() > 0) {
                        changed++;
                        chapters.add(row[1]);
                        createNotificationIfAbsentToday(
                                row[2],
                                "TASK_OVERDUE",
                                "Task #" + row[0] + " is overdue. Please update immediately.",
                                row[0],
                                "TASK");
                    }
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot mark overdue tasks", ex);
        }

        for (Long chapterId : chapters) {
            refreshChapterProgress(chapterId.longValue());
        }
        return changed;
    }

    public int notifyDueSoonTasks() {
        String sql =
            "SELECT id, assistantId FROM PageTask "
            + "WHERE dueDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) "
            + "AND status IN ('PENDING','IN_PROGRESS','REJECTED','SUBMITTED')";
        int sent = 0;
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                long taskId = rs.getLong("id");
                long assistantId = rs.getLong("assistantId");
                if (createNotificationIfAbsentToday(
                        assistantId,
                        "TASK_DUE_SOON",
                        "Task #" + taskId + " is due within 24 hours.",
                        taskId,
                        "TASK")) {
                    sent++;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot send due-soon reminders", ex);
        }
        return sent;
    }

    public int notifyStaleTasks() {
        String sql =
            "SELECT t.id, c.id AS chapterId, s.mangakaId "
            + "FROM PageTask t "
            + "JOIN Chapter c ON c.id = t.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "WHERE t.status IN ('PENDING','IN_PROGRESS','REJECTED') "
            + "AND DATEDIFF(DAY, t.assignedAt, GETDATE()) >= 3 "
            + "AND DATEDIFF(DAY, t.updatedAt, GETDATE()) >= 3";

        int sent = 0;
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                long taskId = rs.getLong("id");
                long mangakaId = rs.getLong("mangakaId");
                if (createNotificationIfAbsentToday(
                        mangakaId,
                        "TASK_DELAYED",
                        "Task #" + taskId + " has not been updated for 3 days.",
                        taskId,
                        "TASK")) {
                    sent++;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot detect stale tasks", ex);
        }
        return sent;
    }

    public void refreshChapterProgress(long chapterId) {
        String readRiskSql = "SELECT atRisk FROM Chapter WHERE id = ?";
        String updateSql =
            "UPDATE c SET "
            + "completionPct = stats.completionPct, "
            + "status = CASE "
            + "  WHEN stats.totalTasks = 0 AND c.status IN ('PLANNING','IN_PROGRESS','COMPLETE') THEN 'PLANNING' "
            + "  WHEN stats.totalTasks > 0 AND stats.completionPct >= 100 AND c.status IN ('PLANNING','IN_PROGRESS','COMPLETE') THEN 'COMPLETE' "
            + "  WHEN stats.totalTasks > 0 AND stats.completionPct < 100 AND c.status IN ('PLANNING','IN_PROGRESS','COMPLETE') THEN 'IN_PROGRESS' "
            + "  ELSE c.status END, "
            + "atRisk = CASE "
            + "  WHEN c.submissionDeadline < CAST(GETDATE() AS DATE) AND stats.completionPct < 100 THEN 1 "
            + "  WHEN DATEDIFF(DAY, CAST(c.createdAt AS DATE), c.publicationDate) > 0 "
            + "       AND stats.completionPct < 50 "
            + "       AND (100.0 * DATEDIFF(DAY, CAST(c.createdAt AS DATE), CAST(GETDATE() AS DATE)) / DATEDIFF(DAY, CAST(c.createdAt AS DATE), c.publicationDate)) > 70 "
            + "  THEN 1 ELSE 0 END "
            + "FROM Chapter c "
            + "CROSS APPLY ( "
            + "  SELECT "
            + "    COUNT(1) AS totalTasks, "
            + "    CAST(ROUND(CASE WHEN COUNT(1)=0 THEN 0 ELSE (100.0 * SUM(CASE WHEN status='APPROVED' THEN 1 ELSE 0 END) / COUNT(1)) END, 2) AS DECIMAL(5,2)) AS completionPct "
            + "  FROM PageTask t WHERE t.chapterId = c.id "
            + ") stats "
            + "WHERE c.id = ?";

        try (Connection conn = dataSource.getConnection()) {
            boolean wasAtRisk = false;
            try (PreparedStatement read = conn.prepareStatement(readRiskSql)) {
                read.setLong(1, chapterId);
                try (ResultSet rs = read.executeQuery()) {
                    if (rs.next()) {
                        wasAtRisk = rs.getBoolean("atRisk");
                    }
                }
            }

            try (PreparedStatement update = conn.prepareStatement(updateSql)) {
                update.setLong(1, chapterId);
                update.executeUpdate();
            }

            boolean nowAtRisk = false;
            try (PreparedStatement read = conn.prepareStatement(readRiskSql)) {
                read.setLong(1, chapterId);
                try (ResultSet rs = read.executeQuery()) {
                    if (rs.next()) {
                        nowAtRisk = rs.getBoolean("atRisk");
                    }
                }
            }

            if (!wasAtRisk && nowAtRisk) {
                long tantouId = findChapterTantouEditor(chapterId);
                createNotificationIfAbsentToday(
                        tantouId,
                        "CHAPTER_AT_RISK",
                        "Chapter #" + chapterId + " is at risk (progress below expected timeline).",
                        chapterId,
                        "CHAPTER");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot refresh chapter progress", ex);
        }
    }

    public void createNotification(long userId, String type, String message, long referenceId, String referenceType) {
        String sql = "INSERT INTO Notification (userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, 0, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, type);
            ps.setString(3, notificationTitle(type));
            ps.setString(4, message);
            ps.setString(5, notificationViewUrl(type, referenceId, referenceType));
            ps.setLong(6, referenceId);
            ps.setString(7, referenceType);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create notification", ex);
        }
    }

    public boolean areAllTasksApproved(long chapterId) {
        String sql = "SELECT CASE WHEN COUNT(1) = 0 THEN 0 ELSE SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) END AS approvedCount, COUNT(1) AS totalCount FROM PageTask WHERE chapterId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int approvedCount = rs.getInt("approvedCount");
                    int totalCount = rs.getInt("totalCount");
                    return totalCount > 0 && approvedCount == totalCount;
                }
                return false;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check chapter task approval status", ex);
        }
    }

    public boolean createNotificationIfAbsentToday(long userId, String type, String message, long referenceId, String referenceType) {
        String checkSql =
            "SELECT COUNT(1) FROM Notification "
            + "WHERE userId = ? AND type = ? AND referenceId = ? "
            + "AND CAST(createdAt AS DATE) = CAST(GETDATE() AS DATE)";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement check = conn.prepareStatement(checkSql)) {
            check.setLong(1, userId);
            check.setString(2, type);
            check.setLong(3, referenceId);
            try (ResultSet rs = check.executeQuery()) {
                rs.next();
                if (rs.getInt(1) > 0) {
                    return false;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check notification duplication", ex);
        }

        createNotification(userId, type, message, referenceId, referenceType);
        return true;
    }

    private String notificationTitle(String type) {
        if (type == null) {
            return "Notification";
        }
        String normalized = type.trim().toUpperCase(Locale.ENGLISH);
        if ("TASK_ASSIGNED".equals(normalized)) {
            return "New page task assigned";
        }
        if ("TASK_DUE_SOON".equals(normalized)) {
            return "Task due in 24 hours";
        }
        if ("TASK_DELAYED".equals(normalized)) {
            return "Task delayed";
        }
        if ("TASK_OVERDUE".equals(normalized)) {
            return "Task overdue";
        }
        if ("TASK_ESCALATED".equals(normalized)) {
            return "Task escalated";
        }
        if ("CHAPTER_AT_RISK".equals(normalized)) {
            return "Chapter at risk";
        }
        if (normalized.startsWith("MANUSCRIPT")) {
            return "Manuscript update";
        }
        if (normalized.startsWith("CHAPTER")) {
            return "Chapter update";
        }
        return "Notification";
    }

    private String notificationViewUrl(String type, long referenceId, String referenceType) {
        if (referenceId <= 0 || referenceType == null) {
            return null;
        }
        String normalizedType = type == null ? "" : type.trim().toUpperCase(Locale.ENGLISH);
        String normalizedRef = referenceType.trim().toUpperCase(Locale.ENGLISH);
        if ("TASK".equals(normalizedRef) || "PAGETASK".equals(normalizedRef)) {
            if ("TASK_ESCALATED".equals(normalizedType)) {
                return "/main/tasks/" + referenceId + "?tab=history";
            }
            return "/main/tasks/" + referenceId;
        }
        if ("CHAPTER".equals(normalizedRef)) {
            return "/main/chapters/" + referenceId;
        }
        if ("MANUSCRIPT".equals(normalizedRef)) {
            if ("MANUSCRIPT_REVIEW_REMINDER".equals(normalizedType)) {
                return "/main/manuscripts/" + referenceId + "/review";
            }
            if ("MANUSCRIPT_REJECTED".equals(normalizedType)) {
                return "/main/manuscripts/" + referenceId + "?tab=feedback";
            }
            return "/main/manuscripts/" + referenceId;
        }
        if ("DECISION".equals(normalizedRef) || "DECISION_SESSION".equals(normalizedRef)) {
            return "/main/decisions/" + referenceId;
        }
        if ("PROPOSAL".equals(normalizedRef)) {
            return "/main/proposals/" + referenceId;
        }
        if ("SERIES".equals(normalizedRef)) {
            return "/main/series/" + referenceId;
        }
        return null;
    }

    private TaskSummary mapDetailed(ResultSet rs) throws SQLException {
        TaskSummary t = map(rs);
        t.setChapterTitle(rs.getString("chapterTitle"));
        t.setChapterNumber(rs.getInt("chapterNumber"));
        t.setSeriesTitle(rs.getString("seriesTitle"));
        t.setAssistantName(rs.getString("assistantName"));
        return t;
    }
    private TaskSummary map(ResultSet rs) throws SQLException {
        TaskSummary t = new TaskSummary();
        t.setId(rs.getLong("id"));
        t.setChapterId(rs.getLong("chapterId"));
        t.setAssistantId(rs.getLong("assistantId"));
        t.setPageRangeStart(rs.getInt("pageRangeStart"));
        t.setPageRangeEnd(rs.getInt("pageRangeEnd"));
        t.setTaskType(rs.getString("taskType"));
        t.setDueDate(rs.getDate("dueDate"));
        t.setStatus(rs.getString("status"));
        t.setRejectionCount(rs.getInt("rejectionCount"));
        return t;
    }
}
