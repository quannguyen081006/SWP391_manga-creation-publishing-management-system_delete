package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.dto.AddAnnotationRequest;
import manga.dto.ApproveManuscriptRequest;
import manga.dto.RejectManuscriptRequest;
import manga.dto.SubmitManuscriptRequest;
import manga.model.AnnotationSummary;
import manga.model.AuthenticatedUser;
import manga.model.ManuscriptSummary;
import manga.repository.ManuscriptRepository;
import manga.service.AnnotationService;
import manga.service.ManuscriptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpSession;
import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class ManuscriptApiController {

    @Autowired
    private ManuscriptService manuscriptService;

    @Autowired
    private ManuscriptRepository manuscriptRepository;
    @Autowired
    private AnnotationService annotationService;

    @RequestMapping(value = "/chapters/{chapterId}/manuscripts", method = RequestMethod.GET)
    public ApiResponse<List<ManuscriptSummary>> list(@PathVariable("chapterId") long chapterId, HttpSession session) {
        SessionUserUtil.requireUser(session);
        return ApiResponse.ok(manuscriptService.listManuscriptVersions(chapterId), "Manuscripts");
    }

    @RequestMapping(value = "/chapters/{chapterId}/manuscripts", method = RequestMethod.POST)
    public ApiResponse<ManuscriptSummary> submit(
            @PathVariable("chapterId") long chapterId,
            HttpSession session,
            @RequestBody SubmitManuscriptRequest request) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can submit manuscript");

        ManuscriptSummary manuscript = manuscriptService.submitManuscript(chapterId, request, user);
        return ApiResponse.ok(manuscript, "Manuscript submitted");
    }

    @RequestMapping(value = "/manuscripts/{id}", method = RequestMethod.GET)
    public ApiResponse<ManuscriptSummary> detail(@PathVariable("id") long id, HttpSession session) {
        SessionUserUtil.requireUser(session);
        ManuscriptSummary manuscript = manuscriptService.getManuscriptById(id);
        if (manuscript == null) {
            throw new IllegalArgumentException("Manuscript not found");
        }
        return ApiResponse.ok(manuscript, "Manuscript detail");
    }

    @RequestMapping(value = "/manuscripts/{id}/approve", method = RequestMethod.POST)
    public ApiResponse<Object> approve(@PathVariable("id") long id, HttpSession session, @RequestBody ApproveManuscriptRequest request) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can approve manuscript");

        manuscriptService.approveManuscript(id, request, user);
        return ApiResponse.ok(null, "Manuscript approved");
    }

    @RequestMapping(value = "/manuscripts/{id}/reject", method = RequestMethod.POST)
    public ApiResponse<Object> reject(@PathVariable("id") long id, HttpSession session, @RequestBody RejectManuscriptRequest request) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can reject manuscript");

        manuscriptService.rejectManuscript(id, request, user);
        return ApiResponse.ok(null, "Manuscript rejected");
    }

    @RequestMapping(value = "/manuscripts/{id}/request-revision", method = RequestMethod.POST)
    public ApiResponse<Object> requestRevision(@PathVariable("id") long id, HttpSession session, @RequestBody RejectManuscriptRequest request) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can request revision");

        manuscriptService.requestRevision(id, request.getFeedback(), user);
        return ApiResponse.ok(null, "Revision requested");
    }

    @RequestMapping(value = "/manuscripts/{id}/annotations", method = RequestMethod.POST)
    public ApiResponse<Object> annotate(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestBody AddAnnotationRequest request) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can annotate manuscript");

        annotationService.addAnnotation(id, request, user);
        return ApiResponse.ok(null, "Annotation added");
    }

    @RequestMapping(value = "/manuscripts/{id}/annotations", method = RequestMethod.GET)
    public ApiResponse<List<AnnotationSummary>> annotations(
            @PathVariable("id") long id,
            HttpSession session) {

        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        return ApiResponse.ok(annotationService.listAnnotationsByManuscript(id, user), "Annotations");
    }

    @RequestMapping(value = "/manuscripts/{id}/review", method = RequestMethod.POST)
    public ApiResponse<Object> startReview(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "TANTOU_EDITOR", "Only TANTOU_EDITOR can review manuscript");

        manuscriptService.startReview(id, user);
        return ApiResponse.ok(null, "Review started");
    }
}
