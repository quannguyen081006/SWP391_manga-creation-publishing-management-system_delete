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
}


