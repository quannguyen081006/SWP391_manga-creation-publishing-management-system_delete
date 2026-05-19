package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.repository.ManuscriptRepository;
import manga.model.AuthenticatedUser;
import manga.model.ManuscriptSummary;
import java.util.List;
import javax.servlet.http.HttpSession;
import manga.enums.ManuscriptStatus;
import manga.model.AnnotationSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class ManuscriptApiController {

    @Autowired
    private ManuscriptRepository manuscriptRepository;

    @RequestMapping(value = "/chapters/{chapterId}/manuscripts", method = RequestMethod.GET)
    public ApiResponse<List<ManuscriptSummary>> list(@PathVariable("chapterId") long chapterId, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(manuscriptRepository.listByChapter(chapterId), "Manuscripts");
    }

    @RequestMapping(value = "/chapters/{chapterId}/manuscripts", method = RequestMethod.POST)
    public ApiResponse<ManuscriptSummary> submit(
            @PathVariable("chapterId") long chapterId,
            HttpSession session,
            @RequestParam("fileUrl") String fileUrl) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can submit manuscript");

        if (fileUrl == null || fileUrl.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "File URL cannot be empty"
            );
        }
        long ownerId = manuscriptRepository.getChapterMangaka(chapterId);
        if (ownerId != user.getId()) {
            throw new IllegalArgumentException("Only chapter owner can submit manuscript");
        }

        long id = manuscriptRepository.submit(chapterId, fileUrl);
        return ApiResponse.ok(manuscriptRepository.findById(id), "Manuscript submitted");
    }

    @RequestMapping(value = "/manuscripts/{id}", method = RequestMethod.GET)
    public ApiResponse<ManuscriptSummary> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        ManuscriptSummary manuscript = manuscriptRepository.findById(id);
        if (manuscript == null) {
            throw new IllegalArgumentException("Manuscript not found");
        }
        return ApiResponse.ok(manuscript, "Manuscript detail");
    }

    @RequestMapping(value = "/manuscripts/{id}/approve", method = RequestMethod.POST)
    public ApiResponse<Object> approve(@PathVariable("id") long id, HttpSession session) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);

        SessionUserUtil.requireRole(
                user,
                "TANTOU_EDITOR",
                "Only TANTOU_EDITOR can approve manuscript"
        );

        long tantouId = manuscriptRepository.getManuscriptTantou(id);

        if (tantouId != user.getId()) {
            throw new IllegalArgumentException(
                    "Only assigned Tantou can approve this manuscript"
            );
        }

        String status = manuscriptRepository.getStatus(id);

        if (ManuscriptStatus.APPROVED.name().equals(status)
                || ManuscriptStatus.ARCHIVED.name().equals(status)) {

            throw new IllegalArgumentException(
                    "Cannot approve finalized manuscript"
            );
        }

        manuscriptRepository.approve(id);

        return ApiResponse.ok(null, "Manuscript approved");
    }

    @RequestMapping(value = "/manuscripts/{id}/reject", method = RequestMethod.POST)
    public ApiResponse<Object> reject(@PathVariable("id") long id, HttpSession session) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);

        SessionUserUtil.requireRole(
                user,
                "TANTOU_EDITOR",
                "Only TANTOU_EDITOR can reject manuscript"
        );

        long tantouId = manuscriptRepository.getManuscriptTantou(id);

        if (tantouId != user.getId()) {
            throw new IllegalArgumentException(
                    "Only assigned Tantou can reject this manuscript"
            );
        }

        String status = manuscriptRepository.getStatus(id);

        if (ManuscriptStatus.APPROVED.name().equals(status)
                || ManuscriptStatus.ARCHIVED.name().equals(status)) {

            throw new IllegalArgumentException(
                    "Cannot reject finalized manuscript"
            );
        }

        manuscriptRepository.reject(id);

        return ApiResponse.ok(null, "Manuscript rejected");
    }

    @RequestMapping(value = "/manuscripts/{id}/annotations", method = RequestMethod.POST)
    public ApiResponse<Object> annotate(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("pageNumber") int pageNumber,
            @RequestParam("content") String content) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);

        SessionUserUtil.requireRole(
                user,
                "TANTOU_EDITOR",
                "Only TANTOU_EDITOR can annotate manuscript"
        );

        long tantouId = manuscriptRepository.getManuscriptTantou(id);

        if (tantouId != user.getId()) {
            throw new IllegalArgumentException(
                    "Only assigned Tantou can annotate"
            );
        }

        String status = manuscriptRepository.getStatus(id);

        if (ManuscriptStatus.APPROVED.name().equals(status)
                || ManuscriptStatus.ARCHIVED.name().equals(status)) {

            throw new IllegalArgumentException(
                    "Cannot annotate finalized manuscript"
            );
        }

        if (pageNumber <= 0) {
            throw new IllegalArgumentException(
                    "Page number must be greater than 0"
            );
        }

        if (content == null || content.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Annotation content cannot be empty"
            );
        }

        if (content.length() > 1000) {
            throw new IllegalArgumentException(
                    "Annotation content too long"
            );
        }

        manuscriptRepository.addAnnotation(
                id,
                user.getId(),
                pageNumber,
                content.trim()
        );

        return ApiResponse.ok(null, "Annotation added");
    }

    @RequestMapping(value = "/manuscripts/{id}/annotations", method = RequestMethod.GET)
    public ApiResponse<List<AnnotationSummary>> annotations(
            @PathVariable("id") long id,
            HttpSession session) {

        SessionUserUtil.requireUser(session);

        return ApiResponse.ok(
                manuscriptRepository.listAnnotations(id),
                "Annotations");
    }

    @RequestMapping(value = "/manuscripts/{id}/review", method = RequestMethod.POST)
    public ApiResponse<Object> startReview(
            @PathVariable("id") long id,
            HttpSession session) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);

        SessionUserUtil.requireRole(
                user,
                "TANTOU_EDITOR",
                "Only TANTOU_EDITOR can review manuscript"
        );

        long tantouId = manuscriptRepository.getManuscriptTantou(id);

        if (tantouId != user.getId()) {
            throw new IllegalArgumentException(
                    "Only assigned Tantou can review manuscript"
            );
        }

        manuscriptRepository.startReview(id);

        return ApiResponse.ok(null, "Review started");
    }
}
