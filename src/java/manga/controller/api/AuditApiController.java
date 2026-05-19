package manga.controller.api;

import manga.repository.AuditLogRepository;
import manga.common.ApiResponse;
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

    @RequestMapping(method = RequestMethod.GET)
    public ApiResponse<List<AuditLogItem>> list(
            HttpSession session,
            @RequestParam(value = "limit", defaultValue = "100") int limit) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can view audit logs");
        return ApiResponse.ok(auditLogRepository.list(limit), "Audit logs");
    }

    @RequestMapping(value = "/{id}", method = RequestMethod.GET)
    public ApiResponse<AuditLogItem> detail(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ADMIN", "Only ADMIN can view audit logs");
        return ApiResponse.ok(auditLogRepository.findById(id), "Audit log detail");
    }
}




