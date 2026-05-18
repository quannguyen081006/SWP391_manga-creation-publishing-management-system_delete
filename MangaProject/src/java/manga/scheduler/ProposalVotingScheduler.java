package manga.scheduler;

import manga.repository.ProposalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class ProposalVotingScheduler {

    @Autowired
    private ProposalRepository proposalRepository;

    @Scheduled(cron = "0 0 */2 * * *")
    public void autoResolveExpiredVoting() {
        proposalRepository.resolveExpiredVotings();
    }
}
