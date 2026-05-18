package manga.service;

import manga.model.AuthenticatedUser;
import manga.repository.UserAdminRepository;
import manga.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserAdminRepository userAdminRepository;

    public AuthenticatedUser login(String username, String password) {
        if (username != null) {
            ensureTestingAccountExists(username.trim());
        }

        AuthenticatedUser user = userRepository.findByUsername(username);
        if (user == null) {
            throw new IllegalArgumentException("Username or password is incorrect");
        }
        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new IllegalArgumentException("This account is inactive");
        }

        if (password == null || !password.equals(user.getPasswordHash())) {
            throw new IllegalArgumentException("Username or password is incorrect");
        }

        return user;
    }

    // DEV_SWITCH_ROLE: temporary quick switch helper for testing accounts.
    public AuthenticatedUser switchUserForTesting(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Username is required for switch role");
        }

        String normalized = username.trim();
        ensureTestingAccountExists(normalized);

        AuthenticatedUser user = userRepository.findByUsername(normalized);
        if (user == null) {
            throw new IllegalArgumentException("User not found: " + username);
        }
        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new IllegalArgumentException("Cannot switch to inactive account");
        }
        return user;
    }

    private void ensureTestingAccountExists(String username) {
        if (username == null || username.isEmpty()) {
            return;
        }
        if (userRepository.findByUsername(username) != null) {
            return;
        }

        String role;
        String fullName;
        if ("admin".equalsIgnoreCase(username)) {
            role = "ADMIN";
            fullName = "System Admin";
        } else if ("mangaka1".equalsIgnoreCase(username)) {
            role = "MANGAKA";
            fullName = "Yuki Tanaka";
        } else if ("assistant1".equalsIgnoreCase(username)) {
            role = "ASSISTANT";
            fullName = "Aiko Mori";
        } else if ("tantou1".equalsIgnoreCase(username)) {
            role = "TANTOU_EDITOR";
            fullName = "Hiroshi Yamamoto";
        } else if (username.toLowerCase().matches("board[1-5]")) {
            role = "EDITORIAL_BOARD";
            fullName = "Board Member " + username.substring(username.length() - 1);
        } else {
            return;
        }

        String email = username.toLowerCase() + "@mangaflow.local";
        try {
            long userId = userAdminRepository.createUser(username, "12345", fullName, email);
            userAdminRepository.addRole(userId, role);
        } catch (RuntimeException ignored) {
            // Ignore duplicate-create races for testing helper.
        }
    }
}
