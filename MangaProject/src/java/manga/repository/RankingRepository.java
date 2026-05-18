package manga.repository;

import java.sql.Connection;
import java.sql.Date;
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
public class RankingRepository {

    @Autowired
    private DataSource dataSource;

    public List<Map<String, Object>> listPeriods() {
        String sql = "SELECT id, name, startDate, endDate, status, calculatedAt FROM RankingPeriod ORDER BY id DESC";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(mapPeriod(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list ranking periods", ex);
        }
        return rows;
    }

    public Map<String, Object> findPeriodById(long periodId) {
        String sql = "SELECT id, name, startDate, endDate, status, calculatedAt FROM RankingPeriod WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Ranking period not found");
                }
                return mapPeriod(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load ranking period", ex);
        }
    }

    public long createPeriod(String name, Date startDate, Date endDate) {
        String sql = "INSERT INTO RankingPeriod (name, startDate, endDate, status) VALUES (?, ?, ?, 'OPEN')";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);
            ps.setDate(2, startDate);
            ps.setDate(3, endDate);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot create ranking period");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create ranking period", ex);
        }
    }

    public void closePeriod(long periodId) {
        String sql = "UPDATE RankingPeriod SET status = 'CLOSED' WHERE id = ? AND status = 'OPEN'";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Only OPEN period can be closed");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot close ranking period", ex);
        }
    }

    public void submitEntry(long periodId, long seriesId, long boardMemberId, int voteCount, int readerCount) {
        if (voteCount < 0) {
            throw new IllegalArgumentException("voteCount must be >= 0");
        }
        if (readerCount <= 0) {
            throw new IllegalArgumentException("readerCount must be > 0");
        }

        String periodStatusSql = "SELECT status FROM RankingPeriod WHERE id = ?";
        String upsertSql =
            "MERGE VoteEntry AS target "
            + "USING (SELECT ? AS periodId, ? AS seriesId, ? AS boardMemberId) AS src "
            + "ON target.periodId = src.periodId AND target.seriesId = src.seriesId AND target.boardMemberId = src.boardMemberId "
            + "WHEN MATCHED THEN UPDATE SET voteCount = ?, readerCount = ?, submittedAt = GETDATE() "
            + "WHEN NOT MATCHED THEN INSERT (periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt) VALUES (?, ?, ?, ?, ?, GETDATE());";

        try (Connection conn = dataSource.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(periodStatusSql)) {
                ps.setLong(1, periodId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Ranking period not found");
                    }
                    if (!"OPEN".equalsIgnoreCase(rs.getString("status"))) {
                        throw new IllegalArgumentException("Vote entries can be submitted only when period is OPEN");
                    }
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
                ps.setLong(1, periodId);
                ps.setLong(2, seriesId);
                ps.setLong(3, boardMemberId);
                ps.setInt(4, voteCount);
                ps.setInt(5, readerCount);
                ps.setLong(6, periodId);
                ps.setLong(7, seriesId);
                ps.setLong(8, boardMemberId);
                ps.setInt(9, voteCount);
                ps.setInt(10, readerCount);
                ps.executeUpdate();
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot submit vote entry", ex);
        }
    }

    public List<Map<String, Object>> listEntries(long periodId) {
        String sql = "SELECT id, periodId, seriesId, boardMemberId, voteCount, readerCount, submittedAt FROM VoteEntry WHERE periodId = ? ORDER BY id DESC";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<String, Object>();
                    row.put("id", rs.getLong("id"));
                    row.put("periodId", rs.getLong("periodId"));
                    row.put("seriesId", rs.getLong("seriesId"));
                    row.put("boardMemberId", rs.getLong("boardMemberId"));
                    row.put("voteCount", rs.getInt("voteCount"));
                    row.put("readerCount", rs.getInt("readerCount"));
                    row.put("submittedAt", rs.getTimestamp("submittedAt"));
                    rows.add(row);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list vote entries", ex);
        }
        return rows;
    }

    public void calculatePeriod(long periodId) {
        String statusSql = "SELECT status FROM RankingPeriod WHERE id = ?";
        String deleteSql = "DELETE FROM RankingRecord WHERE periodId = ?";
        String insertSql =
            ";WITH agg AS ("
            + " SELECT ve.seriesId, CAST((SUM(CAST(ve.voteCount AS DECIMAL(18,6))) / NULLIF(SUM(CAST(ve.readerCount AS DECIMAL(18,6))), 0)) * 100 AS DECIMAL(6,2)) AS rankScore"
            + " FROM VoteEntry ve WHERE ve.periodId = ? GROUP BY ve.seriesId"
            + "), ranked AS ("
            + " SELECT seriesId, rankScore, ROW_NUMBER() OVER (ORDER BY rankScore DESC, seriesId ASC) AS rankPosition, COUNT(*) OVER () AS totalRows"
            + " FROM agg"
            + ")"
            + " INSERT INTO RankingRecord (periodId, seriesId, rankScore, rankPosition, isBottomTwenty, calculatedAt)"
            + " SELECT ?, r.seriesId, r.rankScore, r.rankPosition,"
            + " CASE WHEN r.rankPosition > CEILING(r.totalRows * 0.8) THEN 1 ELSE 0 END, GETDATE()"
            + " FROM ranked r";
        String updateSql = "UPDATE RankingPeriod SET status = 'CALCULATED', calculatedAt = GETDATE() WHERE id = ?";

        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                    ps.setLong(1, periodId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("Ranking period not found");
                        }
                        String status = rs.getString("status");
                        if ("CALCULATED".equalsIgnoreCase(status)) {
                            throw new IllegalArgumentException("Ranking period already calculated");
                        }
                        if (!"CLOSED".equalsIgnoreCase(status)) {
                            throw new IllegalArgumentException("Only CLOSED period can be calculated");
                        }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                    ps.setLong(1, periodId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setLong(1, periodId);
                    ps.setLong(2, periodId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                    ps.setLong(1, periodId);
                    ps.executeUpdate();
                }

                conn.commit();
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot calculate ranking period", ex);
        }
    }

    public List<Map<String, Object>> results(long periodId) {
        String sql = "SELECT id, periodId, seriesId, rankScore, rankPosition, isBottomTwenty, calculatedAt FROM RankingRecord WHERE periodId = ? ORDER BY rankPosition";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, periodId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<String, Object>();
                    row.put("id", rs.getLong("id"));
                    row.put("periodId", rs.getLong("periodId"));
                    row.put("seriesId", rs.getLong("seriesId"));
                    row.put("rankScore", rs.getBigDecimal("rankScore"));
                    row.put("rankPosition", rs.getInt("rankPosition"));
                    row.put("isBottomTwenty", rs.getBoolean("isBottomTwenty"));
                    row.put("calculatedAt", rs.getTimestamp("calculatedAt"));
                    rows.add(row);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load ranking results", ex);
        }
        return rows;
    }

    private Map<String, Object> mapPeriod(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<String, Object>();
        row.put("id", rs.getLong("id"));
        row.put("name", rs.getString("name"));
        row.put("startDate", rs.getDate("startDate"));
        row.put("endDate", rs.getDate("endDate"));
        row.put("status", rs.getString("status"));
        row.put("calculatedAt", rs.getTimestamp("calculatedAt"));
        return row;
    }
}


