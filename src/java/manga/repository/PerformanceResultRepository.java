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
public class PerformanceResultRepository {

    @Autowired
    private DataSource dataSource;

    public void saveResult(long periodId, long mangakaId, double overallScore, 
                          double popularityScore, double reliabilityScore, double qualityScore,
                          int overallRank, int popularityRank, int reliabilityRank, int qualityRank) {
        String sql = "INSERT INTO PerformanceResult (periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            ps.setDouble(3, overallScore);
            ps.setDouble(4, popularityScore);
            ps.setDouble(5, reliabilityScore);
            ps.setDouble(6, qualityScore);
            ps.setInt(7, overallRank);
            ps.setInt(8, popularityRank);
            ps.setInt(9, reliabilityRank);
            ps.setInt(10, qualityRank);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot save performance result", ex);
        }
    }

    public List<Map<String, Object>> getResultsByPeriod(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, " +
                     "overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt " +
                     "FROM PerformanceResult WHERE periodId = ? ORDER BY overallRank";
        List<Map<String, Object>> results = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapResult(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get results by period", ex);
        }
        return results;
    }

    public List<Map<String, Object>> getResultsByPeriodOrderByPopularity(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, " +
                     "overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt " +
                     "FROM PerformanceResult WHERE periodId = ? ORDER BY popularityRank";
        List<Map<String, Object>> results = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapResult(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get results by period ordered by popularity", ex);
        }
        return results;
    }

    public List<Map<String, Object>> getResultsByPeriodOrderByReliability(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, " +
                     "overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt " +
                     "FROM PerformanceResult WHERE periodId = ? ORDER BY reliabilityRank";
        List<Map<String, Object>> results = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapResult(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get results by period ordered by reliability", ex);
        }
        return results;
    }

    public List<Map<String, Object>> getResultsByPeriodOrderByQuality(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, " +
                     "overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt " +
                     "FROM PerformanceResult WHERE periodId = ? ORDER BY qualityRank";
        List<Map<String, Object>> results = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    results.add(mapResult(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get results by period ordered by quality", ex);
        }
        return results;
    }

    public Map<String, Object> getResultByMangaka(long periodId, long mangakaId) {
        String sql = "SELECT id, periodId, mangakaId, overallScore, popularityScore, reliabilityScore, qualityScore, " +
                     "overallRank, popularityRank, reliabilityRank, qualityRank, calculatedAt " +
                     "FROM PerformanceResult WHERE periodId = ? AND mangakaId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResult(rs);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get result by mangaka", ex);
        }
        return null;
    }

    public void deleteResultsByPeriod(long periodId) {
        String sql = "DELETE FROM PerformanceResult WHERE periodId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot delete results by period", ex);
        }
    }

    public boolean hasResultsForPeriod(long periodId) {
        String sql = "SELECT COUNT(1) FROM PerformanceResult WHERE periodId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check results for period", ex);
        }
        return false;
    }

    private Map<String, Object> mapResult(ResultSet rs) throws SQLException {
        Map<String, Object> result = new HashMap<>();
        result.put("id", rs.getLong("id"));
        result.put("periodId", rs.getLong("periodId"));
        result.put("mangakaId", rs.getLong("mangakaId"));
        result.put("overallScore", rs.getBigDecimal("overallScore"));
        result.put("popularityScore", rs.getBigDecimal("popularityScore"));
        result.put("reliabilityScore", rs.getBigDecimal("reliabilityScore"));
        result.put("qualityScore", rs.getBigDecimal("qualityScore"));
        result.put("overallRank", rs.getInt("overallRank"));
        result.put("popularityRank", rs.getInt("popularityRank"));
        result.put("reliabilityRank", rs.getInt("reliabilityRank"));
        result.put("qualityRank", rs.getInt("qualityRank"));
        result.put("calculatedAt", rs.getTimestamp("calculatedAt"));
        return result;
    }
}
