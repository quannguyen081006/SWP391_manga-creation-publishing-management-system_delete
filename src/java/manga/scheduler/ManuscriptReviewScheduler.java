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
        Calendar cal = Calendar.getInstance();
        
        // Check for manuscripts due in 6 hours (reminder)
        cal.add(Calendar.HOUR, 6);
        Timestamp sixHoursFromNow = new Timestamp(cal.getTimeInMillis());
        
        // Check for overdue manuscripts (past deadline)
        cal = Calendar.getInstance();
        cal.add(Calendar.HOUR, -1);
        Timestamp oneHourAgo = new Timestamp(cal.getTimeInMillis());
        
        // Get all manuscripts that need checking
        List<ManuscriptSummary> manuscripts = manuscriptRepository.listManuscriptsNeedingReviewReminder();
        
        for (ManuscriptSummary manuscript : manuscripts) {
            if (manuscript.getReviewDeadline() == null) {
                continue;
            }
            
            long tantouId = manuscriptRepository.getManuscriptTantou(manuscript.getId());
            
            // Reminder before 48h SLA expires (send at 6 hours remaining)
            if (manuscript.getReviewDeadline().after(now) && 
                manuscript.getReviewDeadline().before(sixHoursFromNow)) {
                pageTaskRepository.createNotificationIfAbsentToday(
                    tantouId,
                    "MANUSCRIPT_REVIEW_REMINDER",
                    "Reminder: Manuscript #" + manuscript.getId() + " review deadline in 6 hours. Please complete review by " + manuscript.getReviewDeadline(),
                    manuscript.getId(),
                    "MANUSCRIPT"
                );
            }
            
            // Detect overdue reviews
            if (manuscript.getReviewDeadline().before(now)) {
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
