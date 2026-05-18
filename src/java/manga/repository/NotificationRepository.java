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

    public List<NotificationItem> listByUser(long userId) {
        String sql = "SELECT id, userId, type, message, isRead, createdAt FROM Notification WHERE userId = ? ORDER BY createdAt DESC";
        List<NotificationItem> rows = new ArrayList<NotificationItem>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    NotificationItem n = new NotificationItem();
                    n.setId(rs.getLong("id"));
                    n.setUserId(rs.getLong("userId"));
                    n.setType(rs.getString("type"));
                    n.setMessage(rs.getString("message"));
                    n.setRead(rs.getBoolean("isRead"));
                    n.setCreatedAt(rs.getTimestamp("createdAt"));
                    rows.add(n);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load notifications", ex);
        }
        return rows;
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
}



