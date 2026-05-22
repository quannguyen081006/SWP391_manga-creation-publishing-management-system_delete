package manga.repository;

import manga.model.MangakaPerformanceRecord;
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
public class MangakaPerformanceRepository {

    @Autowired
    private DataSource dataSource;

    public void save(MangakaPerformanceRecord record) {
        String sql = "INSERT INTO MangakaPerformanceRecord (mangakaId, periodId, popularityScore, reliabilityScore, qualityScore, overallScore, rankPosition, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, record.getMangakaId());
            ps.setLong(2, record.getPeriodId());
            ps.setDouble(3, record.getPopularityScore());
            ps.setDouble(4, record.getReliabilityScore());
            ps.setDouble(5, record.getQualityScore());
            ps.setDouble(6, record.getOverallScore());
            ps.setInt(7, record.getRankPosition());
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    record.setId(rs.getLong(1));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot save mangaka performance record", ex);
        }
    }

    public List<MangakaPerformanceRecord> listByPeriod(long periodId) {
        String sql = "SELECT id, mangakaId, periodId, popularityScore, reliabilityScore, qualityScore, overallScore, rankPosition, createdAt FROM MangakaPerformanceRecord WHERE periodId = ? ORDER BY overallScore DESC";
        List<MangakaPerformanceRecord> records = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    records.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list mangaka performance records", ex);
        }
        return records;
    }

    public List<MangakaPerformanceRecord> listByPeriodOrderByPopularity(long periodId) {
        String sql = "SELECT id, mangakaId, periodId, popularityScore, reliabilityScore, qualityScore, overallScore, rankPosition, createdAt FROM MangakaPerformanceRecord WHERE periodId = ? ORDER BY popularityScore DESC";
        List<MangakaPerformanceRecord> records = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    records.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list mangaka performance records", ex);
        }
        return records;
    }

    public List<MangakaPerformanceRecord> listByPeriodOrderByReliability(long periodId) {
        String sql = "SELECT id, mangakaId, periodId, popularityScore, reliabilityScore, qualityScore, overallScore, rankPosition, createdAt FROM MangakaPerformanceRecord WHERE periodId = ? ORDER BY reliabilityScore DESC";
        List<MangakaPerformanceRecord> records = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    records.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list mangaka performance records", ex);
        }
        return records;
    }

    public List<MangakaPerformanceRecord> listByPeriodOrderByQuality(long periodId) {
        String sql = "SELECT id, mangakaId, periodId, popularityScore, reliabilityScore, qualityScore, overallScore, rankPosition, createdAt FROM MangakaPerformanceRecord WHERE periodId = ? ORDER BY qualityScore DESC";
        List<MangakaPerformanceRecord> records = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    records.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list mangaka performance records", ex);
        }
        return records;
    }

    public List<Long> listAllPeriods() {
        String sql = "SELECT DISTINCT periodId FROM MangakaPerformanceRecord ORDER BY periodId DESC";
        List<Long> periods = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                periods.add(rs.getLong(1));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list periods", ex);
        }
        return periods;
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

    public int getMangakaSeriesCount(long mangakaId) {
        String sql = "SELECT COUNT(*) FROM Series WHERE mangakaId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get mangaka series count", ex);
        }
        return 0;
    }

    public List<Map<String, Object>> listMangakaUsers() {
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

    private MangakaPerformanceRecord map(ResultSet rs) throws SQLException {
        MangakaPerformanceRecord record = new MangakaPerformanceRecord();
        record.setId(rs.getLong("id"));
        record.setMangakaId(rs.getLong("mangakaId"));
        record.setPeriodId(rs.getLong("periodId"));
        record.setPopularityScore(rs.getDouble("popularityScore"));
        record.setReliabilityScore(rs.getDouble("reliabilityScore"));
        record.setQualityScore(rs.getDouble("qualityScore"));
        record.setOverallScore(rs.getDouble("overallScore"));
        record.setRankPosition(rs.getInt("rankPosition"));
        record.setCreatedAt(rs.getDate("createdAt"));
        return record;
    }

    // Aggregation queries for old system (kept for backward compatibility)
    // These are used by the old MangakaPerformanceService which may still be used elsewhere

    public List<MangakaPopularityData> getPopularityData(long periodId) {
        String sql = "SELECT s.mangakaId, AVG(rr.rankScore) as avgRankScore " +
                     "FROM RankingRecord rr " +
                     "JOIN Series s ON s.id = rr.seriesId " +
                     "WHERE rr.periodId = ? " +
                     "GROUP BY s.mangakaId";
        List<MangakaPopularityData> data = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MangakaPopularityData d = new MangakaPopularityData();
                    d.mangakaId = rs.getLong("mangakaId");
                    d.avgRankScore = rs.getDouble("avgRankScore");
                    data.add(d);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get popularity data", ex);
        }
        return data;
    }

    public List<MangakaReliabilityData> getReliabilityData(long periodId) {
        String sql = "SELECT s.mangakaId, " +
                     "COUNT(CASE WHEN m.submittedAt <= c.submissionDeadline THEN 1 END) as onTimeSubmissions, " +
                     "COUNT(*) as totalSubmissions " +
                     "FROM Manuscript m " +
                     "JOIN Chapter c ON c.id = m.chapterId " +
                     "JOIN Series s ON s.id = c.seriesId " +
                     "WHERE m.submittedAt >= (SELECT startDate FROM RankingPeriod WHERE id = ?) " +
                     "AND m.submittedAt <= (SELECT endDate FROM RankingPeriod WHERE id = ?) " +
                     "GROUP BY s.mangakaId";
        List<MangakaReliabilityData> data = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MangakaReliabilityData d = new MangakaReliabilityData();
                    d.mangakaId = rs.getLong("mangakaId");
                    d.onTimeSubmissions = rs.getInt("onTimeSubmissions");
                    d.totalSubmissions = rs.getInt("totalSubmissions");
                    data.add(d);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get reliability data", ex);
        }
        return data;
    }

    public List<MangakaQualityData> getQualityData(long periodId) {
        String sql = "SELECT s.mangakaId, " +
                     "COUNT(CASE WHEN m.status = 'APPROVED' THEN 1 END) as approvedCount, " +
                     "COUNT(CASE WHEN m.status = 'REJECTED' THEN 1 END) as rejectedCount, " +
                     "COUNT(*) as totalCount, " +
                     "COUNT(DISTINCT a.id) as annotationCount " +
                     "FROM Manuscript m " +
                     "JOIN Chapter c ON c.id = m.chapterId " +
                     "JOIN Series s ON s.id = c.seriesId " +
                     "LEFT JOIN Annotation a ON a.manuscriptId = m.id " +
                     "WHERE m.submittedAt >= (SELECT startDate FROM RankingPeriod WHERE id = ?) " +
                     "AND m.submittedAt <= (SELECT endDate FROM RankingPeriod WHERE id = ?) " +
                     "GROUP BY s.mangakaId";
        List<MangakaQualityData> data = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    MangakaQualityData d = new MangakaQualityData();
                    d.mangakaId = rs.getLong("mangakaId");
                    d.approvedCount = rs.getInt("approvedCount");
                    d.rejectedCount = rs.getInt("rejectedCount");
                    d.totalCount = rs.getInt("totalCount");
                    d.annotationCount = rs.getInt("annotationCount");
                    data.add(d);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get quality data", ex);
        }
        return data;
    }

    public static class MangakaPopularityData {
        public long mangakaId;
        public double avgRankScore;
    }

    public static class MangakaReliabilityData {
        public long mangakaId;
        public int onTimeSubmissions;
        public int totalSubmissions;
    }

    public static class MangakaQualityData {
        public long mangakaId;
        public int approvedCount;
        public int rejectedCount;
        public int totalCount;
        public int annotationCount;
    }
}
