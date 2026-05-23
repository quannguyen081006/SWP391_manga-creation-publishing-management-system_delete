package manga.repository;

import manga.model.AuthenticatedUser;
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

    public List<ChapterSummary> listAll() {
        String sql = "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk FROM Chapter ORDER BY createdAt DESC";
        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(mapChapter(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list chapters", ex);
        }
        return rows;
    }

    public List<ChapterSummary> listAll(AuthenticatedUser user) {
        String sql;
        List<Object> params = new ArrayList<Object>();

        if (user.hasRole("ADMIN")) {
            sql = "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk "
                + "FROM Chapter ORDER BY createdAt DESC";
        } else if (user.hasRole("MANGAKA")) {
            sql = "SELECT c.id, c.seriesId, c.chapterNumber, c.title, c.status, c.submissionDeadline, c.publicationDate, c.completionPct, c.atRisk "
                + "FROM Chapter c JOIN Series s ON s.id = c.seriesId "
                + "WHERE s.mangakaId = ? ORDER BY c.createdAt DESC";
            params.add(user.getId());
        } else if (user.hasRole("TANTOU_EDITOR")) {
            sql = "SELECT c.id, c.seriesId, c.chapterNumber, c.title, c.status, c.submissionDeadline, c.publicationDate, c.completionPct, c.atRisk "
                + "FROM Chapter c JOIN Series s ON s.id = c.seriesId "
                + "WHERE s.tantouEditorId = ? ORDER BY c.createdAt DESC";
            params.add(user.getId());
        } else {
            return new ArrayList<ChapterSummary>();
        }

        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) {
                ps.setLong(i + 1, (Long) params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapChapter(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list chapters", ex);
        }
        return rows;
    }

    public List<ChapterSummary> listBySeries(long seriesId) {
        String sql = "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk FROM Chapter WHERE seriesId = ? ORDER BY chapterNumber";
        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, seriesId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapChapter(rs));
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
                return mapChapter(rs);
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

    public long createNext(long seriesId, String title, Date publicationDate) {
        Date submissionDeadline = new Date(publicationDate.getTime() - (14L * 24L * 60L * 60L * 1000L));
        String nextSql = "SELECT ISNULL(MAX(chapterNumber), 0) + 1 FROM Chapter WITH (UPDLOCK, HOLDLOCK) WHERE seriesId = ?";
        String insertSql = "INSERT INTO Chapter (seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk, createdAt) VALUES (?, ?, ?, 'PLANNING', ?, ?, 0.00, 0, GETDATE())";

        try (Connection conn = dataSource.getConnection()) {
            boolean oldAutoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                int nextChapterNumber;
                try (PreparedStatement ps = conn.prepareStatement(nextSql)) {
                    ps.setLong(1, seriesId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Series not found");
                        }
                        nextChapterNumber = rs.getInt(1);
                    }
                }

                long newId;
                try (PreparedStatement ps = conn.prepareStatement(insertSql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                    ps.setLong(1, seriesId);
                    ps.setInt(2, nextChapterNumber);
                    ps.setString(3, title);
                    ps.setDate(4, submissionDeadline);
                    ps.setDate(5, publicationDate);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            throw new IllegalStateException("Cannot create chapter");
                        }
                        newId = rs.getLong(1);
                    }
                }
                conn.commit();
                return newId;
            } catch (RuntimeException ex) {
                conn.rollback();
                throw ex;
            } catch (SQLException ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(oldAutoCommit);
            }
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

    public void deleteChapter(long chapterId, long mangakaId) {
        long ownerId = findOwnerMangakaByChapter(chapterId);
        if (ownerId != mangakaId) {
            throw new IllegalArgumentException("Only series owner can delete chapter");
        }

        String statusSql = "SELECT status FROM Chapter WHERE id = ?";
        String taskCountSql = "SELECT COUNT(1) FROM PageTask WHERE chapterId = ?";
        String deleteSql = "DELETE FROM Chapter WHERE id = ?";

        try (Connection conn = dataSource.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                ps.setLong(1, chapterId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Chapter not found");
                    if (!"PLANNING".equalsIgnoreCase(rs.getString("status"))) {
                        throw new IllegalArgumentException("Only PLANNING chapters can be deleted");
                    }
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(taskCountSql)) {
                ps.setLong(1, chapterId);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Cannot delete chapter with existing tasks");
                    }
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                ps.setLong(1, chapterId);
                if (ps.executeUpdate() == 0) throw new IllegalArgumentException("Chapter not found");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot delete chapter", ex);
        }
    }

    public List<ChapterSummary> findChaptersWithDeadlineInDays(int days) {
        String sql =
            "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk "
            + "FROM Chapter "
            + "WHERE submissionDeadline = CAST(DATEADD(DAY, ?, GETDATE()) AS DATE) "
            + "  AND status IN ('PLANNING', 'IN_PROGRESS')";
        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, days);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(mapChapter(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot query deadline chapters", ex);
        }
        return rows;
    }

    public List<ChapterSummary> findMissedSubmissionDeadlineChapters() {
        String sql =
            "SELECT id, seriesId, chapterNumber, title, status, submissionDeadline, publicationDate, completionPct, atRisk "
            + "FROM Chapter "
            + "WHERE submissionDeadline < CAST(GETDATE() AS DATE) "
            + "  AND status NOT IN ('EDITORIAL_REVIEW', 'COMPLETE')";
        List<ChapterSummary> rows = new ArrayList<ChapterSummary>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(mapChapter(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot query missed deadline chapters", ex);
        }
        return rows;
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

    public String getChapterStatus(long chapterId) {
        String sql = "SELECT status FROM Chapter WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                return rs.getString("status");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get chapter status", ex);
        }
    }

    public String getSeriesStatus(long chapterId) {
        String sql = "SELECT s.status FROM Chapter c JOIN Series s ON s.id = c.seriesId WHERE c.id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, chapterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Chapter not found");
                }
                return rs.getString("status");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get series status", ex);
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

    private ChapterSummary mapChapter(ResultSet rs) throws SQLException {
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
}


