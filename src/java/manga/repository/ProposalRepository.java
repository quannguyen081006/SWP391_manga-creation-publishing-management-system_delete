package manga.repository;

import manga.model.AuthenticatedUser;
import manga.model.Proposal;
import manga.model.ProposalHistory;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class ProposalRepository {

    @Autowired
    private DataSource dataSource;

    private static final String BOARD_REVOTE_NOTE = "Board vote tied across approve, revise, and reject. Revote requested.";
    private static final String BOARD_VOTE_ACTIONS = "'APPROVED','REVISE_REQUESTED','REJECTED'";
    private static final String CURRENT_BOARD_ROUND_FILTER =
            "AND h.id > ISNULL((SELECT MAX(rv.id) FROM ProposalHistory rv WHERE rv.proposalId = p.id "
            + "AND rv.actorRole = 'SYSTEM' AND rv.submitAttemptNumber = p.submitAttemptCount "
            + "AND rv.actionType = 'UPDATED' AND rv.note = '" + BOARD_REVOTE_NOTE + "'), 0) ";

    private static final String SELECT_COLUMNS =
            "p.id, p.mangakaId, p.title, p.genre, p.synopsis, p.sampleFilePath, p.originalFileName, "
            + "p.approximateChapter, p.status, p.submittedAt, p.rejectedAt, p.assignedEditorId, p.submitAttemptCount, "
            + "(SELECT COUNT(1) FROM ProposalHistory h WHERE h.proposalId = p.id "
            + "AND h.actorRole = 'EDITORIAL_BOARD' AND h.submitAttemptNumber = p.submitAttemptCount "
            + CURRENT_BOARD_ROUND_FILTER
            + "AND h.actionType = 'APPROVED') AS boardApproveVotes, "
            + "(SELECT COUNT(1) FROM ProposalHistory h WHERE h.proposalId = p.id "
            + "AND h.actorRole = 'EDITORIAL_BOARD' AND h.submitAttemptNumber = p.submitAttemptCount "
            + CURRENT_BOARD_ROUND_FILTER
            + "AND h.actionType = 'REVISE_REQUESTED') AS boardReviseVotes, "
            + "(SELECT COUNT(1) FROM ProposalHistory h WHERE h.proposalId = p.id "
            + "AND h.actorRole = 'EDITORIAL_BOARD' AND h.submitAttemptNumber = p.submitAttemptCount "
            + CURRENT_BOARD_ROUND_FILTER
            + "AND h.actionType = 'REJECTED') AS boardRejectVotes, "
            + "(SELECT COUNT(1) FROM ProposalHistory h WHERE h.proposalId = p.id "
            + "AND h.actorRole = 'EDITORIAL_BOARD' AND h.submitAttemptNumber = p.submitAttemptCount "
            + CURRENT_BOARD_ROUND_FILTER
            + "AND h.actionType IN (" + BOARD_VOTE_ACTIONS + ")) AS boardTotalVotes ";

    public List<Proposal> findForMangaka(long mangakaId) {
        String sql = "SELECT " + SELECT_COLUMNS
            + "FROM Proposal p WHERE p.mangakaId = ? ORDER BY p.createdAt DESC";
        return queryMany(sql, Long.valueOf(mangakaId));
    }

    public List<Proposal> findForBoardAndEditor() {
        String sql = "SELECT " + SELECT_COLUMNS
            + "FROM Proposal p WHERE p.status IN ('UNDER_REVIEW','BOARD_REVIEW','REVISION_REQUESTED','APPROVED','REJECTED') "
            + "ORDER BY p.createdAt DESC";
        return queryMany(sql, null);
    }

    public List<Proposal> findForAssignedEditor(long editorId) {
        String sql = "SELECT " + SELECT_COLUMNS
            + "FROM Proposal p "
            + "WHERE p.assignedEditorId = ? "
            + "AND p.status IN ('UNDER_REVIEW','BOARD_REVIEW','REVISION_REQUESTED','APPROVED','REJECTED') "
            + "ORDER BY p.createdAt DESC";
        return queryMany(sql, Long.valueOf(editorId));
    }

    public Proposal findById(long id) {
        String sql = "SELECT " + SELECT_COLUMNS + "FROM Proposal p WHERE p.id = ?";
        List<Proposal> rows = queryMany(sql, Long.valueOf(id));
        return rows.isEmpty() ? null : rows.get(0);
    }

    public long createDraft(AuthenticatedUser actor, String title, String genre, String synopsis,
            String sampleFilePath, String originalFileName, int approximateChapter) {
        String sql =
            "INSERT INTO Proposal (mangakaId, title, genre, synopsis, sampleFilePath, originalFileName, approximateChapter, status, createdAt, updatedAt) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, 'DRAFT', GETDATE(), GETDATE())";
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, actor.getId());
                ps.setString(2, title);
                ps.setString(3, genre);
                ps.setString(4, synopsis);
                ps.setString(5, sampleFilePath);
                ps.setString(6, originalFileName);
                ps.setInt(7, approximateChapter);
                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) {
                        throw new IllegalStateException("Cannot get generated proposal id");
                    }
                    long id = rs.getLong(1);
                    insertHistory(conn, id, actor, "CREATED", "Draft proposal created.", 0);
                    conn.commit();
                    return id;
                }
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create proposal", ex);
        }
    }

    public void updateDraft(AuthenticatedUser actor, long proposalId, String title, String genre, String synopsis,
            String sampleFilePath, String originalFileName, int approximateChapter) {
        StringBuilder sql = new StringBuilder("UPDATE Proposal SET title = ?, genre = ?, synopsis = ?");
        if (sampleFilePath != null) {
            sql.append(", sampleFilePath = ?, originalFileName = ?");
        }
        sql.append(", approximateChapter = ?, updatedAt = GETDATE() ")
           .append("WHERE id = ? AND mangakaId = ? AND status IN ('DRAFT','REVISION_REQUESTED')");
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                int i = 1;
                ps.setString(i++, title);
                ps.setString(i++, genre);
                ps.setString(i++, synopsis);
                if (sampleFilePath != null) {
                    ps.setString(i++, sampleFilePath);
                    ps.setString(i++, originalFileName);
                }
                ps.setInt(i++, approximateChapter);
                ps.setLong(i++, proposalId);
                ps.setLong(i++, actor.getId());
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Only editable proposal owner can update proposal");
                }
                Proposal p = findById(conn, proposalId);
                insertHistory(conn, proposalId, actor, "UPDATED", "Proposal content updated.", p.getSubmitAttemptCount());
                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update proposal draft", ex);
        }
    }

    public void submitForTantouReview(AuthenticatedUser actor, long proposalId) {
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Proposal p = lockProposal(conn, proposalId);
                if (p.getMangakaId() != actor.getId() || !isEditableStatus(p.getStatus())) {
                    throw new IllegalArgumentException("Only editable proposal owner can submit");
                }
                if (p.getSubmitAttemptCount() >= 2) {
                    throw new IllegalArgumentException("Proposal submit attempt limit reached");
                }
                long editorId = findLeastAssignedTantouEditor(conn);
                int nextAttempt = p.getSubmitAttemptCount() + 1;
                String action = p.getSubmitAttemptCount() == 0 ? "SUBMITTED" : "RESUBMITTED";
                String sql =
                    "UPDATE Proposal SET status = 'UNDER_REVIEW', submittedAt = GETDATE(), assignedEditorId = ?, "
                    + "submitAttemptCount = ?, updatedAt = GETDATE() WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, editorId);
                    ps.setInt(2, nextAttempt);
                    ps.setLong(3, proposalId);
                    ps.executeUpdate();
                }
                insertHistory(conn, proposalId, actor, action, "Submitted to Tantou Editor review.", nextAttempt);
                insertSystemHistory(conn, proposalId, "ASSIGNED_EDITOR", "Auto-assigned Tantou Editor #" + editorId + ".", nextAttempt);
                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit proposal", ex);
        }
    }

    public void reviewByTantou(AuthenticatedUser actor, long proposalId, String decision, String note) {
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Proposal p = lockProposal(conn, proposalId);
                if (p.getAssignedEditorId() == null || p.getAssignedEditorId().longValue() != actor.getId()) {
                    throw new IllegalArgumentException("Only assigned Tantou Editor can review this proposal");
                }
                if (!"UNDER_REVIEW".equalsIgnoreCase(p.getStatus())) {
                    throw new IllegalArgumentException("Proposal is not under Tantou review");
                }
                if ("APPROVE".equals(decision)) {
                    updateProposalStatus(conn, proposalId, "BOARD_REVIEW", false);
                    insertHistory(conn, proposalId, actor, "APPROVED", note, p.getSubmitAttemptCount());
                    notifyBoardReviewOpened(conn, p);
                } else if ("REJECT".equals(decision)) {
                    updateProposalStatus(conn, proposalId, "REJECTED", true);
                    insertHistory(conn, proposalId, actor, "REJECTED", note, p.getSubmitAttemptCount());
                } else if ("REVISE".equals(decision)) {
                    updateProposalStatus(conn, proposalId, "REVISION_REQUESTED", false);
                    insertHistory(conn, proposalId, actor, "REVISE_REQUESTED", note, p.getSubmitAttemptCount());
                } else {
                    throw new IllegalArgumentException("Review decision must be APPROVE, REJECT, or REVISE");
                }
                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot review proposal", ex);
        }
    }

    public void voteByEditorialBoard(AuthenticatedUser actor, long proposalId, String decision, String note) {
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Proposal p = lockProposal(conn, proposalId);
                if (!"BOARD_REVIEW".equalsIgnoreCase(p.getStatus())) {
                    throw new IllegalArgumentException("Proposal is not waiting for Editorial Board review");
                }
                if (hasBoardVote(conn, proposalId, actor.getId(), p.getSubmitAttemptCount())) {
                    throw new IllegalArgumentException("You have already voted on this proposal");
                }

                String action = "APPROVE".equals(decision)
                        ? "APPROVED"
                        : ("REJECT".equals(decision) ? "REJECTED" : "REVISE_REQUESTED");
                insertHistory(conn, proposalId, actor, action, note, p.getSubmitAttemptCount());
                resolveBoardReviewIfReady(conn, p);
                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot vote on proposal", ex);
        }
    }

    public List<ProposalHistory> listHistory(long proposalId) {
        String sql =
            "SELECT h.id, h.proposalId, h.actorId, u.fullName AS actorName, h.actorRole, h.actionType, "
            + "h.note, h.createdAt, h.submitAttemptNumber "
            + "FROM ProposalHistory h LEFT JOIN [User] u ON u.id = h.actorId "
            + "WHERE h.proposalId = ? ORDER BY h.createdAt DESC, h.id DESC";
        List<ProposalHistory> rows = new ArrayList<ProposalHistory>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProposalHistory h = new ProposalHistory();
                    h.setId(rs.getLong("id"));
                    h.setProposalId(rs.getLong("proposalId"));
                    long actorId = rs.getLong("actorId");
                    h.setActorId(rs.wasNull() ? null : Long.valueOf(actorId));
                    h.setActorName(rs.getString("actorName"));
                    h.setActorRole(rs.getString("actorRole"));
                    h.setActionType(rs.getString("actionType"));
                    h.setNote(rs.getString("note"));
                    h.setCreatedAt(rs.getTimestamp("createdAt"));
                    h.setSubmitAttemptNumber(rs.getInt("submitAttemptNumber"));
                    rows.add(h);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list proposal history", ex);
        }
        return rows;
    }

    public boolean hasActiveProposal(long mangakaId, long excludingProposalId) {
        String sql = "SELECT COUNT(1) FROM Proposal WHERE mangakaId = ? AND id <> ? AND status IN ('UNDER_REVIEW','BOARD_REVIEW','REVISION_REQUESTED')";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, mangakaId);
            ps.setLong(2, excludingProposalId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check active proposal", ex);
        }
    }

    private Proposal findById(Connection conn, long id) throws SQLException {
        String sql = "SELECT " + SELECT_COLUMNS + "FROM Proposal p WHERE p.id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapBaseProposal(rs) : null;
            }
        }
    }

    private Proposal lockProposal(Connection conn, long proposalId) throws SQLException {
        String sql = "SELECT " + SELECT_COLUMNS + "FROM Proposal p WITH (UPDLOCK, ROWLOCK) WHERE p.id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Proposal not found");
                }
                return mapBaseProposal(rs);
            }
        }
    }

    private boolean isEditableStatus(String status) {
        return "DRAFT".equalsIgnoreCase(status) || "REVISION_REQUESTED".equalsIgnoreCase(status);
    }

    private long ensureSeriesExistsOnApprove(Connection conn, long proposalId) throws SQLException {
        String checkSeries = "SELECT COUNT(1) FROM Series WHERE proposalId = ?";
        try (PreparedStatement ps = conn.prepareStatement(checkSeries)) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (rs.getInt(1) > 0) {
                    return findSeriesIdByProposal(conn, proposalId);
                }
            }
        }
        Proposal p = findById(conn, proposalId);
        long editorId = p.getAssignedEditorId() == null ? findLeastAssignedTantouEditor(conn) : p.getAssignedEditorId().longValue();
        String insertSeries =
            "INSERT INTO Series (proposalId, mangakaId, tantouEditorId, title, genre, status, createdAt) "
            + "VALUES (?, ?, ?, ?, ?, 'ACTIVE', GETDATE())";
        try (PreparedStatement ps = conn.prepareStatement(insertSeries, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, proposalId);
            ps.setLong(2, p.getMangakaId());
            ps.setLong(3, editorId);
            ps.setString(4, p.getTitle());
            ps.setString(5, p.getGenre());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }
        return findSeriesIdByProposal(conn, proposalId);
    }

    private long findSeriesIdByProposal(Connection conn, long proposalId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT id FROM Series WHERE proposalId = ?")) {
            ps.setLong(1, proposalId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }
        throw new IllegalStateException("Cannot resolve approved series");
    }

    private boolean hasBoardVote(Connection conn, long proposalId, long actorId, int attempt) throws SQLException {
        String sql =
            "SELECT COUNT(1) FROM ProposalHistory "
            + "WHERE proposalId = ? AND actorId = ? AND actorRole = 'EDITORIAL_BOARD' "
            + "AND submitAttemptNumber = ? AND actionType IN (" + BOARD_VOTE_ACTIONS + ") "
            + "AND id > ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            ps.setLong(2, actorId);
            ps.setInt(3, attempt);
            ps.setLong(4, findCurrentBoardRoundStartId(conn, proposalId, attempt));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private void resolveBoardReviewIfReady(Connection conn, Proposal proposal) throws SQLException {
        String countSql =
            "SELECT "
            + "SUM(CASE WHEN actionType = 'APPROVED' THEN 1 ELSE 0 END) AS approveVotes, "
            + "SUM(CASE WHEN actionType = 'REVISE_REQUESTED' THEN 1 ELSE 0 END) AS reviseVotes, "
            + "SUM(CASE WHEN actionType = 'REJECTED' THEN 1 ELSE 0 END) AS rejectVotes, "
            + "COUNT(1) AS totalVotes "
            + "FROM ProposalHistory "
            + "WHERE proposalId = ? AND actorRole = 'EDITORIAL_BOARD' "
            + "AND submitAttemptNumber = ? AND actionType IN (" + BOARD_VOTE_ACTIONS + ") "
            + "AND id > ?";
        int approveVotes;
        int reviseVotes;
        int rejectVotes;
        int totalVotes;
        try (PreparedStatement ps = conn.prepareStatement(countSql)) {
            ps.setLong(1, proposal.getId());
            ps.setInt(2, proposal.getSubmitAttemptCount());
            ps.setLong(3, findCurrentBoardRoundStartId(conn, proposal.getId(), proposal.getSubmitAttemptCount()));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                approveVotes = rs.getInt("approveVotes");
                reviseVotes = rs.getInt("reviseVotes");
                rejectVotes = rs.getInt("rejectVotes");
                totalVotes = rs.getInt("totalVotes");
            }
        }
        if (totalVotes < 3) {
            return;
        }

        if (approveVotes == 1 && reviseVotes == 1 && rejectVotes == 1) {
            insertSystemHistory(conn, proposal.getId(), "UPDATED", BOARD_REVOTE_NOTE, proposal.getSubmitAttemptCount());
            return;
        }

        if (approveVotes > reviseVotes && approveVotes > rejectVotes) {
            long seriesId = ensureSeriesExistsOnApprove(conn, proposal.getId());
            updateProposalStatus(conn, proposal.getId(), "APPROVED", false);
            insertSystemHistory(conn, proposal.getId(), "APPROVED", "Editorial Board approved publication.", proposal.getSubmitAttemptCount());
            notifyProposalApproved(conn, proposal, seriesId);
        } else if (reviseVotes > approveVotes && reviseVotes > rejectVotes) {
            updateProposalStatus(conn, proposal.getId(), "REVISION_REQUESTED", false);
            insertSystemHistory(conn, proposal.getId(), "REVISE_REQUESTED", "Editorial Board requested revisions before publication.", proposal.getSubmitAttemptCount());
            notifyProposalRevisionRequested(conn, proposal);
        } else if (rejectVotes > approveVotes && rejectVotes > reviseVotes) {
            updateProposalStatus(conn, proposal.getId(), "REJECTED", true);
            insertSystemHistory(conn, proposal.getId(), "REJECTED", "Editorial Board rejected publication.", proposal.getSubmitAttemptCount());
        } else {
            insertSystemHistory(conn, proposal.getId(), "UPDATED", BOARD_REVOTE_NOTE, proposal.getSubmitAttemptCount());
        }
    }

    private long findCurrentBoardRoundStartId(Connection conn, long proposalId, int attempt) throws SQLException {
        String sql =
            "SELECT ISNULL(MAX(id), 0) FROM ProposalHistory "
            + "WHERE proposalId = ? AND actorRole = 'SYSTEM' AND submitAttemptNumber = ? "
            + "AND actionType = 'UPDATED' AND note = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            ps.setInt(2, attempt);
            ps.setString(3, BOARD_REVOTE_NOTE);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    private void notifyProposalApproved(Connection conn, Proposal proposal, long seriesId) throws SQLException {
        String sql =
            "INSERT INTO Notification (userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt) "
            + "VALUES (?, 'PROPOSAL_APPROVED_SERIES_CREATED', 'Series created', ?, ?, ?, 'SERIES', 0, GETDATE())";
        String message = "Proposal \"" + proposal.getTitle() + "\" was approved and series #" + seriesId + " was created.";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposal.getMangakaId());
            ps.setString(2, message);
            ps.setString(3, "/main/series/" + seriesId);
            ps.setLong(4, seriesId);
            ps.executeUpdate();
        }
        if (proposal.getAssignedEditorId() != null) {
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setLong(1, proposal.getAssignedEditorId().longValue());
                ps.setString(2, message);
                ps.setString(3, "/main/series/" + seriesId);
                ps.setLong(4, seriesId);
                ps.executeUpdate();
            }
        }
    }

    private void notifyBoardReviewOpened(Connection conn, Proposal proposal) throws SQLException {
        String sql =
            "INSERT INTO Notification (userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt) "
            + "SELECT u.id, 'PROPOSAL_BOARD_REVIEW_OPENED', 'Proposal ready for board review', "
            + "?, ?, ?, 'PROPOSAL', 0, GETDATE() "
            + "FROM [User] u "
            + "JOIN UserRole ur ON ur.userId = u.id "
            + "JOIN [Role] r ON r.id = ur.roleId "
            + "WHERE u.status = 'ACTIVE' AND r.name = 'EDITORIAL_BOARD'";
        String message = "Proposal \"" + proposal.getTitle() + "\" passed Tantou review and is ready for Editorial Board vote.";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, message);
            ps.setString(2, "/main/proposals/" + proposal.getId());
            ps.setLong(3, proposal.getId());
            ps.executeUpdate();
        }
    }

    private void notifyProposalRevisionRequested(Connection conn, Proposal proposal) throws SQLException {
        String sql =
            "INSERT INTO Notification (userId, type, title, message, viewUrl, referenceId, referenceType, isRead, createdAt) "
            + "VALUES (?, 'PROPOSAL_BOARD_REVISION_REQUESTED', 'Revision requested', ?, ?, ?, 'PROPOSAL', 0, GETDATE())";
        String message = "Editorial Board requested revisions for proposal \"" + proposal.getTitle() + "\".";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposal.getMangakaId());
            ps.setString(2, message);
            ps.setString(3, "/main/proposals/" + proposal.getId() + "/edit");
            ps.setLong(4, proposal.getId());
            ps.executeUpdate();
        }
    }

    private long findLeastAssignedTantouEditor(Connection conn) throws SQLException {
        String sql =
            "SELECT TOP 1 u.id "
            + "FROM [User] u JOIN UserRole ur ON ur.userId = u.id JOIN [Role] r ON r.id = ur.roleId "
            + "LEFT JOIN Proposal p ON p.assignedEditorId = u.id AND p.status IN ('UNDER_REVIEW','BOARD_REVIEW','REVISION_REQUESTED') "
            + "WHERE r.name = 'TANTOU_EDITOR' AND u.status = 'ACTIVE' "
            + "GROUP BY u.id ORDER BY COUNT(p.id), u.id";
        try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getLong(1);
            }
        }
        throw new IllegalStateException("No active Tantou Editor available for assignment");
    }

    private void updateProposalStatus(Connection conn, long proposalId, String status, boolean setRejectedAt) throws SQLException {
        String sql = setRejectedAt
            ? "UPDATE Proposal SET status = ?, rejectedAt = GETDATE(), updatedAt = GETDATE() WHERE id = ?"
            : "UPDATE Proposal SET status = ?, updatedAt = GETDATE() WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setLong(2, proposalId);
            ps.executeUpdate();
        }
    }

    private void insertHistory(Connection conn, long proposalId, AuthenticatedUser actor, String actionType, String note, int attempt) throws SQLException {
        String role = actor.getRoles().isEmpty() ? "USER" : actor.getRoles().iterator().next();
        insertHistory(conn, proposalId, Long.valueOf(actor.getId()), role, actionType, note, attempt);
    }

    private void insertSystemHistory(Connection conn, long proposalId, String actionType, String note, int attempt) throws SQLException {
        insertHistory(conn, proposalId, null, "SYSTEM", actionType, note, attempt);
    }

    private void insertHistory(Connection conn, long proposalId, Long actorId, String actorRole, String actionType, String note, int attempt) throws SQLException {
        String sql =
            "INSERT INTO ProposalHistory (proposalId, actorId, actorRole, actionType, note, submitAttemptNumber, createdAt) "
            + "VALUES (?, ?, ?, ?, ?, ?, GETDATE())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, proposalId);
            if (actorId == null) {
                ps.setNull(2, java.sql.Types.BIGINT);
            } else {
                ps.setLong(2, actorId.longValue());
            }
            ps.setString(3, actorRole);
            ps.setString(4, actionType);
            ps.setString(5, note);
            ps.setInt(6, attempt);
            ps.executeUpdate();
        }
    }

    private List<Proposal> queryMany(String sql, Long param) {
        List<Proposal> rows = new ArrayList<Proposal>();
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (param != null) {
                ps.setLong(1, param.longValue());
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapBaseProposal(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot query proposals", ex);
        }
        return rows;
    }

    private Proposal mapBaseProposal(ResultSet rs) throws SQLException {
        Proposal p = new Proposal();
        p.setId(rs.getLong("id"));
        p.setMangakaId(rs.getLong("mangakaId"));
        p.setTitle(rs.getString("title"));
        p.setGenre(rs.getString("genre"));
        p.setSynopsis(rs.getString("synopsis"));
        p.setSampleFilePath(rs.getString("sampleFilePath"));
        p.setOriginalFileName(rs.getString("originalFileName"));
        int chapters = rs.getInt("approximateChapter");
        p.setApproximateChapter(rs.wasNull() ? null : Integer.valueOf(chapters));
        p.setStatus(rs.getString("status"));
        p.setSubmittedAt(rs.getTimestamp("submittedAt"));
        p.setRejectedAt(rs.getTimestamp("rejectedAt"));
        long editorId = rs.getLong("assignedEditorId");
        p.setAssignedEditorId(rs.wasNull() ? null : Long.valueOf(editorId));
        p.setSubmitAttemptCount(rs.getInt("submitAttemptCount"));
        p.setBoardApproveVotes(readOptionalInt(rs, "boardApproveVotes"));
        p.setBoardReviseVotes(readOptionalInt(rs, "boardReviseVotes"));
        p.setBoardRejectVotes(readOptionalInt(rs, "boardRejectVotes"));
        p.setBoardTotalVotes(readOptionalInt(rs, "boardTotalVotes"));
        return p;
    }

    private int readOptionalInt(ResultSet rs, String columnName) throws SQLException {
        try {
            return rs.getInt(columnName);
        } catch (SQLException ex) {
            return 0;
        }
    }
}
