package manga.scheduler;

import manga.repository.PageTaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class TaskOverdueScheduler {

    @Autowired
    private PageTaskRepository pageTaskRepository;

    @Scheduled(cron = "0 */30 * * * *")
    public void markOverdueTasks() {
        pageTaskRepository.markOverdueTasks();
    }
}
