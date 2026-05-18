package manga.scheduler;

import manga.repository.ChapterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class ChapterDeadlineScheduler {

    @Autowired
    private ChapterRepository chapterRepository;

    @Scheduled(cron = "0 30 */2 * * *")
    public void refreshChapterAtRisk() {
        chapterRepository.refreshAtRiskFlags();
    }
}
