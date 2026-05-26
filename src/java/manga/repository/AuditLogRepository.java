package manga.repository;

import manga.model.AuditLogItem;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class AuditLogRepository {

    @Autowired
    private DataSource dataSource;

    public void append(Long actorId, String action, String entityType, long entityId, String detail) {
        String sql = "INSERT INTO AuditLog (actorId, action, entityType, entityId, detail, performedAt) VALUES (?, ?, ?, ?, ?, GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (actorId == null) {
                ps.setNull(1, java.sql.Types.BIGINT);
            } else {
                ps.setLong(1, actorId.longValue());
            }
            ps.setString(2, action);
            ps.setString(3, entityType);
            ps.setLong(4, entityId);
            ps.setString(5, detail);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot append audit log", ex);
        }
    }

    public List<AuditLogItem> list(int limit) {
        String sql = "SELECT TOP (?) id, actorId, action, entityType, entityId, detail, performedAt FROM AuditLog ORDER BY performedAt DESC";
        List<AuditLogItem> rows = new ArrayList<AuditLogItem>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load audit logs", ex);
        }
        return rows;
    }

    public List<AuditLogItem> search(Integer actorId, String action, String entityType, int limit) {
        StringBuilder sql = new StringBuilder("SELECT TOP (?) id, actorId, action, entityType, entityId, detail, performedAt FROM AuditLog WHERE 1 = 1");
        List<Object> params = new ArrayList<Object>();
        params.add(limit);

        if (actorId != null) {
            sql.append(" AND actorId = ?");
            params.add(actorId);
        }
        if (!isBlank(action)) {
            sql.append(" AND action LIKE ?");
            params.add("%" + action.trim().toUpperCase() + "%");
        }
        if (!isBlank(entityType)) {
            sql.append(" AND entityType = ?");
            params.add(entityType.trim().toUpperCase());
        }
        sql.append(" ORDER BY performedAt DESC");

        List<AuditLogItem> rows = new ArrayList<AuditLogItem>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object param = params.get(i);
                if (param instanceof Integer) {
                    ps.setInt(i + 1, ((Integer) param).intValue());
                } else {
                    ps.setString(i + 1, String.valueOf(param));
                }
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot search audit logs", ex);
        }
        return rows;
    }

    public AuditLogItem findById(long id) {
        String sql = "SELECT id, actorId, action, entityType, entityId, detail, performedAt FROM AuditLog WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Audit log not found");
                }
                return map(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load audit log", ex);
        }
    }

    public List<AuditLogItem> listByEntity(String entityType, long entityId) {
        String sql = "SELECT id, actorId, action, entityType, entityId, detail, performedAt "
                + "FROM AuditLog WHERE entityType = ? AND entityId = ? ORDER BY performedAt DESC";
        List<AuditLogItem> rows = new ArrayList<AuditLogItem>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, entityType);
            ps.setLong(2, entityId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(map(rs));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load audit logs by entity", ex);
        }
        return rows;
    }


    public List<String> listActions() {
        String sql = "SELECT DISTINCT action FROM AuditLog WHERE action IS NOT NULL ORDER BY action";
        List<String> actions = new ArrayList<String>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                actions.add(rs.getString("action"));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load audit actions", ex);
        }
        return actions;
    }

    private AuditLogItem map(ResultSet rs) throws SQLException {
        AuditLogItem a = new AuditLogItem();
        a.setId(rs.getLong("id"));
        long actorId = rs.getLong("actorId");
        a.setActorId(rs.wasNull() ? null : actorId);
        a.setAction(rs.getString("action"));
        a.setEntityType(rs.getString("entityType"));
        a.setEntityId(rs.getLong("entityId"));
        a.setDetail(rs.getString("detail"));
        a.setPerformedAt(rs.getTimestamp("performedAt"));
        return a;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}


