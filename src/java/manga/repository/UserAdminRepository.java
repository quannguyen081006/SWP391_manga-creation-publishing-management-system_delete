package manga.repository;

import manga.model.AuthenticatedUser;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class UserAdminRepository {

    @Autowired
    private DataSource dataSource;

    public List<Map<String, Object>> listUsers() {
        String sql = "SELECT id, username, fullName, email, status, createdAt, updatedAt FROM [User] ORDER BY id";
        List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rows.add(toMap(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot list users", ex);
        }
        return rows;
    }

    public Map<String, Object> getUser(long id) {
        String sql = "SELECT id, username, fullName, email, status, createdAt, updatedAt FROM [User] WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                return toMap(rs);
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load user", ex);
        }
    }

    public long createUser(String username, String passwordHash, String fullName, String email) {
        String sql = "INSERT INTO [User] (username, passwordHash, fullName, email, status, createdAt, updatedAt) VALUES (?, ?, ?, ?, 'ACTIVE', GETDATE(), GETDATE())";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, username);
            ps.setString(2, passwordHash);
            ps.setString(3, fullName);
            ps.setString(4, email);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
            throw new IllegalStateException("Cannot create user");
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot create user", ex);
        }
    }

    public void updateUser(long id, String fullName, String email) {
        String sql = "UPDATE [User] SET fullName = ?, email = ?, updatedAt = GETDATE() WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fullName);
            ps.setString(2, email);
            ps.setLong(3, id);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("User not found");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update user", ex);
        }
    }

    public void updateStatus(long id, String status) {
        String sql = "UPDATE [User] SET status = ?, updatedAt = GETDATE() WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setLong(2, id);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("User not found");
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot update status", ex);
        }
    }

    public void addRole(long userId, String roleName) {
        String roleSql = "SELECT id FROM [Role] WHERE name = ?";
        String insertSql = "INSERT INTO UserRole (userId, roleId) VALUES (?, ?)";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement rolePs = conn.prepareStatement(roleSql)) {
            rolePs.setString(1, roleName);
            long roleId;
            try (ResultSet rs = rolePs.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Role not found");
                }
                roleId = rs.getLong(1);
            }
            try (PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
                insertPs.setLong(1, userId);
                insertPs.setLong(2, roleId);
                insertPs.executeUpdate();
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot add role", ex);
        }
    }

    private Map<String, Object> toMap(ResultSet rs) throws SQLException {
        Map<String, Object> row = new HashMap<String, Object>();
        row.put("id", rs.getLong("id"));
        row.put("username", rs.getString("username"));
        row.put("fullName", rs.getString("fullName"));
        row.put("email", rs.getString("email"));
        row.put("status", rs.getString("status"));
        row.put("createdAt", rs.getTimestamp("createdAt"));
        row.put("updatedAt", rs.getTimestamp("updatedAt"));
        return row;
    }
}



