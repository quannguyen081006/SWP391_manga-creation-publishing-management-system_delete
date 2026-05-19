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

    public List<ManuscriptSummary> listByChapter(long chapterId) {
        String sql = "SELECT id, chapterId, version, status, submittedAt, reviewDeadline, fileUrl, revisionDeadline FROM Manuscript WHERE chapterId = ? ORDER BY version DESC";
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
        String sql = "SELECT id, chapterId, version, status, submittedAt, reviewDeadline, fileUrl, revisionDeadline FROM Manuscript WHERE id = ?";
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

        String sql = "SELECT id, manuscriptId, editorId, pageNumber, content, createdAt "
                + "FROM Annotation WHERE manuscriptId = ? ORDER BY createdAt DESC";

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

    public long submit(long chapterId, String fileUrl) {
        String checkActive = "SELECT COUNT(1) FROM Manuscript WHERE chapterId = ? AND status IN ('SUBMITTED','UNDER_REVIEW')";
        String versionSql = "SELECT ISNULL(MAX(version),0)+1 FROM Manuscript WHERE chapterId = ?";
        String archive = "UPDATE Manuscript SET status='ARCHIVED' WHERE chapterId = ? AND status IN ('APPROVED','REJECTED')";
        String insert = "INSERT INTO Manuscript (chapterId, version, status, submittedAt, fileUrl) VALUES (?, ?, 'SUBMITTED', GETDATE(), ?)";

        try ( Connection conn = dataSource.getConnection()) {
            try ( PreparedStatement ps = conn.prepareStatement(checkActive)) {
                ps.setLong(1, chapterId);
                try ( ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Cannot submit while active review exists (BR-53)");
                    }
                }
            }

            int version;
            try ( PreparedStatement ps = conn.prepareStatement(versionSql)) {
                ps.setLong(1, chapterId);
                try ( ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    version = rs.getInt(1);
                }
            }

            try ( PreparedStatement ps = conn.prepareStatement(archive)) {
                ps.setLong(1, chapterId);
                ps.executeUpdate();
            }

            try ( PreparedStatement ps = conn.prepareStatement(insert, PreparedStatement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, chapterId);
                ps.setInt(2, version);
                ps.setString(3, fileUrl);
                ps.executeUpdate();
                try ( ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getLong(1);
                    }
                }
            }
            throw new IllegalStateException("Cannot create manuscript");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit manuscript", ex);
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

    public void reject(long manuscriptId) {
        String sql = "UPDATE Manuscript SET status='REJECTED', revisionDeadline=DATEADD(DAY,3,GETDATE()) WHERE id = ? AND status IN ('SUBMITTED','UNDER_REVIEW')";
        updateStatus(sql, manuscriptId, "Cannot reject manuscript");
    }

    public void startReview(long manuscriptId) {
        String sql = "UPDATE Manuscript SET status='UNDER_REVIEW' WHERE id = ? AND status = 'SUBMITTED'";
        updateStatus(sql, manuscriptId, "Cannot start manuscript review");
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

    public void addAnnotation(long manuscriptId, long editorId, int pageNumber, String content) {
        String sql = "INSERT INTO Annotation (manuscriptId, editorId, pageNumber, content, createdAt) VALUES (?, ?, ?, ?, GETDATE())";
        try ( Connection conn = dataSource.getConnection();  PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, manuscriptId);
            ps.setLong(2, editorId);
            ps.setInt(3, pageNumber);
            ps.setString(4, content);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot add annotation", ex);
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
        m.setRevisionDeadline(rs.getTimestamp("revisionDeadline"));
        return m;
    }

    private AnnotationSummary mapAnnotation(ResultSet rs) throws SQLException {

        AnnotationSummary a = new AnnotationSummary();

        a.setId(rs.getLong("id"));
        a.setManuscriptId(rs.getLong("manuscriptId"));
        a.setEditorId(rs.getLong("editorId"));
        a.setPageNumber(rs.getInt("pageNumber"));
        a.setContent(rs.getString("content"));
        a.setCreatedAt(rs.getTimestamp("createdAt"));

        return a;
    }
}
