package manga.dto;

import java.sql.Timestamp;

public class AnnotationDTO {
    private long id;
    private long manuscriptId;
    private long editorId;
    private int pageNumber;
    private String content;
    private Timestamp createdAt;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getManuscriptId() {
        return manuscriptId;
    }

    public void setManuscriptId(long manuscriptId) {
        this.manuscriptId = manuscriptId;
    }

    public long getEditorId() {
        return editorId;
    }

    public void setEditorId(long editorId) {
        this.editorId = editorId;
    }

    public int getPageNumber() {
        return pageNumber;
    }

    public void setPageNumber(int pageNumber) {
        this.pageNumber = pageNumber;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
