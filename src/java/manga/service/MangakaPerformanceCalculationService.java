package manga.service;

import manga.repository.PerformancePeriodRepository;
import manga.repository.PerformanceVoteRepository;
import manga.repository.PerformanceResultRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MangakaPerformanceCalculationService {

    @Autowired
    private PerformancePeriodRepository periodRepository;

    @Autowired
    private PerformanceVoteRepository voteRepository;

    @Autowired
    private PerformanceResultRepository resultRepository;

    // Weighted formula: Overall = 0.4*Popularity + 0.35*Reliability + 0.25*Quality
    private static final double POPULARITY_WEIGHT = 0.4;
    private static final double RELIABILITY_WEIGHT = 0.35;
    private static final double QUALITY_WEIGHT = 0.25;

    @Transactional
    public void calculatePeriod(long periodId) {
        // Validate period status
        Map<String, Object> period = periodRepository.findPeriodById(periodId);
        if (!"CLOSED".equalsIgnoreCase((String) period.get("status"))) {
            throw new IllegalArgumentException("Only CLOSED periods can be calculated");
        }

        // Delete existing results if any (recalculation protection)
        if (resultRepository.hasResultsForPeriod(periodId)) {
            throw new IllegalArgumentException("Period has already been calculated. Results are immutable.");
        }

        // Get all votes for the period
        List<Map<String, Object>> votes = voteRepository.getVotesByPeriod(periodId);
        if (votes.isEmpty()) {
            throw new IllegalArgumentException("No votes found for this period");
        }

        // Aggregate votes by mangaka
        Map<Long, List<Map<String, Object>>> votesByMangaka = new HashMap<>();
        for (Map<String, Object> vote : votes) {
            long mangakaId = (Long) vote.get("mangakaId");
            votesByMangaka.computeIfAbsent(mangakaId, k -> new ArrayList<>()).add(vote);
        }

        // Calculate averages for each mangaka
        List<MangakaScore> mangakaScores = new ArrayList<>();
        for (Map.Entry<Long, List<Map<String, Object>>> entry : votesByMangaka.entrySet()) {
            long mangakaId = entry.getKey();
            List<Map<String, Object>> mangakaVotes = entry.getValue();

            double avgPopularity = calculateAverage(mangakaVotes, "popularityScore");
            double avgReliability = calculateAverage(mangakaVotes, "reliabilityScore");
            double avgQuality = calculateAverage(mangakaVotes, "qualityScore");

            // Calculate weighted overall score
            double overallScore = (POPULARITY_WEIGHT * avgPopularity) + 
                                  (RELIABILITY_WEIGHT * avgReliability) + 
                                  (QUALITY_WEIGHT * avgQuality);

            mangakaScores.add(new MangakaScore(mangakaId, overallScore, avgPopularity, avgReliability, avgQuality));
        }

        // Generate rankings
        List<MangakaScore> overallRanking = new ArrayList<>(mangakaScores);
        overallRanking.sort(Comparator.comparingDouble(MangakaScore::getOverallScore).reversed());

        List<MangakaScore> popularityRanking = new ArrayList<>(mangakaScores);
        popularityRanking.sort(Comparator.comparingDouble(MangakaScore::getPopularityScore).reversed());

        List<MangakaScore> reliabilityRanking = new ArrayList<>(mangakaScores);
        reliabilityRanking.sort(Comparator.comparingDouble(MangakaScore::getReliabilityScore).reversed());

        List<MangakaScore> qualityRanking = new ArrayList<>(mangakaScores);
        qualityRanking.sort(Comparator.comparingDouble(MangakaScore::getQualityScore).reversed());

        // Create rank maps
        Map<Long, Integer> overallRankMap = createRankMap(overallRanking);
        Map<Long, Integer> popularityRankMap = createRankMap(popularityRanking);
        Map<Long, Integer> reliabilityRankMap = createRankMap(reliabilityRanking);
        Map<Long, Integer> qualityRankMap = createRankMap(qualityRanking);

        // Save results
        for (MangakaScore score : mangakaScores) {
            resultRepository.saveResult(
                periodId,
                score.getMangakaId(),
                score.getOverallScore(),
                score.getPopularityScore(),
                score.getReliabilityScore(),
                score.getQualityScore(),
                overallRankMap.get(score.getMangakaId()),
                popularityRankMap.get(score.getMangakaId()),
                reliabilityRankMap.get(score.getMangakaId()),
                qualityRankMap.get(score.getMangakaId())
            );
        }

        // Mark period as calculated
        periodRepository.markAsCalculated(periodId);
    }

    private double calculateAverage(List<Map<String, Object>> votes, String scoreField) {
        double sum = 0;
        for (Map<String, Object> vote : votes) {
            sum += (Integer) vote.get(scoreField);
        }
        return sum / votes.size();
    }

    private Map<Long, Integer> createRankMap(List<MangakaScore> ranking) {
        Map<Long, Integer> rankMap = new HashMap<>();
        for (int i = 0; i < ranking.size(); i++) {
            rankMap.put(ranking.get(i).getMangakaId(), i + 1);
        }
        return rankMap;
    }

    private static class MangakaScore {
        private long mangakaId;
        private double overallScore;
        private double popularityScore;
        private double reliabilityScore;
        private double qualityScore;

        public MangakaScore(long mangakaId, double overallScore, double popularityScore, 
                          double reliabilityScore, double qualityScore) {
            this.mangakaId = mangakaId;
            this.overallScore = overallScore;
            this.popularityScore = popularityScore;
            this.reliabilityScore = reliabilityScore;
            this.qualityScore = qualityScore;
        }

        public long getMangakaId() { return mangakaId; }
        public double getOverallScore() { return overallScore; }
        public double getPopularityScore() { return popularityScore; }
        public double getReliabilityScore() { return reliabilityScore; }
        public double getQualityScore() { return qualityScore; }
    }
}
