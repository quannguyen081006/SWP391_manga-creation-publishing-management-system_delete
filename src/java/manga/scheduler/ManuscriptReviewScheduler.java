package manga.scheduler;

import manga.model.ManuscriptSummary;
import manga.repository.ManuscriptRepository;
import manga.repository.PageTaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.util.Calendar;
import java.util.List;

@Component
public class ManuscriptReviewScheduler {

    @Autowired
    private ManuscriptRepository manuscriptRepository;

    @Autowired
    private PageTaskRepository pageTaskRepository;

    // Run every hour to check for approaching deadlines and overdue reviews
    @Scheduled(cron = "0 0 * * * *")
    public void checkReviewDeadlines() {
        Timestamp now = new Timestamp(System.currentTimeMillis());
        // Get all manuscripts that need checking
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listManuscriptsNeedingReviewReminder();
        
        for (ManuscriptSummary manuscript : manuscripts) {
            if (manuscript.getSubmittedAt() == null) {
                continue;
            }
            
            long tantouId = manuscriptRepository.getManuscriptTantou(manuscript.getId());
            Calendar cal = Calendar.getInstance();
            cal.setTimeInMillis(manuscript.getSubmittedAt().getTime());
            cal.add(Calendar.HOUR, 36);
            Timestamp reminderAt = new Timestamp(cal.getTimeInMillis());
            
            if (!now.before(reminderAt)) {
                pageTaskRepository.createNotificationIfAbsentToday(
                    tantouId,
                    "MANUSCRIPT_REVIEW_REMINDER",
                    "Reminder: Manuscript #" + manuscript.getId() + " has been waiting for review for 36 hours.",
                    manuscript.getId(),
                    "MANUSCRIPT"
                );
            }
            
            // Detect overdue reviews
            if (manuscript.getReviewDeadline() != null && manuscript.getReviewDeadline().before(now)) {
                pageTaskRepository.createNotificationIfAbsentToday(
                    tantouId,
                    "MANUSCRIPT_REVIEW_OVERDUE",
                    "OVERDUE: Manuscript #" + manuscript.getId() + " review was due on " + manuscript.getReviewDeadline() + ". Please complete review immediately.",
                    manuscript.getId(),
                    "MANUSCRIPT"
                );
            }
        }
    }
}
