package manga.controller.api;

import manga.common.ApiResponse;
import manga.common.util.SessionUserUtil;
import manga.model.AuthenticatedUser;
import manga.model.TaskSummary;
import manga.repository.PageTaskRepository;
import java.sql.Date;
import java.util.List;
import javax.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class PageTaskApiController {

    @Autowired
    private PageTaskRepository pageTaskRepository;

    @RequestMapping(value = "/tasks", method = RequestMethod.GET)
    public ApiResponse<List<TaskSummary>> listVisible(
            HttpSession session,
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "chapterId", required = false) Long chapterId) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        return ApiResponse.ok(pageTaskRepository.listVisible(user, status, chapterId), "Task list");
    }
    @RequestMapping(value = "/chapters/{chapterId}/tasks", method = RequestMethod.GET)
    public ApiResponse<List<TaskSummary>> list(@PathVariable("chapterId") long chapterId, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);

        if (user.hasRole("ADMIN")) {
            return ApiResponse.ok(pageTaskRepository.listByChapter(chapterId), "Task list");
        }

        if (user.hasRole("MANGAKA")) {
            long ownerId = pageTaskRepository.findChapterOwnerMangaka(chapterId);
            if (ownerId != user.getId()) {
                throw new IllegalArgumentException("Only chapter owner Mangaka can view this task list (BR-42)");
            }
            return ApiResponse.ok(pageTaskRepository.listByChapter(chapterId), "Task list");
        }

        if (user.hasRole("TANTOU_EDITOR")) {
            long tantouId = pageTaskRepository.findChapterTantouEditor(chapterId);
            if (tantouId != user.getId()) {
                throw new IllegalArgumentException("Only assigned Tantou can view this chapter task list (BR-42)");
            }
            return ApiResponse.ok(pageTaskRepository.listByChapter(chapterId), "Task list");
        }

        throw new IllegalArgumentException("Only MANGAKA/TANTOU_EDITOR/ADMIN can view chapter task list (BR-42)");
    }

    @RequestMapping(value = "/chapters/{chapterId}/tasks", method = RequestMethod.POST)
    public ApiResponse<TaskSummary> create(
            @PathVariable("chapterId") long chapterId,
            HttpSession session,
            @RequestParam("assistantId") long assistantId,
            @RequestParam("pageRangeStart") int pageRangeStart,
            @RequestParam("pageRangeEnd") int pageRangeEnd,
            @RequestParam("taskType") String taskType,
            @RequestParam("dueDate") String dueDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can create task");

        long ownerId = pageTaskRepository.findChapterOwnerMangaka(chapterId);
        if (ownerId != user.getId()) {
            throw new IllegalArgumentException("Only chapter owner can assign task (BR-31)");
        }

        long taskId = pageTaskRepository.create(
                chapterId,
                assistantId,
                pageRangeStart,
                pageRangeEnd,
                taskType,
                Date.valueOf(dueDate));
        return ApiResponse.ok(pageTaskRepository.findById(taskId), "Task created");
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.GET)
    public ApiResponse<TaskSummary> detail(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        TaskSummary task = pageTaskRepository.findById(id);
        if (task == null) {
            throw new IllegalArgumentException("Task not found");
        }

        long chapterId = task.getChapterId();
        long ownerMangakaId = pageTaskRepository.findChapterOwnerMangaka(chapterId);
        long tantouId = pageTaskRepository.findChapterTantouEditor(chapterId);

        boolean allowed = user.hasRole("ADMIN")
                || (user.hasRole("MANGAKA") && ownerMangakaId == user.getId())
                || (user.hasRole("TANTOU_EDITOR") && tantouId == user.getId())
                || (user.hasRole("ASSISTANT") && task.getAssistantId() == user.getId());

        if (!allowed) {
            throw new IllegalArgumentException("Only assigned roles can view this task (BR-42)");
        }

        return ApiResponse.ok(task, "Task detail");
    }

    @RequestMapping(value = "/tasks/{id}", method = RequestMethod.PUT)
    public ApiResponse<TaskSummary> update(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("assistantId") long assistantId,
            @RequestParam("pageRangeStart") int pageRangeStart,
            @RequestParam("pageRangeEnd") int pageRangeEnd,
            @RequestParam("taskType") String taskType,
            @RequestParam("dueDate") String dueDate) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can update task");

        pageTaskRepository.updateTaskByMangaka(
                id,
                user.getId(),
                assistantId,
                pageRangeStart,
                pageRangeEnd,
                taskType,
                Date.valueOf(dueDate));

        return ApiResponse.ok(pageTaskRepository.findById(id), "Task updated");
    }

    @RequestMapping(value = "/tasks/{id}/status", method = RequestMethod.PATCH)
    public ApiResponse<Object> updateStatus(
            @PathVariable("id") long id,
            HttpSession session,
            @RequestParam("status") String status) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "ASSISTANT", "Only ASSISTANT can submit task for review");
        pageTaskRepository.updateStatusByAssistant(id, user.getId(), status.toUpperCase());
        return ApiResponse.ok(null, "Task submitted for review");
    }

    @RequestMapping(value = "/tasks/{id}/approve", method = RequestMethod.POST)
    public ApiResponse<Object> approve(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can approve task");
        pageTaskRepository.approveByMangaka(id, user.getId());
        return ApiResponse.ok(null, "Task approved");
    }

    @RequestMapping(value = "/tasks/{id}/reject", method = RequestMethod.POST)
    public ApiResponse<Object> reject(@PathVariable("id") long id, HttpSession session) {
        AuthenticatedUser user = SessionUserUtil.requireUser(session);
        SessionUserUtil.requireRole(user, "MANGAKA", "Only MANGAKA can reject task");
        pageTaskRepository.rejectByMangaka(id, user.getId());
        return ApiResponse.ok(null, "Task rejected");
    }
}
