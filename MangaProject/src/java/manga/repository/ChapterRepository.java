package manga.repository;

import manga.model.ChapterSummary;
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
public class ChapterRepository {

    @Autowired
    private DataSource dataSource;

    public List<ChapterSummary> listBySeries(long seriesId) {
        String sql = "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk FROM Chapter WHERE seriesId = ? ORDER BY chapterNumber";
        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, seriesId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ChapterSummary c = new ChapterSummary();
                    c.setId(rs.getLong("id"));
                    c.setSeriesId(rs.getLong("seriesId"));
                    c.setChapterNumber(rs.getInt("chapterNumber"));
                    c.setTitle(rs.getString("title"));
                    c.setStatus(rs.getString("status"));
                    c.setSubmissionDeadline(rs.getDate("submissionDeadline"));
                    c.setPublicationDate(rs.getDate("publicationDate"));
                    c.setCompletionPct(rs.getDouble("completionPct"));
                    c.setAtRisk(rs.getBoolean("atRisk"));
                    rows.add(c);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list chapters", ex);
        }
        return rows;
    }

    public ChapterSummary findById(long chapterId) {
        String sql = "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk FROM Chapter WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                ChapterSummary c = new ChapterSummary();
                c.setId(rs.getLong("id"));
                c.setSeriesId(rs.getLong("seriesId"));
                c.setChapterNumber(rs.getInt("chapterNumber"));
                c.setTitle(rs.getString("title"));
                c.setStatus(rs.getString("status"));
                c.setSubmissionDeadline(rs.getDate("submissionDeadline"));
                c.setPublicationDate(rs.getDate("publicationDate"));
                c.setCompletionPct(rs.getDouble("completionPct"));
                c.setAtRisk(rs.getBoolean("atRisk"));
                return c;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load chapter", ex);
        }
    }

    public long create(long seriesId, int chapterNumber, String title, Date publicationDate) {
        Date submissionDeadline = new Date(publicationDate.getTime() - (14L * 24L * 60L * 60L * 1000L));
        String sql = "INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk, createdAt) VALUES (?, ?, ?, 'PLANNING', ?, ?, 0.00, 0, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, seriesId);
            ps.setInt(2, chapterNumber);
            ps.setString(3, title);
            ps.setDate(4, submissionDeadline);
            ps.setDate(5, publicationDate);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot create chapter");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create chapter", ex);
        }
    }

    public void updateChapterMetadata(long chapterId, String title, Date publicationDate) {
        Date submissionDeadline = new Date(publicationDate.getTime() - (14L * 24L * 60L * 60L * 1000L));
        String sql = "UPDATE Chapter SET title = ?, publicationDate = ?, submissionDeadline = ? WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setDate(2, publicationDate);
            ps.setDate(3, submissionDeadline);
            ps.setLong(4, chapterId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Chapter not found");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update chapter", ex);
        }
    }

    public void submitForReview(long chapterId, long mangakaId) {
        String sql =
            "UPDATE c SET c.status = 'EDITORIAL_REVIEW' "
            + "FROM Chapter c "
            + "JOIN Series s ON s.id = c.seriesId "
            + "WHERE c.id = ? AND s.mangakaId = ? AND c.completionPct >= 100.00 AND c.status IN ('IN_PROGRESS','COMPLETE')";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            ps.setLong(2, mangakaId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Chapter must be owner-managed and 100% complete before submit-review");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit chapter for review", ex);
        }
    }

    public long findSeriesOwnerMangaka(long seriesId) {
        String sql = "SELECT mangakaId FROM Series WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, seriesId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Series not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot verify series owner", ex);
        }
    }

    public long findOwnerMangakaByChapter(long chapterId) {
        String sql = "SELECT s.mangakaId FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot verify chapter owner", ex);
        }
    }

    public long findSeriesTantou(long seriesId) {
        String sql = "SELECT tantouEditorId FROM Series WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, seriesId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Series not found");
                }
                return rs.getLong(1);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load series tantou", ex);
        }
    }

    public int refreshAtRiskFlags() {
        String sql =
            "UPDATE c SET atRisk = CASE "
            + "WHEN c.status IN ('PLANNING','IN_PROGRESS','EDITORIAL_REVIEW') "
            + "AND c.completionPct < 50 "
            + "AND DATEDIFF(DAY, c.createdAt, GETDATE()) * 1.0 / NULLIF(DATEDIFF(DAY, c.createdAt, c.submissionDeadline), 0) >= 0.7 "
            + "THEN 1 ELSE 0 END "
            + "FROM Chapter c";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            return ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot refresh chapter at-risk flags", ex);
        }
    }
}

