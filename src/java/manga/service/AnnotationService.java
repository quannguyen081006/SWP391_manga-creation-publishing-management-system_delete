package manga.service;

import manga.common.exception.BusinessRuleException;
import manga.dto.AddAnnotationRequest;
import manga.enums.ManuscriptStatus;
import manga.model.AnnotationSummary;
import manga.model.AuthenticatedUser;
import manga.repository.ManuscriptRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AnnotationService {

    @Autowired
    private ManuscriptRepository manuscriptRepository;

    @Transactional
    public void addAnnotation(long manuscriptId, AddAnnotationRequest request, AuthenticatedUser user) {
        // Validate manuscript exists
        if (manuscriptRepository.findById(manuscriptId) == null) {
            throw new BusinessRuleException("Manuscript not found");
        }

        // Validate user is assigned Tantou Editor
        long tantouId = manuscriptRepository.getManuscriptTantou(manuscriptId);
        if (tantouId != user.getId()) {
            throw new BusinessRuleException("Only assigned Tantou Editor can add annotations");
        }

        // Validate manuscript status - annotations are part of the active Tantou review only.
        String status = manuscriptRepository.getStatus(manuscriptId);
        if (!ManuscriptStatus.UNDER_REVIEW.name().equals(status)) {
            throw new BusinessRuleException("Can only annotate the current UNDER_REVIEW manuscript version");
        }
        long chapterId = manuscriptRepository.findById(manuscriptId).getChapterId();
        if (!manuscriptRepository.listByChapter(chapterId).isEmpty()
                && manuscriptRepository.listByChapter(chapterId).get(0).getId() != manuscriptId) {
            throw new BusinessRuleException("Can only annotate the current manuscript version");
        }

        // Validate pageNumber
        if (request.getPageNumber() <= 0) {
            throw new BusinessRuleException("Page number must be greater than 0");
        }

        // Validate content (BR-40: meaningful feedback)
        if (request.getContent() == null || request.getContent().trim().isEmpty()) {
            throw new BusinessRuleException("Annotation content cannot be empty (BR-40)");
        }

        if (request.getContent().length() > 1000) {
            throw new BusinessRuleException("Annotation content too long (max 1000 characters)");
        }

        // Add annotation - binds strictly to manuscript version (BR-41)
        manuscriptRepository.addAnnotation(
            manuscriptId,
            user.getId(),
            request.getPageNumber(),
            normalizeCategory(request.getCategory()),
            normalizeStatus(request.getStatus()),
            request.getContent().trim()
        );
    }

    public List<AnnotationSummary> listAnnotationsByManuscript(long manuscriptId, AuthenticatedUser user) {
        // Validate manuscript exists
        if (manuscriptRepository.findById(manuscriptId) == null) {
            throw new BusinessRuleException("Manuscript not found");
        }

        // Return annotations ordered by createdAt (repository handles ordering)
        return manuscriptRepository.listAnnotations(manuscriptId);
    }

    private String normalizeCategory(String category) {
        String value = category == null ? "OTHER" : category.trim().toUpperCase();
        if ("ART".equals(value) || "STORY".equals(value) || "PACING".equals(value)
                || "DIALOGUE".equals(value) || "PANELING".equals(value) || "OTHER".equals(value)) {
            return value;
        }
        throw new BusinessRuleException("Annotation category must be ART, STORY, PACING, DIALOGUE, PANELING, or OTHER");
    }

    private String normalizeStatus(String status) {
        String value = status == null || status.trim().isEmpty() ? "OPEN" : status.trim().toUpperCase();
        if ("OPEN".equals(value) || "RESOLVED".equals(value)) {
            return value;
        }
        throw new BusinessRuleException("Annotation status must be OPEN or RESOLVED");
    }
}
