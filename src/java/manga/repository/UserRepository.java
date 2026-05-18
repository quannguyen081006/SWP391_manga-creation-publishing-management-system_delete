package manga.repository;

import manga.model.AuthenticatedUser;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

@Repository
public class UserRepository {

    @Autowired
    private DataSource dataSource;

    public AuthenticatedUser findByUsername(String username) {
        String sql = "SELECT id, username, passwordHash, fullName, status FROM [User] WHERE username = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                AuthenticatedUser user = new AuthenticatedUser();
                user.setId(rs.getLong("id"));
                user.setUsername(rs.getString("username"));
                user.setPasswordHash(rs.getString("passwordHash"));
                user.setFullName(rs.getString("fullName"));
                user.setStatus(rs.getString("status"));
                loadRoles(conn, user);
                return user;
            }
        } catch (SQLException ex) {
            throw new RuntimeException("Cannot load user by username", ex);
        }
    }

    private void loadRoles(Connection conn, AuthenticatedUser user) throws SQLException {
        String sql = "SELECT r.name FROM UserRole ur JOIN [Role] r ON ur.roleId = r.id WHERE ur.userId = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, user.getId());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    user.addRole(rs.getString("name"));
                }
            }
        }
    }
}


