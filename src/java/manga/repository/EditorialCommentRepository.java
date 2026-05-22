package manga.repository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class EditorialCommentRepository {

    @Autowired
    private DataSource dataSource;

    public void saveComment(long periodId, long mangakaId, long boardMemberId, String comment) {
        String sql = "INSERT INTO EditorialComment (periodId, mangakaId, boardMemberId, comment, createdAt) " +
                     "VALUES (?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            ps.setLong(3, boardMemberId);
            ps.setString(4, comment);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot save editorial comment", ex);
        }
    }

    public List<Map<String, Object>> getCommentsByPeriodAndMangaka(long periodId, long mangakaId) {
        String sql = "SELECT ec.id, ec.periodId, ec.mangakaId, ec.boardMemberId, ec.comment, ec.createdAt, u.username as boardMemberName " +
                     "FROM EditorialComment ec " +
                     "JOIN [User] u ON u.id = ec.boardMemberId " +
                     "WHERE ec.periodId = ? AND ec.mangakaId = ? " +
                     "ORDER BY ec.createdAt DESC";
        List<Map<String, Object>> comments = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> comment = new HashMap<>();
                    comment.put("id", rs.getLong("id"));
                    comment.put("periodId", rs.getLong("periodId"));
                    comment.put("mangakaId", rs.getLong("mangakaId"));
                    comment.put("boardMemberId", rs.getLong("boardMemberId"));
                    comment.put("boardMemberName", rs.getString("boardMemberName"));
                    comment.put("comment", rs.getString("comment"));
                    comment.put("createdAt", rs.getTimestamp("createdAt"));
                    comments.add(comment);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get editorial comments", ex);
        }
        return comments;
    }

    public List<Map<String, Object>> getCommentsByPeriod(long periodId) {
        String sql = "SELECT ec.id, ec.periodId, ec.mangakaId, ec.boardMemberId, ec.comment, ec.createdAt, u.username as boardMemberName " +
                     "FROM EditorialComment ec " +
                     "JOIN [User] u ON u.id = ec.boardMemberId " +
                     "WHERE ec.periodId = ? " +
                     "ORDER BY ec.createdAt DESC";
        List<Map<String, Object>> comments = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> comment = new HashMap<>();
                    comment.put("id", rs.getLong("id"));
                    comment.put("periodId", rs.getLong("periodId"));
                    comment.put("mangakaId", rs.getLong("mangakaId"));
                    comment.put("boardMemberId", rs.getLong("boardMemberId"));
                    comment.put("boardMemberName", rs.getString("boardMemberName"));
                    comment.put("comment", rs.getString("comment"));
                    comment.put("createdAt", rs.getTimestamp("createdAt"));
                    comments.add(comment);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get editorial comments", ex);
        }
        return comments;
    }

    public boolean hasComment(long periodId, long mangakaId, long boardMemberId) {
        String sql = "SELECT COUNT(1) FROM EditorialComment WHERE periodId = ? AND mangakaId = ? AND boardMemberId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            ps.setLong(3, boardMemberId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check editorial comment", ex);
        }
        return false;
    }

    public void deleteCommentsByPeriod(long periodId) {
        String sql = "DELETE FROM EditorialComment WHERE periodId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot delete editorial comments", ex);
        }
    }
}
