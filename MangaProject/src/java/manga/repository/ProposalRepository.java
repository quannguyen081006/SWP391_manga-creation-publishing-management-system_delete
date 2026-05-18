package manga.repository;

import manga.model.Proposal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class ProposalRepository {

    @Autowired
    private DataSource dataSource;

    public List<Proposal> findForMangaka(long mangakaId) {
        String sql =
            "SELECT p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId, "
            + "SUM(CASE WHEN pv.voteType = 'APPROVE' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN pv.voteType = 'REJECT' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "SUM(CASE WHEN pv.voteType = 'ABSTAIN' THEN 1 ELSE 0 END) AS abstainVotes "
            + "FROM Proposal p "
            + "LEFT JOIN ProposalVote pv ON pv.proposalId = p.id "
            + "WHERE p.mangakaId = ? "
            + "GROUP BY p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId "
            + "ORDER BY MAX(p.createdAt) DESC";
        return queryMany(sql, mangakaId);
    }

    public List<Proposal> findForBoardAndEditor() {
        String sql =
            "SELECT p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId, "
            + "SUM(CASE WHEN pv.voteType = 'APPROVE' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN pv.voteType = 'REJECT' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "SUM(CASE WHEN pv.voteType = 'ABSTAIN' THEN 1 ELSE 0 END) AS abstainVotes "
            + "FROM Proposal p "
            + "LEFT JOIN ProposalVote pv ON pv.proposalId = p.id "
            + "WHERE p.status IN ('SUBMITTED','VOTING','APPROVED','REJECTED','DEFERRED') "
            + "GROUP BY p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId "
            + "ORDER BY MAX(p.createdAt) DESC";
        return queryMany(sql, null);
    }

    public Proposal findById(long id) {
        String sql =
            "SELECT p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId, "
            + "SUM(CASE WHEN pv.voteType = 'APPROVE' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN pv.voteType = 'REJECT' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "SUM(CASE WHEN pv.voteType = 'ABSTAIN' THEN 1 ELSE 0 END) AS abstainVotes "
            + "FROM Proposal p "
            + "LEFT JOIN ProposalVote pv ON pv.proposalId = p.id "
            + "WHERE p.id = ? "
            + "GROUP BY p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.status, p.submittedAt, p.votingDeadline, p.rejectedAt, p.assignedEditorId";
        List<Proposal> rows = queryMany(sql, id);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public long createDraft(long mangakaId, String title, String genre, String synopsis) {
        String sql =
            "INSERT INTO Proposal (mangakaId, title, genre, synopsis, status, createdAt, updatedAt) "
            + "VALUES (?, ?, ?, ?, 'DRAFT', GETDATE(), GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, mangakaId);
            ps.setString(2, title);
            ps.setString(3, genre);
            ps.setString(4, synopsis);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot get generated proposal id");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create proposal", ex);
        }
    }

    public void updateDraft(long proposalId, long mangakaId, String title, String genre, String synopsis) {
        String sql = "UPDATE Proposal SET title = ?, genre = ?, synopsis = ?, updatedAt = GETDATE() WHERE id = ? AND mangakaId = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setString(2, genre);
            ps.setString(3, synopsis);
            ps.setLong(4, proposalId);
            ps.setLong(5, mangakaId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only owner can update DRAFT proposal");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update proposal draft", ex);
        }
    }

    public List<Map<String, Object>> listVotes(long proposalId) {
        String sql = "SELECT id, proposalId, voterId, voteType, reason, votedAt FROM ProposalVote WHERE proposalId = ? ORDER BY votedAt DESC";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<String, Object>();
                    row.put("id", rs.getLong("id"));
                    row.put("proposalId", rs.getLong("proposalId"));
                    row.put("voterId", rs.getLong("voterId"));
                    row.put("voteType", rs.getString("voteType"));
                    row.put("reason", rs.getString("reason"));
                    row.put("votedAt", rs.getTimestamp("votedAt"));
                    rows.add(row);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list proposal votes", ex);
        }
        return rows;
    }

    public void submitProposal(long proposalId, long mangakaId) {
        String sql =
            "UPDATE Proposal SET status = 'SUBMITTED', submittedAt = GETDATE(), updatedAt = GETDATE() "
            + "WHERE id = ? AND mangakaId = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            ps.setLong(2, mangakaId);
            int updated = ps.executeUpdate();
            if (updated == 0) {
                throw new IllegalArgumentException("Only DRAFT proposal owner can submit");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit proposal", ex);
        }
    }

    public boolean hasActiveProposal(long mangakaId) {
        String sql = "SELECT COUNT(1) FROM Proposal WHERE mangakaId = ? AND status IN ('SUBMITTED','VOTING')";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check active proposal", ex);
        }
    }

    public void castVoteAndResolve(long proposalId, long voterId, String voteType, String reason) {
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Proposal p = lockProposal(conn, proposalId);
                ensureProposalCanVote(conn, p, voterId);
                insertVote(conn, proposalId, voterId, voteType, reason);
                if ("SUBMITTED".equalsIgnoreCase(p.getStatus())) {
                    updateProposalStatus(conn, proposalId, "VOTING", false);
                }
                resolveIfQuorum(conn, proposalId);
                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot cast vote", ex);
        }
    }

    private Proposal lockProposal(Connection conn, long proposalId) throws SQLException {
        String sql = "SELECT id, mangakaId, title, genre, status, assignedEditorId FROM Proposal WITH (UPDLOCK, ROWLOCK) WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Proposal not found");
                }
                Proposal p = new Proposal();
                p.setId(rs.getLong("id"));
                p.setMangakaId(rs.getLong("mangakaId"));
                p.setTitle(rs.getString("title"));
                p.setGenre(rs.getString("genre"));
                p.setStatus(rs.getString("status"));
                long editorId = rs.getLong("assignedEditorId");
                p.setAssignedEditorId(rs.wasNull() ? null : editorId);
                return p;
            }
        }
    }

    private void ensureProposalCanVote(Connection conn, Proposal p, long voterId) throws SQLException {
        if (!("SUBMITTED".equalsIgnoreCase(p.getStatus()) || "VOTING".equalsIgnoreCase(p.getStatus()))) {
            throw new IllegalArgumentException("Proposal is not open for voting");
        }
        if (p.getMangakaId() == voterId) {
            throw new IllegalArgumentException("Mangaka cannot vote on own proposal");
        }
        if (p.getAssignedEditorId() != null && p.getAssignedEditorId() == voterId) {
            throw new IllegalArgumentException("Assigned Tantou Editor cannot vote this proposal");
        }

        String checkDuplicate = "SELECT COUNT(1) FROM ProposalVote WHERE proposalId = ? AND voterId = ?";
        try (PreparedStatement ps = conn.prepareStatement(checkDuplicate)) {
            ps.setLong(1, p.getId());
            ps.setLong(2, voterId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (rs.getInt(1) > 0) {
                    throw new IllegalArgumentException("You already voted this proposal");
                }
            }
        }
    }

    private void insertVote(Connection conn, long proposalId, long voterId, String voteType, String reason) throws SQLException {
        String sql = "INSERT INTO ProposalVote (proposalId, voterId, voteType, reason, votedAt) VALUES (?, ?, ?, ?, GETDATE())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            ps.setLong(2, voterId);
            ps.setString(3, voteType);
            ps.setString(4, reason);
            ps.executeUpdate();
        }
    }

    private void resolveIfQuorum(Connection conn, long proposalId) throws SQLException {
        String countSql =
            "SELECT "
            + "SUM(CASE WHEN voteType='APPROVE' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN voteType='REJECT' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "SUM(CASE WHEN voteType='ABSTAIN' THEN 1 ELSE 0 END) AS abstainVotes, "
            + "COUNT(1) AS totalVotes "
            + "FROM ProposalVote WHERE proposalId = ?";

        int approve = 0;
        int reject = 0;
        int total = 0;
        try (PreparedStatement ps = conn.prepareStatement(countSql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    approve = rs.getInt("approveVotes");
                    reject = rs.getInt("rejectVotes");
                    total = rs.getInt("totalVotes");
                }
            }
        }

        if (total < 3) {
            return;
        }

        if (approve > reject) {
            ensureSeriesExistsOnApprove(conn, proposalId);
            updateProposalStatus(conn, proposalId, "APPROVED", false);
            return;
        }

        if (reject > 0 && reject >= approve) {
            updateProposalStatus(conn, proposalId, "REJECTED", true);
            return;
        }

        updateProposalStatus(conn, proposalId, "DEFERRED", false);
    }

    private void ensureSeriesExistsOnApprove(Connection conn, long proposalId) throws SQLException {
        String checkSeries = "SELECT COUNT(1) FROM Series WHERE proposalId = ?";
        try (PreparedStatement ps = conn.prepareStatement(checkSeries)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (rs.getInt(1) > 0) {
                    return;
                }
            }
        }

        String proposalSql = "SELECT mangakaId, title, genre, assignedEditorId FROM Proposal WHERE id = ?";
        long mangakaId;
        long editorId;
        String title;
        String genre;

        try (PreparedStatement ps = conn.prepareStatement(proposalSql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Proposal not found during approval");
                }
                mangakaId = rs.getLong("mangakaId");
                title = rs.getString("title");
                genre = rs.getString("genre");
                long tmp = rs.getLong("assignedEditorId");
                editorId = rs.wasNull() ? 0L : tmp;
            }
        }

        if (editorId == 0L) {
            editorId = getAnyTantouEditor(conn);
            String assignSql = "UPDATE Proposal SET assignedEditorId = ?, updatedAt = GETDATE() WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(assignSql)) {
                ps.setLong(1, editorId);
                ps.setLong(2, proposalId);
                ps.executeUpdate();
            }
        }

        String insertSeries =
            "INSERT INTO Series (proposalId, mangakaId, tantouEditorId, title, genre, status, createdAt) "
            + "VALUES (?, ?, ?, ?, ?, 'ACTIVE', GETDATE())";
        try (PreparedStatement ps = conn.prepareStatement(insertSeries)) {
            ps.setLong(1, proposalId);
            ps.setLong(2, mangakaId);
            ps.setLong(3, editorId);
            ps.setString(4, title);
            ps.setString(5, genre);
            ps.executeUpdate();
        }
    }

    private long getAnyTantouEditor(Connection conn) throws SQLException {
        String sql =
            "SELECT TOP 1 u.id "
            + "FROM [User] u "
            + "JOIN UserRole ur ON ur.userId = u.id "
            + "JOIN [Role] r ON r.id = ur.roleId "
            + "WHERE r.name = 'TANTOU_EDITOR' AND u.status = 'ACTIVE' "
            + "ORDER BY u.id";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getLong(1);
            }
        }
        throw new IllegalStateException("No active Tantou Editor available for series assignment");
    }

    private void updateProposalStatus(Connection conn, long proposalId, String status, boolean setRejectedAt) throws SQLException {
        String sql;
        if (setRejectedAt) {
            sql = "UPDATE Proposal SET status = ?, rejectedAt = GETDATE(), updatedAt = GETDATE() WHERE id = ?";
        } else {
            sql = "UPDATE Proposal SET status = ?, updatedAt = GETDATE() WHERE id = ?";
        }
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setLong(2, proposalId);
            ps.executeUpdate();
        }
    }

    private List<Proposal> queryMany(String sql, Object param) {
        List<Proposal> rows = new ArrayList<Proposal>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (param != null) {
                if (param instanceof Long) {
                    ps.setLong(1, (Long) param);
                } else {
                    ps.setObject(1, param);
                }
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Proposal p = new Proposal();
                    p.setId(rs.getLong("id"));
                    p.setMangakaId(rs.getLong("mangakaId"));
                    p.setTitle(rs.getString("title"));
                    p.setGenre(rs.getString("genre"));
                    p.setSynopsis(rs.getString("synopsis"));
                    p.setStatus(rs.getString("status"));
                    p.setSubmittedAt(rs.getTimestamp("submittedAt"));
                    p.setVotingDeadline(rs.getTimestamp("votingDeadline"));
                    p.setRejectedAt(rs.getTimestamp("rejectedAt"));
                    long editorId = rs.getLong("assignedEditorId");
                    p.setAssignedEditorId(rs.wasNull() ? null : editorId);
                    p.setApproveVotes(rs.getInt("approveVotes"));
                    p.setRejectVotes(rs.getInt("rejectVotes"));
                    p.setAbstainVotes(rs.getInt("abstainVotes"));
                    rows.add(p);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot query proposals", ex);
        }
        return rows;
    }

    public int resolveExpiredVotings() {
        String selectSql =
            "SELECT id FROM Proposal "
            + "WHERE status IN ('SUBMITTED','VOTING') "
            + "AND votingDeadline IS NOT NULL "
            + "AND votingDeadline <= GETDATE()";

        int processed = 0;
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                List<Long> ids = new ArrayList<Long>();
                try (PreparedStatement ps = conn.prepareStatement(selectSql);
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        ids.add(rs.getLong(1));
                    }
                }

                for (Long id : ids) {
                    resolveExpiredProposal(conn, id.longValue());
                    processed++;
                }

                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot resolve expired proposal votings", ex);
        }

        return processed;
    }

    private void resolveExpiredProposal(Connection conn, long proposalId) throws SQLException {
        Proposal proposal = lockProposal(conn, proposalId);
        if (!("SUBMITTED".equalsIgnoreCase(proposal.getStatus()) || "VOTING".equalsIgnoreCase(proposal.getStatus()))) {
            return;
        }

        String countSql =
            "SELECT "
            + "SUM(CASE WHEN voteType='APPROVE' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN voteType='REJECT' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "COUNT(1) AS totalVotes "
            + "FROM ProposalVote WHERE proposalId = ?";

        int approve = 0;
        int reject = 0;
        int total = 0;
        try (PreparedStatement ps = conn.prepareStatement(countSql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    approve = rs.getInt("approveVotes");
                    reject = rs.getInt("rejectVotes");
                    total = rs.getInt("totalVotes");
                }
            }
        }

        if (total < 3) {
            updateProposalStatus(conn, proposalId, "DEFERRED", false);
            return;
        }

        if (approve > reject) {
            ensureSeriesExistsOnApprove(conn, proposalId);
            updateProposalStatus(conn, proposalId, "APPROVED", false);
            return;
        }

        if (reject > approve) {
            updateProposalStatus(conn, proposalId, "REJECTED", true);
            return;
        }

        updateProposalStatus(conn, proposalId, "DEFERRED", false);
    }
}

