package manga.service;

import manga.repository.PerformanceImportRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class CsvImportService {

    @Autowired
    private PerformanceImportRecordRepository importRecordRepository;

    public static class CsvRow {
        public long mangakaId;
        public String mangakaName;
        public double popularityScore;
        public double reliabilityScore;
        public double qualityScore;
    }

    public static class ImportResult {
        public int successCount;
        public int failureCount;
        public List<String> errors;
        public List<CsvRow> validRows;

        public ImportResult() {
            this.successCount = 0;
            this.failureCount = 0;
            this.errors = new ArrayList<>();
            this.validRows = new ArrayList<>();
        }
    }

    public ImportResult parseAndValidateCsv(MultipartFile file, Map<String, Long> mangakaNameToIdMap) {
        ImportResult result = new ImportResult();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream()))) {
            String line;
            int lineNumber = 0;
            Set<Long> seenMangakaIds = new HashSet<>();

            // Skip header
            String header = reader.readLine();
            lineNumber++;

            if (header == null || !header.trim().equalsIgnoreCase("mangakaId,mangakaName,popularity,reliability,quality")) {
                result.errors.add("Invalid CSV header. Expected: mangakaId,mangakaName,popularity,reliability,quality");
                result.failureCount++;
                return result;
            }

            while ((line = reader.readLine()) != null) {
                lineNumber++;
                line = line.trim();
                if (line.isEmpty()) {
                    continue;
                }

                try {
                    CsvRow row = parseCsvRow(line, lineNumber, mangakaNameToIdMap);
                    if (!seenMangakaIds.add(row.mangakaId)) {
                        result.errors.add("Line " + lineNumber + ": duplicate mangakaId " + row.mangakaId);
                        result.failureCount++;
                    } else {
                        result.validRows.add(row);
                        result.successCount++;
                    }
                } catch (IllegalArgumentException e) {
                    result.errors.add("Line " + lineNumber + ": " + e.getMessage());
                    result.failureCount++;
                }
            }
        } catch (Exception e) {
            result.errors.add("Failed to read CSV file: " + e.getMessage());
            result.failureCount++;
        }

        if (result.successCount == 0 && result.failureCount == 0) {
            result.errors.add("CSV must contain at least one performance row");
            result.failureCount++;
        }

        return result;
    }

    private CsvRow parseCsvRow(String line, int lineNumber, Map<String, Long> mangakaNameToIdMap) {
        String[] parts = line.split(",");
        if (parts.length != 5) {
            throw new IllegalArgumentException("Invalid row format. Expected 5 columns: mangakaId,mangakaName,popularity,reliability,quality");
        }

        String mangakaIdStr = parts[0].trim();
        String mangakaName = parts[1].trim();
        String popularityStr = parts[2].trim();
        String reliabilityStr = parts[3].trim();
        String qualityStr = parts[4].trim();

        if (mangakaName.isEmpty()) {
            throw new IllegalArgumentException("Mangaka name cannot be empty");
        }

        long mangakaId;
        try {
            mangakaId = Long.parseLong(mangakaIdStr);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid mangakaId");
        }

        Long expectedMangakaId = mangakaNameToIdMap.get(mangakaName);
        if (expectedMangakaId == null) {
            throw new IllegalArgumentException("Mangaka '" + mangakaName + "' not found in database");
        }
        if (expectedMangakaId.longValue() != mangakaId) {
            throw new IllegalArgumentException("Mangaka ID does not match mangaka name");
        }

        double popularityScore;
        double reliabilityScore;
        double qualityScore;

        try {
            popularityScore = Double.parseDouble(popularityStr);
            reliabilityScore = Double.parseDouble(reliabilityStr);
            qualityScore = Double.parseDouble(qualityStr);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid numeric values");
        }

        if (popularityScore < 0 || popularityScore > 100) {
            throw new IllegalArgumentException("Popularity score must be between 0 and 100");
        }

        if (reliabilityScore < 0 || reliabilityScore > 100) {
            throw new IllegalArgumentException("Reliability score must be between 0 and 100");
        }

        if (qualityScore < 0 || qualityScore > 100) {
            throw new IllegalArgumentException("Quality score must be between 0 and 100");
        }

        CsvRow row = new CsvRow();
        row.mangakaId = mangakaId;
        row.mangakaName = mangakaName;
        row.popularityScore = popularityScore;
        row.reliabilityScore = reliabilityScore;
        row.qualityScore = qualityScore;

        return row;
    }

    public void importValidRows(long periodId, List<CsvRow> validRows, Map<String, Long> mangakaNameToIdMap) {
        for (CsvRow row : validRows) {
            importRecordRepository.saveImportRecord(
                periodId,
                row.mangakaId,
                row.popularityScore,
                row.reliabilityScore,
                row.qualityScore
            );
        }
    }

    public Map<String, Long> buildMangakaNameToIdMap(List<Map<String, Object>> mangakaList) {
        Map<String, Long> map = new HashMap<>();
        for (Map<String, Object> mangaka : mangakaList) {
            String username = (String) mangaka.get("username");
            Long id = (Long) mangaka.get("id");
            if (username != null && id != null) {
                map.put(username, id);
            }
        }
        return map;
    }
}
