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
public class PerformanceImportRecordRepository {

    @Autowired
    private DataSource dataSource;

    public void saveImportRecord(long periodId, long mangakaId, double popularityScore, 
                                  double reliabilityScore, double qualityScore) {
        String sql = "INSERT INTO PerformanceImportRecord (periodId, mangakaId, popularityScore, reliabilityScore, qualityScore, createdAt) " +
                     "VALUES (?, ?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            ps.setDouble(3, popularityScore);
            ps.setDouble(4, reliabilityScore);
            ps.setDouble(5, qualityScore);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot save performance import record", ex);
        }
    }

    public List<Map<String, Object>> getImportRecordsByPeriod(long periodId) {
        String sql = "SELECT id, periodId, mangakaId, popularityScore, reliabilityScore, qualityScore, createdAt " +
                     "FROM PerformanceImportRecord WHERE periodId = ? ORDER BY mangakaId";
        List<Map<String, Object>> records = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> record = new HashMap<>();
                    record.put("id", rs.getLong("id"));
                    record.put("periodId", rs.getLong("periodId"));
                    record.put("mangakaId", rs.getLong("mangakaId"));
                    record.put("popularityScore", rs.getDouble("popularityScore"));
                    record.put("reliabilityScore", rs.getDouble("reliabilityScore"));
                    record.put("qualityScore", rs.getDouble("qualityScore"));
                    record.put("createdAt", rs.getTimestamp("createdAt"));
                    records.add(record);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot get import records", ex);
        }
        return records;
    }

    public void deleteImportRecordsByPeriod(long periodId) {
        String sql = "DELETE FROM PerformanceImportRecord WHERE periodId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot delete import records", ex);
        }
    }

    public int countImportRecordsByPeriod(long periodId) {
        String sql = "SELECT COUNT(*) FROM PerformanceImportRecord WHERE periodId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot count import records", ex);
        }
        return 0;
    }

    public boolean hasImportRecord(long periodId, long mangakaId) {
        String sql = "SELECT COUNT(1) FROM PerformanceImportRecord WHERE periodId = ? AND mangakaId = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            ps.setLong(2, mangakaId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot check import record", ex);
        }
        return false;
    }
}
