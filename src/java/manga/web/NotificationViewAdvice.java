package manga.web;

import manga.model.AuthenticatedUser;
import manga.model.NotificationItem;
import manga.repository.NotificationRepository;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice(annotations = Controller.class)
public class NotificationViewAdvice {

    @Autowired
    private NotificationRepository notificationRepository;

    @ModelAttribute("headerUnreadNotificationCount")
    public int unreadCount(HttpSession session) {
        AuthenticatedUser user = getUser(session);
        if (user == null) {
            return 0;
        }
        List<NotificationItem> all = notificationRepository.listByUser(user.getId());
        int unread = 0;
        for (NotificationItem item : all) {
            if (!item.isRead()) {
                unread++;
            }
        }
        return unread;
    }

    @ModelAttribute("headerNotifications")
    public List<NotificationItem> latestNotifications(HttpSession session) {
        AuthenticatedUser user = getUser(session);
        if (user == null) {
            return new ArrayList<NotificationItem>();
        }
        List<NotificationItem> all = notificationRepository.listByUser(user.getId());
        int size = Math.min(all.size(), 5);
        return new ArrayList<NotificationItem>(all.subList(0, size));
    }

    private AuthenticatedUser getUser(HttpSession session) {
        if (session == null) {
            return null;
        }
        Object raw = session.getAttribute("AUTH_USER");
        if (!(raw instanceof AuthenticatedUser)) {
            return null;
        }
        return (AuthenticatedUser) raw;
    }
}
