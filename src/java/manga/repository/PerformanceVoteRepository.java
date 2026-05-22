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
public class PerformanceVoteRepository {

    @Autowired
    private DataSource dataSource;

    public void submitVote(long periodId, long mangakaId, long boardMemberId, 
                          int popularityScore, int reliabilityScore, int qualityScore, String comment) {
        // Check if period is OPEN
        String periodStatusSql = "SELECT status FROM PerformancePeriod WHERE id = ?";
        // Check for duplicate vote
        String duplicateSql = "SELECT COUNT(1) FROM PerformanceVote WHERE periodId = ? AND mangakaId = ? AND boardMemberId = ?";
        // Insert vote
        String insertSql = "INSERT INTO PerformanceVote (periodId, mangakaId, boardMemberId, popularityScore, reliabilityScore, qualityScore, comment, votedAt) VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())";

        try (Connection conn = dataSource.getConnection()) {
            // Check period status
            try (PreparedStatement ps = conn.prepareStatement(periodStatusSql)) {
                ps.setLong(1, periodId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Performance period not found");
                    }
                    if (!"OPEN".equalsIgnoreCase(rs.getString("status"))) {
                        throw new IllegalArgumentException("Performance votes can only be submitted when period is OPEN");
                    }
                }
            }

            // Check for duplicate
            try (PreparedStatement ps = conn.prepareStatement(duplicateSql)) {
                ps.setLong(1, periodId);
                ps.setLong(2, mangakaId);
                ps.setLong(3, boardMemberId);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("You have already voted for this mangaka in this period");
                    }
                }
            }

            // Insert vote
            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                ps.setLong(1, periodId);
                ps.setLong(2, mangakaId);
                ps.setLong(3, boardMemberId);
                ps.setInt(4, popularityScore);
                ps.setInt(5, reliabilityScore);
                ps.setInt(6, qualityScore);
                ps.setString(7, comment);
                ps.executeUpdate();
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit performance vote", ex);
        }
    }

    public List<Map<String, Object>> getVotesByPeriod(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, boardMemberId, popularityScore, reliabilityScore, qualityScore, comment, votedAt " +
                     "FROM PerformanceVote WHERE periodId = ? ORDER BY votedAt DESC";
        List<Map<String, Object>> votes = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    votes.add(mapVote(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get votes by period", ex);
        }
        return votes;
    }

    public List<Map<String, Object>> getVotesByMangaka(long periodId, long mangakaId) {
        String sql = "SELECT id, periodId, mangakaId, boardMemberId, popularityScore, reliabilityScore, qualityScore, comment, votedAt " +
                     "FROM PerformanceVote WHERE periodId = ? AND mangakaId = ? ORDER BY votedAt DESC";
        List<Map<String, Object>> votes = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    votes.add(mapVote(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get votes by mangaka", ex);
        }
        return votes;
    }

    public Map<String, Object> getVoteByBoardMember(long periodId, long mangakaId, long boardMemberId) {
        String sql = "SELECT id, periodId, mangakaId, boardMemberId, popularityScore, reliabilityScore, qualityScore, comment, votedAt " +
                     "FROM PerformanceVote WHERE periodId = ? AND mangakaId = ? AND boardMemberId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            ps.setLong(3, boardMemberId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapVote(rs);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get vote by board member", ex);
        }
        return null;
    }

    public List<Map<String, Object>> getMangakaList() {
        String sql = "SELECT id, username FROM [User] WHERE id IN (SELECT DISTINCT mangakaId FROM Series) ORDER BY username";
        List<Map<String, Object>> users = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getLong("id"));
                user.put("username", rs.getString("username"));
                users.add(user);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list mangaka users", ex);
        }
        return users;
    }

    public String getMangakaName(long mangakaId) {
        String sql = "SELECT username FROM [User] WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("username");
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get mangaka name", ex);
        }
        return "Unknown";
    }

    private Map<String, Object> mapVote(ResultSet rs) throws SQLException {
        Map<String, Object> vote = new HashMap<>();
        vote.put("id", rs.getLong("id"));
        vote.put("periodId", rs.getLong("periodId"));
        vote.put("mangakaId", rs.getLong("mangakaId"));
        vote.put("boardMemberId", rs.getLong("boardMemberId"));
        vote.put("popularityScore", rs.getInt("popularityScore"));
        vote.put("reliabilityScore", rs.getInt("reliabilityScore"));
        vote.put("qualityScore", rs.getInt("qualityScore"));
        vote.put("comment", rs.getString("comment"));
        vote.put("votedAt", rs.getTimestamp("votedAt"));
        return vote;
    }
}
