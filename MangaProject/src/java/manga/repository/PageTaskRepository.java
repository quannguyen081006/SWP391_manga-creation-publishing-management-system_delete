package manga.repository;

import manga.model.TaskSummary;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class PageTaskRepository {

    @Autowired
    private DataSource dataSource;

    public List<TaskSummary> listByChapter(long chapterId) {
        String sql = "SELECT id, chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount FROM PageTask WHERE chapterId = ? ORDER BY id DESC";
        List<TaskSummary> rows = new ArrayList<TaskSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TaskSummary t = map(rs);
                    rows.add(t);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list tasks", ex);
        }
        return rows;
    }

    public TaskSummary findById(long taskId) {
        String sql = "SELECT id, chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount FROM PageTask WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return map(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task", ex);
        }
    }

    public long create(long chapterId, long assistantId, int start, int end, String taskType, Date dueDate) {
        String overlapSql = "SELECT COUNT(1) FROM PageTask WHERE chapterId = ? AND NOT (pageRangeEnd < ? OR pageRangeStart > ?)";
        String chapterSql = "SELECT c.submissionDeadline, c.seriesId FROM Chapter c WHERE c.id = ?";
        String enrollmentSql = "SELECT COUNT(1) FROM SeriesAssistant WHERE seriesId = ? AND assistantId = ?";
        String insertSql = "INSERT INTO PageTask (chapterId, assistantId, pageRangeStart, pageRangeEnd, taskType, dueDate, status, rejectionCount, assignedAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, 'PENDING', 0, GETDATE(), GETDATE())";

        try (Connection conn = dataSource.getConnection()) {
            validateTaskAssignment(conn, 0L, chapterId, assistantId, start, end, dueDate, overlapSql, chapterSql, enrollmentSql);

            try (PreparedStatement insert = conn.prepareStatement(insertSql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                insert.setLong(1, chapterId);
                insert.setLong(2, assistantId);
                insert.setInt(3, start);
                insert.setInt(4, end);
                insert.setString(5, taskType);
                insert.setDate(6, dueDate);
                insert.executeUpdate();
                try (ResultSet rs = insert.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getLong(1);
                    }
                }
            }
            throw new IllegalStateException("Cannot create task");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create task", ex);
        }
    }

    public void updateTaskByMangaka(long taskId, long mangakaId, long assistantId, int start, int end, String taskType, Date dueDate) {
        long ownerId = getTaskOwnerMangaka(taskId);
        if (ownerId != mangakaId) {
            throw new IllegalArgumentException("Only task owner can update task");
        }

        String taskInfoSql = "SELECT t.chapterId FROM PageTask t WHERE t.id = ?";
        String updateSql = "UPDATE PageTask SET assistantId = ?, pageRangeStart = ?, pageRangeEnd = ?, taskType = ?, dueDate = ?, status = 'PENDING', rejectionCount = 0, updatedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection()) {
            long chapterId;
            try (PreparedStatement ps = conn.prepareStatement(taskInfoSql)) {
                ps.setLong(1, taskId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Task not found");
                    }
                    chapterId = rs.getLong("chapterId");
                }
            }

            validateTaskAssignment(conn, taskId, chapterId, assistantId, start, end, dueDate,
                    "SELECT COUNT(1) FROM PageTask WHERE chapterId = ? AND id <> ? AND NOT (pageRangeEnd < ? OR pageRangeStart > ?)",
                    "SELECT c.submissionDeadline, c.seriesId FROM Chapter c WHERE c.id = ?",
                    "SELECT COUNT(1) FROM SeriesAssistant WHERE seriesId = ? AND assistantId = ?");

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setLong(1, assistantId);
                ps.setInt(2, start);
                ps.setInt(3, end);
                ps.setString(4, taskType);
                ps.setDate(5, dueDate);
                ps.setLong(6, taskId);
                ps.executeUpdate();
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update task", ex);
        }
    }

    private void validateTaskAssignment(
            Connection conn,
            long taskId,
            long chapterId,
            long assistantId,
            int start,
            int end,
            Date dueDate,
            String overlapSql,
            String chapterSql,
            String enrollmentSql) throws SQLException {

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

        long seriesId;
        Date submissionDeadline;
        try (PreparedStatement chapter = conn.prepareStatement(chapterSql)) {
            chapter.setLong(1, chapterId);
            try (ResultSet rs = chapter.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                submissionDeadline = rs.getDate("submissionDeadline");
                seriesId = rs.getLong("seriesId");
            }
        }

        if (dueDate.after(submissionDeadline)) {
            throw new IllegalArgumentException("Task dueDate must be <= chapter submissionDeadline (BR-34)");
        }

        try (PreparedStatement enrollment = conn.prepareStatement(enrollmentSql)) {
            enrollment.setLong(1, seriesId);
            enrollment.setLong(2, assistantId);
            try (ResultSet rs = enrollment.executeQuery()) {
                rs.next();
                if (rs.getInt(1) == 0) {
                    throw new IllegalArgumentException("Assistant must be enrolled in series (BR-35)");
                }
            }
        }
    }

    public void updateStatusByAssistant(long taskId, long assistantId, String status) {
        if (!"IN_PROGRESS".equals(status) && !"SUBMITTED".equals(status)) {
            throw new IllegalArgumentException("Assistant can update status only to IN_PROGRESS or SUBMITTED");
        }
        String sql = "UPDATE PageTask SET status = ?, updatedAt = GETDATE() WHERE id = ? AND assistantId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setLong(2, taskId);
            ps.setLong(3, assistantId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Task not found or not assigned to assistant");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update task status", ex);
        }
    }

    public void approveByMangaka(long taskId) {
        String sql = "UPDATE PageTask SET status = 'APPROVED', updatedAt = GETDATE() WHERE id = ? AND status = 'SUBMITTED'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only SUBMITTED task can be approved (BR-39)");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot approve task", ex);
        }
    }

    public int rejectByMangaka(long taskId) {
        String read = "SELECT rejectionCount FROM PageTask WHERE id = ?";
        String update = "UPDATE PageTask SET status = 'REJECTED', rejectionCount = ?, updatedAt = GETDATE() WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement psRead = conn.prepareStatement(read)) {
            psRead.setLong(1, taskId);
            int current;
            try (ResultSet rs = psRead.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                current = rs.getInt("rejectionCount");
            }
            int next = current + 1;
            try (PreparedStatement psUpdate = conn.prepareStatement(update)) {
                psUpdate.setInt(1, next);
                psUpdate.setLong(2, taskId);
                psUpdate.executeUpdate();
            }
            return next;
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot reject task", ex);
        }
    }

    public long getTaskOwnerMangaka(long taskId) {
        String sql = "SELECT s.mangakaId FROM PageTask t JOIN Chapter c ON c.id=t.chapterId JOIN Series s ON s.id=c.seriesId WHERE t.id=?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task owner", ex);
        }
    }

    public long getTaskTantouEditor(long taskId) {
        String sql = "SELECT s.tantouEditorId FROM PageTask t JOIN Chapter c ON c.id=t.chapterId JOIN Series s ON s.id=c.seriesId WHERE t.id=?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Task not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load task tantou", ex);
        }
    }

    public void createNotification(long userId, String type, String message, long referenceId, String referenceType) {
        String sql = "INSERT INTO Notification (userId, type, message, referenceId, referenceType, isRead, createdAt) VALUES (?, ?, ?, ?, ?, 0, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, type);
            ps.setString(3, message);
            ps.setLong(4, referenceId);
            ps.setString(5, referenceType);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create notification", ex);
        }
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

    public int markOverdueTasks() {
        String sql =
            "UPDATE PageTask SET status = 'OVERDUE', updatedAt = GETDATE() "
            + "WHERE status IN ('PENDING','IN_PROGRESS','SUBMITTED') "
            + "AND dueDate < CAST(GETDATE() AS DATE)";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            return ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot mark overdue tasks", ex);
        }
    }
}

