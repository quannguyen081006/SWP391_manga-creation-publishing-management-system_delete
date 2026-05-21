package manga.service;

import manga.common.exception.BusinessRuleException;
import manga.dto.CreateRankingPeriodRequest;
import manga.dto.SubmitVoteEntryRequest;
import manga.enums.RankingPeriodStatus;
import manga.model.AuthenticatedUser;
import manga.repository.RankingRepository;
import manga.service.NotificationService;
import manga.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Date;
import java.util.List;
import java.util.Map;

@Service
public class RankingService {

    @Autowired
    private RankingRepository rankingRepository;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private AuditLogService auditLogService;

    public List<Map<String, Object>> listPeriods() {
        return rankingRepository.listPeriods();
    }

    public Map<String, Object> getPeriodById(long periodId) {
        return rankingRepository.findPeriodById(periodId);
    }

    public long createRankingPeriod(CreateRankingPeriodRequest request, AuthenticatedUser user) {
        // ADMIN only
        if (!user.hasRole("ADMIN")) {
            throw new BusinessRuleException("Only ADMIN can create ranking period");
        }

        // Validate dates
        if (request.getStartDate() == null || request.getEndDate() == null) {
            throw new BusinessRuleException("Start date and end date are required");
        }

        if (request.getStartDate().after(request.getEndDate())) {
            throw new BusinessRuleException("Start date must be before end date");
        }

        long periodId = rankingRepository.createPeriod(request.getName(), request.getStartDate(), request.getEndDate());

        // Audit log
        auditLogService.append(user, "CREATE_RANKING_PERIOD", "RANKING_PERIOD", periodId, 
            "Created ranking period: " + request.getName());

        // Notify Editorial Board
        notificationService.notifyUser(
            user.getId(), // In real implementation, would notify all Editorial Board members
            "RANKING_PERIOD_OPENED",
            "New ranking period '" + request.getName() + "' is now open for vote submissions.",
            periodId,
            "RANKING_PERIOD"
        );

        return periodId;
    }

    public void closeRankingPeriod(long periodId, AuthenticatedUser user) {
        // ADMIN only
        if (!user.hasRole("ADMIN")) {
            throw new BusinessRuleException("Only ADMIN can close ranking period");
        }

        // Validate period exists and is OPEN
        Map<String, Object> period = rankingRepository.findPeriodById(periodId);
        String status = (String) period.get("status");
        if (!RankingPeriodStatus.OPEN.name().equals(status)) {
            throw new BusinessRuleException("Only OPEN period can be closed (BR-57)");
        }

        rankingRepository.closePeriod(periodId);

        // Audit log
        auditLogService.append(user, "CLOSE_RANKING_PERIOD", "RANKING_PERIOD", periodId, 
            "Closed ranking period");

        // Notify Editorial Board
        notificationService.notifyUser(
            user.getId(),
            "RANKING_PERIOD_CLOSED",
            "Ranking period is now closed. Vote submissions are no longer accepted.",
            periodId,
            "RANKING_PERIOD"
        );
    }

    public void submitVoteEntry(long periodId, SubmitVoteEntryRequest request, AuthenticatedUser user) {
        // Only Editorial Board (BR-53)
        if (!user.hasRole("EDITORIAL_BOARD")) {
            throw new BusinessRuleException("Only EDITORIAL_BOARD can submit vote data (BR-53)");
        }

        // Validate period exists and is OPEN (BR-49)
        Map<String, Object> period = rankingRepository.findPeriodById(periodId);
        String status = (String) period.get("status");
        if (!RankingPeriodStatus.OPEN.name().equals(status)) {
            throw new BusinessRuleException("Vote entry only allowed while period OPEN (BR-49)");
        }

        // Validate voteCount (BR-51)
        if (request.getVoteCount() < 0) {
            throw new BusinessRuleException("voteCount cannot be negative (BR-51)");
        }

        // Validate readerCount (BR-52)
        if (request.getReaderCount() <= 0) {
            throw new BusinessRuleException("readerCount must be > 0 (BR-52)");
        }

        // Validate voteCount <= readerCount (BR-50)
        if (request.getVoteCount() > request.getReaderCount()) {
            throw new BusinessRuleException("voteCount cannot exceed readerCount (BR-50)");
        }

        // Submit entry (repository handles duplicate check BR-54)
        rankingRepository.submitEntry(periodId, request.getSeriesId(), user.getId(), 
            request.getVoteCount(), request.getReaderCount());

        // Audit log
        auditLogService.append(user, "SUBMIT_VOTE_ENTRY", "VOTE_ENTRY", periodId, 
            "Submitted vote entry for series " + request.getSeriesId());
    }

    @Transactional
    public void calculateRanking(long periodId, AuthenticatedUser user) {
        // ADMIN only
        if (!user.hasRole("ADMIN")) {
            throw new BusinessRuleException("Only ADMIN can trigger ranking calculation");
        }

        // Validate period exists and is CLOSED (BR-57)
        Map<String, Object> period = rankingRepository.findPeriodById(periodId);
        String status = (String) period.get("status");
        if (!RankingPeriodStatus.CLOSED.name().equals(status)) {
            throw new BusinessRuleException("Only CLOSED period can be calculated (BR-57)");
        }

        // Calculate ranking (repository handles BR-56, BR-58, bottom 20% logic)
        rankingRepository.calculatePeriod(periodId);

        // Audit log
        auditLogService.append(user, "CALCULATE_RANKING", "RANKING_PERIOD", periodId, 
            "Calculated ranking results");

        // Notification is handled within repository's transaction
    }

    public List<Map<String, Object>> getRankingResults(long periodId, AuthenticatedUser user) {
        // Any authenticated user can view results
        return rankingRepository.results(periodId);
    }

    public List<Map<String, Object>> listVoteEntries(long periodId, AuthenticatedUser user) {
        // Only ADMIN and EDITORIAL_BOARD can view vote entries
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new BusinessRuleException("Only ADMIN/EDITORIAL_BOARD can view vote entries");
        }

        return rankingRepository.listEntries(periodId);
    }
}
