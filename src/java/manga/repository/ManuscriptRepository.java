package manga.repository;

import manga.model.ManuscriptSummary;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import manga.model.AnnotationSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class ManuscriptRepository {

    @Autowired
    private DataSource dataSource;

    private static final String MANUSCRIPT_SELECT =
            "SELECT m.id, m.chapterId, m.version, m.status, m.submittedAt, m.reviewDeadline, m.fileUrl, "
            + "m.originalFileName, m.uploadedAt, m.fileSize, m.fileExtension, m.revisionDeadline, m.feedback, m.notes, "
            + "COALESCE(m.genre, p.genre) AS genre, "
            + "c.title AS chapterTitle, c.chapterNumber, s.title AS seriesTitle, p.synopsis, "
            + "mangaka.fullName AS mangakaName, CAST(NULL AS VARCHAR(255)) AS reviewerName "
            + "FROM Manuscript m "
            + "JOIN Chapter c ON c.id = m.chapterId "
            + "JOIN Series s ON s.id = c.seriesId "
            + "LEFT JOIN Proposal p ON p.id = s.proposalId "
            + "LEFT JOIN [User] mangaka ON mangaka.id = s.mangakaId ";

    public List<ManuscriptSummary> listByChapter(long chapterId) {
        String sql = MANUSCRIPT_SELECT + "WHERE m.chapterId = ? ORDER BY m.version DESC";
        List<ManuscriptSummary> rows = new ArrayList<ManuscriptSummary>();
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try ( ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list manuscripts", ex);
        }
        return rows;
    }

    public ManuscriptSummary findById(long manuscriptId) {
        String sql = MANUSCRIPT_SELECT + "WHERE m.id = ?";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            try ( ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return map(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load manuscript", ex);
        }
    }

    public List<AnnotationSummary> listAnnotations(long manuscriptId) {

        String sql = "SELECT a.id, a.manuscriptId, a.editorId, u.fullName AS editorName, a.pageNumber, "
                + "a.category, a.status, a.content, a.createdAt "
                + "FROM Annotation a "
                + "LEFT JOIN [User] u ON u.id = a.editorId "
                + "WHERE a.manuscriptId = ? ORDER BY a.pageNumber ASC, a.createdAt DESC";

        List<AnnotationSummary> rows = new ArrayList<AnnotationSummary>();

        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setLong(1, manuscriptId);

            try ( ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    rows.add(mapAnnotation(rs));
                }
            }

        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list annotations", ex);
        }

        return rows;
    }

    public List<ManuscriptSummary> listManuscriptsNeedingReviewReminder() {
        String sql = MANUSCRIPT_SELECT + "WHERE m.status IN ('SUBMITTED', 'UNDER_REVIEW') ORDER BY m.reviewDeadline ASC";
        List<ManuscriptSummary> rows = new ArrayList<ManuscriptSummary>();
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            try ( ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list manuscripts needing review", ex);
        }
        return rows;
    }

    public long submit(long chapterId, String fileUrl) {
        return createDraft(chapterId, fileUrl, null, null, null);
    }

    public long createDraft(long chapterId, String fileUrl) {
        return createDraft(chapterId, fileUrl, null, null, null);
    }

    public long createDraft(long chapterId, String fileUrl, String originalFileName, String notes, String genre) {
        return createDraft(chapterId, fileUrl, originalFileName, null, null, notes, genre);
    }

    public long createDraft(long chapterId, String fileUrl, String originalFileName, Long fileSize, String fileExtension, String notes, String genre) {
        String activeSql = "SELECT COUNT(1) FROM Manuscript WITH (UPDLOCK, HOLDLOCK) WHERE chapterId = ? AND status IN ('DRAFT','SUBMITTED','UNDER_REVIEW')";
        String latestSql = "SELECT TOP 1 status FROM Manuscript WHERE chapterId = ? ORDER BY version DESC";
        String versionSql = "SELECT ISNULL(MAX(version),0)+1 FROM Manuscript WITH (UPDLOCK, HOLDLOCK) WHERE chapterId = ?";
        String chapterSql = "SELECT c.title AS chapterTitle, c.chapterNumber, s.title AS seriesTitle, p.genre "
                + "FROM Chapter c JOIN Series s ON s.id = c.seriesId LEFT JOIN Proposal p ON p.id = s.proposalId WHERE c.id = ?";
        String insert = "INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl, originalFileName, uploadedAt, fileSize, fileExtension, notes, genre, seriesTitle, chapterTitle, chapterNumber) "
                + "VALUES (?, ?, 'DRAFT', GETDATE(), ?, ?, GETDATE(), ?, ?, ?, ?, ?, ?, ?)";

        try ( Connection conn = dataSource.getConnection()) {
            boolean oldAutoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                try ( PreparedStatement ps = conn.prepareStatement(activeSql)) {
                    ps.setLong(1, chapterId);
                    try ( ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        if (rs.getInt(1) > 0) {
                            throw new IllegalArgumentException("Cannot create another manuscript while a draft or active review version exists");
                        }
                    }
                }

                try ( PreparedStatement ps = conn.prepareStatement(latestSql)) {
                    ps.setLong(1, chapterId);
                    try ( ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            String latestStatus = rs.getString(1);
                            if (!"REVISION_REQUIRED".equals(latestStatus)) {
                                throw new IllegalArgumentException("Next version can only be created after revision is requested");
                            }
                        }
                    }
                }

                int version;
                String chapterTitle = null;
                Integer chapterNumber = null;
                String seriesTitle = null;
                String resolvedGenre = genre;
                try ( PreparedStatement ps = conn.prepareStatement(versionSql)) {
                    ps.setLong(1, chapterId);
                    try ( ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        version = rs.getInt(1);
                    }
                }
                try ( PreparedStatement ps = conn.prepareStatement(chapterSql)) {
                    ps.setLong(1, chapterId);
                    try ( ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            chapterTitle = rs.getString("chapterTitle");
                            int no = rs.getInt("chapterNumber");
                            chapterNumber = rs.wasNull() ? null : Integer.valueOf(no);
                            seriesTitle = rs.getString("seriesTitle");
                            if (resolvedGenre == null || resolvedGenre.trim().isEmpty()) {
                                resolvedGenre = rs.getString("genre");
                            }
                        }
                    }
                }

                try ( PreparedStatement ps = conn.prepareStatement(insert, PreparedStatement.RETURN_GENERATED_KEYS)) {
                    ps.setLong(1, chapterId);
                    ps.setInt(2, version);
                    ps.setString(3, fileUrl);
                    ps.setString(4, originalFileName);
                    if (fileSize == null) {
                        ps.setNull(5, java.sql.Types.BIGINT);
                    } else {
                        ps.setLong(5, fileSize.longValue());
                    }
                    ps.setString(6, fileExtension);
                    ps.setString(7, notes);
                    ps.setString(8, resolvedGenre);
                    ps.setString(9, seriesTitle);
                    ps.setString(10, chapterTitle);
                    if (chapterNumber == null) {
                        ps.setNull(11, java.sql.Types.INTEGER);
                    } else {
                        ps.setInt(11, chapterNumber.intValue());
                    }
                    ps.executeUpdate();
                    try ( ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            long id = rs.getLong(1);
                            conn.commit();
                            return id;
                        }
                    }
                }
                throw new IllegalStateException("Cannot create manuscript draft");
            } catch (RuntimeException ex) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw ex;
            } catch (SQLException ex) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw ex;
            } finally {
                conn.setAutoCommit(oldAutoCommit);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create manuscript draft", ex);
        }
    }

    public String getStatus(long manuscriptId) {
        String sql = "SELECT status FROM Manuscript WHERE id = ?";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            try ( ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Manuscript not found");
                }
                return rs.getString("status");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load manuscript status", ex);
        }
    }

    public void approve(long manuscriptId) {
        String sql = "UPDATE Manuscript SET status='APPROVED' WHERE id = ? AND status = 'UNDER_REVIEW'";
        updateStatus(sql, manuscriptId, "Cannot approve manuscript");
    }

    public void reject(long manuscriptId, String feedback) {
        String sql = "UPDATE Manuscript SET status='REJECTED', feedback=? WHERE id = ? AND status = 'UNDER_REVIEW'";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, feedback);
            ps.setLong(2, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Cannot reject manuscript");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot reject manuscript", ex);
        }
    }

    public void startReview(long manuscriptId) {
        String sql = "UPDATE Manuscript SET status='UNDER_REVIEW' WHERE id = ? AND status = 'SUBMITTED'";
        updateStatus(sql, manuscriptId, "Cannot start review: manuscript must be in SUBMITTED status");
    }

    public void submitForReview(long manuscriptId) {
        String activeSql = "SELECT COUNT(1) FROM Manuscript currentVersion WITH (UPDLOCK, HOLDLOCK) "
                + "JOIN Manuscript otherVersion WITH (UPDLOCK, HOLDLOCK) ON otherVersion.chapterId = currentVersion.chapterId "
                + "WHERE currentVersion.id = ? AND otherVersion.id <> currentVersion.id "
                + "AND otherVersion.status IN ('SUBMITTED','UNDER_REVIEW')";
        String sql = "UPDATE Manuscript SET status='SUBMITTED', submittedAt=GETDATE() WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection()) {
            boolean oldAutoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(activeSql)) {
                    ps.setLong(1, manuscriptId);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        if (rs.getInt(1) > 0) {
                            throw new IllegalArgumentException("Cannot submit manuscript while another version is under review");
                        }
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setLong(1, manuscriptId);
                    if (ps.executeUpdate() == 0) {
                        throw new IllegalArgumentException("Cannot submit manuscript: must be DRAFT");
                    }
                }
                conn.commit();
            } catch (RuntimeException ex) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw ex;
            } catch (SQLException ex) {
                try { conn.rollback(); } catch (SQLException ignore) {}
                throw ex;
            } finally {
                conn.setAutoCommit(oldAutoCommit);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit manuscript for review", ex);
        }
    }

    public void updateFileUrl(long manuscriptId, String fileUrl) {
        updateFile(manuscriptId, fileUrl, null);
    }

    public void updateFile(long manuscriptId, String fileUrl, String originalFileName) {
        String sql = "UPDATE Manuscript SET fileUrl=?, originalFileName=COALESCE(?, originalFileName), uploadedAt=GETDATE() WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fileUrl);
            ps.setString(2, originalFileName);
            ps.setLong(3, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Cannot update manuscript: must be DRAFT");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update manuscript", ex);
        }
    }

    public void updateDraftMetadata(long manuscriptId, String fileUrl, String originalFileName, Long fileSize,
                                    String fileExtension, String notes, String genre) {
        String sql = "UPDATE Manuscript SET "
                + "fileUrl=COALESCE(?, fileUrl), "
                + "originalFileName=COALESCE(?, originalFileName), "
                + "uploadedAt=CASE WHEN ? IS NULL THEN uploadedAt ELSE GETDATE() END, "
                + "fileSize=COALESCE(?, fileSize), "
                + "fileExtension=COALESCE(?, fileExtension), "
                + "notes=?, genre=? "
                + "WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fileUrl);
            ps.setString(2, originalFileName);
            ps.setString(3, fileUrl);
            if (fileSize == null) {
                ps.setNull(4, java.sql.Types.BIGINT);
            } else {
                ps.setLong(4, fileSize.longValue());
            }
            ps.setString(5, fileExtension);
            ps.setString(6, notes);
            ps.setString(7, genre);
            ps.setLong(8, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Cannot update manuscript: must be DRAFT");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update manuscript", ex);
        }
    }

    public void delete(long manuscriptId) {
        String sql = "DELETE FROM Manuscript WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only draft manuscripts can be deleted");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot delete manuscript", ex);
        }
    }

    public long getChapterMangaka(long chapterId) {
        String sql = "SELECT s.mangakaId FROM Chapter c JOIN Series s ON s.id=c.seriesId WHERE c.id = ?";
        return queryLong(sql, chapterId, "Cannot resolve chapter owner");
    }

    public long getChapterTantou(long chapterId) {
        String sql = "SELECT s.tantouEditorId FROM Chapter c JOIN Series s ON s.id=c.seriesId WHERE c.id = ?";
        return queryLong(sql, chapterId, "Cannot resolve chapter tantou");
    }

    public long getManuscriptTantou(long manuscriptId) {
        String sql = "SELECT s.tantouEditorId FROM Manuscript m JOIN Chapter c ON c.id=m.chapterId JOIN Series s ON s.id=c.seriesId WHERE m.id = ?";
        return queryLong(sql, manuscriptId, "Cannot resolve manuscript tantou");
    }

    public void addAnnotation(long manuscriptId, long editorId, int pageNumber, String category, String status, String content) {
        String sql = "INSERT INTO Annotation (manuscriptId, editorId, pageNumber, category, status, content, createdAt) VALUES (?, ?, ?, ?, ?, ?, GETDATE())";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            ps.setLong(2, editorId);
            ps.setInt(3, pageNumber);
            ps.setString(4, category);
            ps.setString(5, status);
            ps.setString(6, content);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot add annotation", ex);
        }
    }

    public void requestRevision(long manuscriptId, String feedback) {
        String sql = "UPDATE Manuscript SET status='REVISION_REQUIRED', revisionDeadline=DATEADD(DAY,3,GETDATE()), feedback=? WHERE id = ? AND status = 'UNDER_REVIEW'";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, feedback);
            ps.setLong(2, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Cannot request revision: manuscript must be UNDER_REVIEW");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot request manuscript revision", ex);
        }
    }

    private void updateStatus(String sql, long manuscriptId, String error) {
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException(error);
            }
        } catch (SQLException ex) {
            throw new RuntimeException(error, ex);
        }
    }

    private long queryLong(String sql, long id, String error) {
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try ( ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(error);
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException(error, ex);
        }
    }

    private ManuscriptSummary map(ResultSet rs) throws SQLException {
        ManuscriptSummary m = new ManuscriptSummary();
        m.setId(rs.getLong("id"));
        m.setChapterId(rs.getLong("chapterId"));
        m.setVersion(rs.getInt("version"));
        m.setStatus(rs.getString("status"));
        m.setSubmittedAt(rs.getTimestamp("submittedAt"));
        m.setReviewDeadline(rs.getTimestamp("reviewDeadline"));
        m.setFileUrl(rs.getString("fileUrl"));
        m.setOriginalFileName(rs.getString("originalFileName"));
        m.setUploadedAt(rs.getTimestamp("uploadedAt"));
        long fileSize = rs.getLong("fileSize");
        m.setFileSize(rs.wasNull() ? null : Long.valueOf(fileSize));
        m.setFileExtension(rs.getString("fileExtension"));
        m.setRevisionDeadline(rs.getTimestamp("revisionDeadline"));
        m.setFeedback(rs.getString("feedback"));
        m.setNotes(rs.getString("notes"));
        m.setGenre(rs.getString("genre"));
        try {
            m.setSeriesTitle(rs.getString("seriesTitle"));
            m.setChapterTitle(rs.getString("chapterTitle"));
            int chapterNumber = rs.getInt("chapterNumber");
            m.setChapterNumber(rs.wasNull() ? null : Integer.valueOf(chapterNumber));
            m.setSynopsis(rs.getString("synopsis"));
            m.setMangakaName(rs.getString("mangakaName"));
            m.setReviewerName(rs.getString("reviewerName"));
        } catch (SQLException ignore) {
            // Some legacy queries only select Manuscript columns.
        }
        return m;
    }

    private AnnotationSummary mapAnnotation(ResultSet rs) throws SQLException {

        AnnotationSummary a = new AnnotationSummary();

        a.setId(rs.getLong("id"));
        a.setManuscriptId(rs.getLong("manuscriptId"));
        a.setEditorId(rs.getLong("editorId"));
        try {
            a.setEditorName(rs.getString("editorName"));
        } catch (SQLException ignore) {
        }
        a.setPageNumber(rs.getInt("pageNumber"));
        try {
            a.setCategory(rs.getString("category"));
            a.setStatus(rs.getString("status"));
        } catch (SQLException ignore) {
        }
        a.setContent(rs.getString("content"));
        a.setCreatedAt(rs.getTimestamp("createdAt"));

        return a;
    }
}
