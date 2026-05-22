package manga.service;

import manga.model.MangakaPerformanceRecord;
import manga.repository.MangakaPerformanceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
public class MangakaPerformanceService {

    @Autowired
    private MangakaPerformanceRepository repository;

    @Transactional
    public void calculateMangakaPerformance(long periodId) {
        // Get all unique mangakas from the period
        Set<Long> mangakaIds = new HashSet<>();
        
        // From popularity data
        repository.getPopularityData(periodId).forEach(d -> mangakaIds.add(d.mangakaId));
        
        // From reliability data
        repository.getReliabilityData(periodId).forEach(d -> mangakaIds.add(d.mangakaId));
        
        // From quality data
        repository.getQualityData(periodId).forEach(d -> mangakaIds.add(d.mangakaId));

        // Calculate scores for each mangaka
        List<MangakaPerformanceRecord> records = new ArrayList<>();
        for (Long mangakaId : mangakaIds) {
            MangakaPerformanceRecord record = calculateMangakaScore(mangakaId, periodId);
            records.add(record);
        }

        // Sort by overall score descending
        records.sort((a, b) -> Double.compare(b.getOverallScore(), a.getOverallScore()));

        // Assign rank positions
        for (int i = 0; i < records.size(); i++) {
            records.get(i).setRankPosition(i + 1);
        }

        // Save all records
        for (MangakaPerformanceRecord record : records) {
            repository.save(record);
        }
    }

    private MangakaPerformanceRecord calculateMangakaScore(long mangakaId, long periodId) {
        MangakaPerformanceRecord record = new MangakaPerformanceRecord();
        record.setMangakaId(mangakaId);
        record.setPeriodId(periodId);

        // Calculate Popularity Score
        double popularityScore = calculatePopularityScore(mangakaId, periodId);
        record.setPopularityScore(popularityScore);

        // Calculate Reliability Score
        double reliabilityScore = calculateReliabilityScore(mangakaId, periodId);
        record.setReliabilityScore(reliabilityScore);

        // Calculate Quality Score
        double qualityScore = calculateQualityScore(mangakaId, periodId);
        record.setQualityScore(qualityScore);

        // Calculate Overall Score (weighted)
        double overallScore = 0.4 * popularityScore + 0.35 * reliabilityScore + 0.25 * qualityScore;
        record.setOverallScore(overallScore);

        return record;
    }

    private double calculatePopularityScore(long mangakaId, long periodId) {
        List<MangakaPerformanceRepository.MangakaPopularityData> data = repository.getPopularityData(periodId);
        Optional<MangakaPerformanceRepository.MangakaPopularityData> mangakaData = data.stream()
            .filter(d -> d.mangakaId == mangakaId)
            .findFirst();

        if (!mangakaData.isPresent()) {
            return 0.0; // No ranking data
        }

        double avgRankScore = mangakaData.get().avgRankScore;
        
        // Normalize to 0-100 scale (assuming rankScore is typically 0-100)
        return Math.min(100, Math.max(0, avgRankScore));
    }

    private double calculateReliabilityScore(long mangakaId, long periodId) {
        List<MangakaPerformanceRepository.MangakaReliabilityData> data = repository.getReliabilityData(periodId);
        Optional<MangakaPerformanceRepository.MangakaReliabilityData> mangakaData = data.stream()
            .filter(d -> d.mangakaId == mangakaId)
            .findFirst();

        if (!mangakaData.isPresent()) {
            return 50.0; // Default score if no submissions
        }

        MangakaPerformanceRepository.MangakaReliabilityData d = mangakaData.get();
        
        if (d.totalSubmissions == 0) {
            return 50.0; // No submissions
        }

        // Calculate on-time percentage
        double onTimePercentage = (d.onTimeSubmissions * 100.0) / d.totalSubmissions;
        return onTimePercentage;
    }

    private double calculateQualityScore(long mangakaId, long periodId) {
        List<MangakaPerformanceRepository.MangakaQualityData> data = repository.getQualityData(periodId);
        Optional<MangakaPerformanceRepository.MangakaQualityData> mangakaData = data.stream()
            .filter(d -> d.mangakaId == mangakaId)
            .findFirst();

        if (!mangakaData.isPresent()) {
            return 50.0; // Default score if no manuscripts
        }

        MangakaPerformanceRepository.MangakaQualityData d = mangakaData.get();
        
        if (d.totalCount == 0) {
            return 50.0; // No manuscripts
        }

        // Approval rate (higher is better)
        double approvalRate = (d.approvedCount * 100.0) / d.totalCount;
        
        // Reject rate (lower is better)
        double rejectRate = (d.rejectedCount * 100.0) / d.totalCount;
        
        // Annotation penalty (more annotations = lower quality)
        double annotationPenalty = Math.min(20, d.annotationCount * 2); // Max 20 point penalty
        
        // Quality score = approval rate - reject rate - annotation penalty
        double qualityScore = approvalRate - rejectRate - annotationPenalty;
        
        // Normalize to 0-100 range
        return Math.min(100, Math.max(0, qualityScore));
    }

    public List<MangakaPerformanceRecord> getPerformanceByPeriod(long periodId) {
        return repository.listByPeriod(periodId);
    }

    public List<MangakaPerformanceRecord> getTopPopularMangaka(long periodId) {
        return repository.listByPeriodOrderByPopularity(periodId);
    }

    public List<MangakaPerformanceRecord> getMostReliableMangaka(long periodId) {
        return repository.listByPeriodOrderByReliability(periodId);
    }

    public List<MangakaPerformanceRecord> getHighestQualityMangaka(long periodId) {
        return repository.listByPeriodOrderByQuality(periodId);
    }

    public List<Long> getAllPeriods() {
        return repository.listAllPeriods();
    }
}
