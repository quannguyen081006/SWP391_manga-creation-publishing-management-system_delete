package manga.repository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class PerformancePeriodRepository {

    @Autowired
    private DataSource dataSource;

    public long createPeriod(String name, Date startDate, Date endDate) {
        String sql = "INSERT INTO PerformancePeriod (name, startDate, endDate, status) VALUES (?, ?, ?, 'OPEN')";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.setDate(2, startDate);
            ps.setDate(3, endDate);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot create performance period");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create performance period", ex);
        }
    }

    public List<Map<String, Object>> listPeriods() {
        String sql = "SELECT id, name, startDate, endDate, status, createdAt, calculatedAt FROM PerformancePeriod ORDER BY id DESC";
        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(mapPeriod(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list performance periods", ex);
        }
        return rows;
    }

    public Map<String, Object> findPeriodById(long periodId) {
        String sql = "SELECT id, name, startDate, endDate, status, createdAt, calculatedAt FROM PerformancePeriod WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Performance period not found");
                }
                return mapPeriod(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load performance period", ex);
        }
    }

    public void closePeriod(long periodId) {
        String sql = "UPDATE PerformancePeriod SET status = 'CLOSED' WHERE id = ? AND status = 'OPEN'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only OPEN period can be closed");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot close performance period", ex);
        }
    }

    public void markAsCalculated(long periodId) {
        String sql = "UPDATE PerformancePeriod SET status = 'CALCULATED', calculatedAt = GETDATE() WHERE id = ? AND status = 'CLOSED'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only CLOSED period can be marked as calculated");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot mark performance period as calculated", ex);
        }
    }

    private Map<String, Object> mapPeriod(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<>();
        row.put("id", rs.getLong("id"));
        row.put("name", rs.getString("name"));
        row.put("startDate", rs.getDate("startDate"));
        row.put("endDate", rs.getDate("endDate"));
        row.put("status", rs.getString("status"));
        row.put("createdAt", rs.getTimestamp("createdAt"));
        row.put("calculatedAt", rs.getTimestamp("calculatedAt"));
        return row;
    }
}
