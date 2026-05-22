package manga.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.sql.Date;

public class MangakaPerformanceRecord {
    private long id;
    private long mangakaId;
    private long periodId;
    private double popularityScore;
    private double reliabilityScore;
    private double qualityScore;
    private double overallScore;
    private int rankPosition;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private Date createdAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public long getMangakaId() { return mangakaId; }
    public void setMangakaId(long mangakaId) { this.mangakaId = mangakaId; }

    public long getPeriodId() { return periodId; }
    public void setPeriodId(long periodId) { this.periodId = periodId; }

    public double getPopularityScore() { return popularityScore; }
    public void setPopularityScore(double popularityScore) { this.popularityScore = popularityScore; }

    public double getReliabilityScore() { return reliabilityScore; }
    public void setReliabilityScore(double reliabilityScore) { this.reliabilityScore = reliabilityScore; }

    public double getQualityScore() { return qualityScore; }
    public void setQualityScore(double qualityScore) { this.qualityScore = qualityScore; }

    public double getOverallScore() { return overallScore; }
    public void setOverallScore(double overallScore) { this.overallScore = overallScore; }

    public int getRankPosition() { return rankPosition; }
    public void setRankPosition(int rankPosition) { this.rankPosition = rankPosition; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }
}
