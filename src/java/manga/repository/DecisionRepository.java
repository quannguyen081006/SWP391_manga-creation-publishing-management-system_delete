package manga.repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class DecisionRepository {

    @Autowired
    private DataSource dataSource;

    public List<Map<String, Object>> listSessions() {
        String sql = "SELECT id, seriesId, rankingRecordId, status, result, openedAt, closedAt FROM DecisionSession ORDER BY openedAt DESC";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(mapSession(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list decision sessions", ex);
        }
        return rows;
    }

    public Map<String, Object> getSessionDetail(long sessionId) {
        String sessionSql = "SELECT id, seriesId, rankingRecordId, status, result, openedAt, closedAt FROM DecisionSession WHERE id = ?";
        String votesSql = "SELECT id, sessionId, voterId, decision, justification, votedAt FROM DecisionVote WHERE sessionId = ? ORDER BY votedAt DESC";

        try (Connection conn = dataSource.getConnection()) {
            Map<String, Object> session;
            try (PreparedStatement ps = conn.prepareStatement(sessionSql)) {
                ps.setLong(1, sessionId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Decision session not found");
                    }
                    session = mapSession(rs);
                }
            }

            List<Map<String, Object>> votes = new ArrayList<Map<String, Object>>();
            try (PreparedStatement ps = conn.prepareStatement(votesSql)) {
                ps.setLong(1, sessionId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> vote = new HashMap<String, Object>();
                        vote.put("id", rs.getLong("id"));
                        vote.put("sessionId", rs.getLong("sessionId"));
                        vote.put("voterId", rs.getLong("voterId"));
                        vote.put("decision", rs.getString("decision"));
                        vote.put("justification", rs.getString("justification"));
                        vote.put("votedAt", rs.getTimestamp("votedAt"));
                        votes.add(vote);
                    }
                }
            }

            session.put("votes", votes);
            return session;
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load decision session detail", ex);
        }
    }

    public void castVote(long sessionId, long voterId, String decision, String justification) {
        String normalized = decision == null ? "" : decision.trim().toUpperCase();
        if (!"CONTINUE".equals(normalized) && !"CANCEL".equals(normalized) && !"CHANGE_TYPE".equals(normalized)) {
            throw new IllegalArgumentException("decision must be CONTINUE, CANCEL, or CHANGE_TYPE");
        }
        if ("CANCEL".equals(normalized) && (justification == null || justification.trim().isEmpty())) {
            throw new IllegalArgumentException("justification is required when decision=CANCEL");
        }

        String sql = "INSERT INTO DecisionVote (sessionId, voterId, decision, justification, votedAt) VALUES (?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, sessionId);
            ps.setLong(2, voterId);
            ps.setString(3, normalized);
            ps.setString(4, justification == null ? null : justification.trim());
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot cast decision vote", ex);
        }
    }

    private Map<String, Object> mapSession(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<String, Object>();
        row.put("id", rs.getLong("id"));
        row.put("seriesId", rs.getLong("seriesId"));
        row.put("rankingRecordId", rs.getLong("rankingRecordId"));
        row.put("status", rs.getString("status"));
        row.put("result", rs.getString("result"));
        row.put("openedAt", rs.getTimestamp("openedAt"));
        row.put("closedAt", rs.getTimestamp("closedAt"));
        return row;
    }
}


