package manga.model;

import java.sql.Timestamp;

public class AuditLogItem {
    private long id;
    private Long actorId;
    private String action;
    private String entityType;
    private long entityId;
    private String detail;
    private Timestamp performedAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public Long getActorId() { return actorId; }
    public void setActorId(Long actorId) { this.actorId = actorId; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }
    public long getEntityId() { return entityId; }
    public void setEntityId(long entityId) { this.entityId = entityId; }
    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }
    public Timestamp getPerformedAt() { return performedAt; }
    public void setPerformedAt(Timestamp performedAt) { this.performedAt = performedAt; }
}

