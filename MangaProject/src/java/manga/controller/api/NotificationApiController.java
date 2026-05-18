package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.NotificationItem;
import manga.repository.NotificationRepository;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationApiController {

    @Autowired
    private NotificationRepository notificationRepository;

    @RequestMapping(method = RequestMethod.GET)
    public ApiResponse<List<NotificationItem>> list(HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        return ApiResponse.ok(notificationRepository.listByUser(user.getId()), "Notifications");
    }

    @RequestMapping(value = "/{id}/read", method = RequestMethod.PATCH)
    public ApiResponse<Object> markRead(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        notificationRepository.markRead(user.getId(), id);
        return ApiResponse.ok(null, "Notification marked as read");
    }

    @RequestMapping(value = "/mark-all-read", method = RequestMethod.POST)
    public ApiResponse<Object> markAllRead(HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        notificationRepository.markAllRead(user.getId());
        return ApiResponse.ok(null, "All notifications marked as read");
    }
}





