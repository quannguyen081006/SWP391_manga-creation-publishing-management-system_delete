package manga.controller.api;

import manga.repository.AuditLogRepository;
import manga.common.util.SessionUserUtil;
import manga.model.AuditLogItem;
import manga.model.AuthenticatedUser;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/audit-logs")
public class AuditApiController {

    @Autowired
    private AuditLogRepository auditLogRepository;

    @RequestMapping(method = RequestMethod.GET, produces = "application/json;charset=UTF-8")
    public String list(
            HttpSession session,
            @RequestParam(value = "limit", defaultValue = "100") int limit) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can view audit logs");
        return ok(auditLogRepository.list(limit), "Audit logs");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.GET, produces = "application/json;charset=UTF-8")
    public String detail(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can view audit logs");
        return ok(auditLogRepository.findById(id), "Audit log detail");
    }

    private String ok(List<AuditLogItem> items, String message) {
        StringBuilder builder = new StringBuilder();
        builder.append("{\"success\":true,\"message\":").append(json(message)).append(",\"data\":[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) {
                builder.append(",");
            }
            appendItem(builder, items.get(i));
        }
        builder.append("]}");
        return builder.toString();
    }

    private String ok(AuditLogItem item, String message) {
        StringBuilder builder = new StringBuilder();
        builder.append("{\"success\":true,\"message\":").append(json(message)).append(",\"data\":");
        if (item == null) {
            builder.append("null");
        } else {
            appendItem(builder, item);
        }
        builder.append("}");
        return builder.toString();
    }

    private void appendItem(StringBuilder builder, AuditLogItem item) {
        builder.append("{");
        builder.append("\"id\":").append(item.getId()).append(",");
        builder.append("\"actorId\":").append(item.getActorId() == null ? "null" : item.getActorId()).append(",");
        builder.append("\"action\":").append(json(item.getAction())).append(",");
        builder.append("\"entityType\":").append(json(item.getEntityType())).append(",");
        builder.append("\"entityId\":").append(item.getEntityId()).append(",");
        builder.append("\"detail\":").append(json(item.getDetail())).append(",");
        builder.append("\"performedAt\":").append(json(item.getPerformedAt() == null ? null : item.getPerformedAt().toString()));
        builder.append("}");
    }

    private String json(String value) {
        if (value == null) {
            return "null";
        }
        StringBuilder builder = new StringBuilder("\"");
        for (int i = 0; i < value.length(); i++) {
            char ch = value.charAt(i);
            switch (ch) {
                case '"':
                    builder.append("\\\"");
                    break;
                case '\\':
                    builder.append("\\\\");
                    break;
                case '\b':
                    builder.append("\\b");
                    break;
                case '\f':
                    builder.append("\\f");
                    break;
                case '\n':
                    builder.append("\\n");
                    break;
                case '\r':
                    builder.append("\\r");
                    break;
                case '\t':
                    builder.append("\\t");
                    break;
                default:
                    if (ch < 32) {
                        String hex = Integer.toHexString(ch);
                        builder.append("\\u");
                        for (int j = hex.length(); j < 4; j++) {
                            builder.append("0");
                        }
                        builder.append(hex);
                    } else {
                        builder.append(ch);
                    }
                    break;
            }
        }
        builder.append("\"");
        return builder.toString();
    }
}




