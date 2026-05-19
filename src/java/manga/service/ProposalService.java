package manga.service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import manga.model.AuthenticatedUser;
import manga.model.Proposal;
import manga.repository.ProposalRepository;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ProposalService {

    @Autowired
    private ProposalRepository proposalRepository;

    public List<Proposal> listForUser(AuthenticatedUser user) {
        if (user.hasRole("MANGAKA")) {
            return proposalRepository.findForMangaka(user.getId());
        }
        if (user.hasRole("EDITORIAL_BOARD") || user.hasRole("TANTOU_EDITOR") || user.hasRole("ADMIN")) {
            return proposalRepository.findForBoardAndEditor();
        }
        throw new IllegalArgumentException("You do not have permission to view proposals");
    }

public Proposal getDetail(AuthenticatedUser user, long proposalId) {
    Proposal p = proposalRepository.findById(proposalId);
    if (p == null) throw new IllegalArgumentException("Proposal not found");

    // BR-09: Draft chỉ owner mới xem được
    if ("DRAFT".equalsIgnoreCase(p.getStatus()) && p.getMangakaId() != user.getId()) {
        throw new IllegalArgumentException("You do not have access to this proposal");
    }
    return p;
}

    public long createProposal(AuthenticatedUser user, String title, String genre, String synopsis) {
        requireRole(user, "MANGAKA", "Only MANGAKA can create proposals");
        if (isBlank(title) || isBlank(genre) || isBlank(synopsis)) {
            throw new IllegalArgumentException("Title, genre, and synopsis are required");
        }
        return proposalRepository.createDraft(user.getId(), title.trim(), genre.trim(), synopsis.trim());
    }

    public void updateDraft(AuthenticatedUser user, long proposalId, String title, String genre, String synopsis) {
        requireRole(user, "MANGAKA", "Only MANGAKA can update draft proposals");
        if (isBlank(title) || isBlank(genre) || isBlank(synopsis)) {
            throw new IllegalArgumentException("Title, genre, and synopsis are required");
        }
        proposalRepository.updateDraft(proposalId, user.getId(), title.trim(), genre.trim(), synopsis.trim());
    }

public void submitProposal(AuthenticatedUser user, long proposalId) {
    requireRole(user, "MANGAKA", "Only MANGAKA can submit proposals");
    if (proposalRepository.hasActiveProposal(user.getId())) {
        throw new IllegalArgumentException("You already have an active proposal (BR-01)");
    }
    // BR-12: 30-day cooldown   
    Proposal p = proposalRepository.findById(proposalId);
    if (p == null) throw new IllegalArgumentException("Proposal not found");
    if (p.getRejectedAt() != null) {
        long days = ChronoUnit.DAYS.between(
            p.getRejectedAt().toInstant(), Instant.now());
        if (days < 30) {
            throw new IllegalArgumentException(
                "Must wait 30 days after rejection. Days remaining: " + (30 - days));
        }
    }
    proposalRepository.submitProposal(proposalId, user.getId());
}

    public void castVote(AuthenticatedUser user, long proposalId, String voteType, String reason) {
        requireRole(user, "EDITORIAL_BOARD", "Only EDITORIAL_BOARD can vote");

        String normalizedVote = voteType == null ? "" : voteType.trim().toUpperCase();
        if (!"APPROVE".equals(normalizedVote) && !"REJECT".equals(normalizedVote) && !"ABSTAIN".equals(normalizedVote)) {
            throw new IllegalArgumentException("voteType must be APPROVE, REJECT, or ABSTAIN");
        }

        if ("REJECT".equals(normalizedVote) && isBlank(reason)) {
            throw new IllegalArgumentException("Reason is required for REJECT vote (BR-14)");
        }

        proposalRepository.castVoteAndResolve(proposalId, user.getId(), normalizedVote, safeTrim(reason));
    }

    public List<Map<String, Object>> listVotes(AuthenticatedUser user, long proposalId) {
        if (!user.hasRole("ADMIN") && !user.hasRole("EDITORIAL_BOARD")) {
            throw new IllegalArgumentException("Only ADMIN/EDITORIAL_BOARD can view proposal votes");
        }
        return proposalRepository.listVotes(proposalId);
    }

    private void requireRole(AuthenticatedUser user, String role, String message) {
        if (user == null || !user.hasRole(role)) {
            throw new IllegalArgumentException(message);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}
