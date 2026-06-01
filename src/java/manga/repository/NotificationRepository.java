package manga.repository;

import manga.model.NotificationItem;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class NotificationRepository {

    @Autowired
    private DataSource dataSource;

    public void create(long userId, String type, String message, long referenceId, String referenceType) {
        create(userId, type, defaultTitle(type), message, defaultViewUrl(type, referenceId, referenceType), referenceId, referenceType);
    }

    public void create(long userId, String type, String title, String message, String viewUrl, long referenceId, String referenceType) {
        String sql = "INSERT INTO Notification (userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, 0, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, type);
            ps.setString(3, title);
            ps.setString(4, message);
            ps.setString(5, viewUrl);
            if (referenceId <= 0) {
                ps.setNull(6, java.sql.Types.BIGINT);
            } else {
                ps.setLong(6, referenceId);
            }
            ps.setString(7, referenceType);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create notification", ex);
        }
    }

    public List<NotificationItem> listByUser(long userId) {
        return listByUser(userId, 100);
    }

    public List<NotificationItem> listByUser(long userId, int limit) {
        String sql = "SELECT TOP (?) id, userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt FROM Notification WHERE userId = ? ORDER BY createdAt DESC";
        List<NotificationItem> rows = new ArrayList<NotificationItem>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load notifications", ex);
        }
        return rows;
    }

    public int unreadCount(long userId) {
        String sql = "SELECT COUNT(*) FROM Notification WHERE userId = ? AND isRead = 0";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot count unread notifications", ex);
        }
    }

    public void markRead(long userId, long id) {
        String sql = "UPDATE Notification SET isRead = 1 WHERE id = ? AND userId = ?";
        update(sql, id, userId);
    }

    public void markAllRead(long userId) {
        String sql = "UPDATE Notification SET isRead = 1 WHERE userId = ? AND isRead = 0";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot mark all notifications", ex);
        }
    }

    private void update(String sql, long id, long userId) {
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, userId);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update notification", ex);
        }
    }

    private NotificationItem map(ResultSet rs) throws SQLException {
        NotificationItem n = new NotificationItem();
        n.setId(rs.getLong("id"));
        n.setUserId(rs.getLong("userId"));
        n.setType(rs.getString("type"));
        n.setTitle(defaultTitle(n.getType()));
        n.setMessage(rs.getString("message"));
        n.setViewUrl(rs.getString("viewUrl"));
        long referenceId = rs.getLong("referenceId");
        n.setReferenceId(rs.wasNull() ? null : referenceId);
        n.setReferenceType(rs.getString("referenceType"));
        n.setRead(rs.getBoolean("isRead"));
        n.setCreatedAt(rs.getTimestamp("createdAt"));
        return n;
    }

    private String defaultTitle(String type) {
        if (isBlank(type)) {
            return "Notification";
        }
        String normalized = type.trim().toUpperCase();
        if ("TASK_ASSIGNED".equals(normalized)) {
            return "Bạn có task mới";
        }
        if ("TASK_UPDATED".equals(normalized)) {
            return "Task đã được cập nhật";
        }
        if ("TASK_REASSIGNED".equals(normalized)) {
            return "Task đã được chuyển giao";
        }
        if ("TASK_DELETED".equals(normalized)) {
            return "Task đã bị xóa";
        }
        if ("TASK_SUBMITTED".equals(normalized)) {
            return "Assistant đã nộp task";
        }
        if ("TASK_APPROVED".equals(normalized)) {
            return "Task được duyệt";
        }
        if ("TASK_REJECTED".equals(normalized)) {
            return "Task bị từ chối";
        }
        if ("TASK_ESCALATED".equals(normalized)) {
            return "Task leo thang lên Tantou Editor";
        }
        if ("TASK_DUE_SOON".equals(normalized)) {
            return "Task sắp đến hạn";
        }
        if ("TASK_DELAYED".equals(normalized)) {
            return "Task bị chậm tiến độ";
        }
        if ("TASK_OVERDUE".equals(normalized)) {
            return "Task đã quá hạn";
        }
        if ("CHAPTER_AT_RISK".equals(normalized)) {
            return "Chapter có nguy cơ trễ deadline";
        }
        if ("MANUSCRIPT_SUBMITTED".equals(normalized)) {
            return "Bản thảo đã được nộp";
        }
        if ("MANUSCRIPT_APPROVED".equals(normalized)) {
            return "Bản thảo được duyệt";
        }
        if ("MANUSCRIPT_PUBLISHED".equals(normalized)) {
            return "Bản thảo đã xuất bản";
        }
        if ("MANUSCRIPT_REJECTED".equals(normalized)) {
            return "Bản thảo bị từ chối";
        }
        if ("REVIEW_ASSIGNED".equals(normalized)) {
            return "Bạn được giao review bản thảo";
        }
        if ("REVIEW_WARNING".equals(normalized)) {
            return "Sắp hết hạn review bản thảo";
        }
        if ("REVIEW_OVERDUE".equals(normalized)) {
            return "Review bản thảo đã quá hạn";
        }
        if ("PROPOSAL_BOARD_REVIEW_OPENED".equals(normalized)) {
            return "Proposal mở phiên bỏ phiếu";
        }
        if ("PROPOSAL_BOARD_VOTE_CLOSING_SOON".equals(normalized)) {
            return "Phiên bỏ phiếu sắp kết thúc";
        }
        if ("PROPOSAL_TANTOU_REVIEW_OVERDUE".equals(normalized)) {
            return "Tantou Editor trễ hạn review proposal";
        }
        if ("PROPOSAL_APPROVED_SERIES_CREATED".equals(normalized)) {
            return "Proposal được duyệt, Series đã được tạo";
        }
        if ("PROPOSAL_BOARD_REVISION_REQUESTED".equals(normalized)) {
            return "Proposal yêu cầu chỉnh sửa";
        }
        if ("DECISION_SESSION_OPENED".equals(normalized)) {
            return "Phiên quyết định mới được mở";
        }
        if ("DECISION_RESOLVED".equals(normalized)) {
            return "Phiên quyết định đã kết thúc";
        }
        if ("RANKING_PERIOD_OPENED".equals(normalized)) {
            return "Kỳ bình chọn xếp hạng mới";
        }
        if ("SERIES_DEADLINE_UPDATED".equals(normalized)) {
            return "Deadline series đã được cập nhật";
        }
        return type.trim();
    }

    private String defaultViewUrl(String type, long referenceId, String referenceType) {
        if (referenceId <= 0 || type == null) {
            return null;
        }
        String normalized = type.trim().toUpperCase();
        String ref = referenceType == null ? "" : referenceType.trim().toUpperCase();
        if (ref.equals("TASK") || ref.equals("PAGETASK")) {
            if ("TASK_ESCALATED".equals(normalized)) {
                return "/main/tasks/" + referenceId + "?tab=history";
            }
            return "/main/tasks/" + referenceId;
        }
        if (ref.equals("CHAPTER")) {
            return "/main/chapters/" + referenceId;
        }
        if (ref.equals("MANUSCRIPT")) {
            if ("MANUSCRIPT_SUBMITTED".equals(normalized) || "REVIEW_WARNING".equals(normalized)) {
                return "/main/manuscripts/" + referenceId + "/versions/" + referenceId + "/review";
            }
            if ("MANUSCRIPT_REJECTED".equals(normalized)) {
                return "/main/manuscripts/" + referenceId + "?tab=feedback";
            }
            return "/main/manuscripts/" + referenceId;
        }
        if (ref.equals("PROPOSAL")) {
            if (normalized.contains("VOTE")) {
                return "/main/proposals/" + referenceId + "/vote";
            }
            return "/main/proposals/" + referenceId;
        }
        if (ref.equals("DECISION") || ref.equals("DECISION_SESSION")) {
            return "/main/decisions/" + referenceId;
        }
        if (ref.equals("SERIES")) {
            return "/main/series/" + referenceId;
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}



