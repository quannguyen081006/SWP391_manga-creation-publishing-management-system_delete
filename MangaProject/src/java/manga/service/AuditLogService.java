package manga.service;

import manga.model.AuthenticatedUser;
import manga.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuditLogService {

    @Autowired
    private AuditLogRepository auditLogRepository;

    public void append(AuthenticatedUser actor, String action, String entityType, long entityId, String detail) {
        Long actorId = actor == null ? null : Long.valueOf(actor.getId());
        auditLogRepository.append(actorId, action, entityType, entityId, detail);
    }

    public String jsonPair(String key, String value) {
        return "{\"" + escape(key) + "\":\"" + escape(value) + "\"}";
    }

    public String jsonTwoPairs(String key1, String value1, String key2, String value2) {
        return "{\"" + escape(key1) + "\":\"" + escape(value1) + "\",\"" + escape(key2) + "\":\"" + escape(value2) + "\"}";
    }

    private String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
