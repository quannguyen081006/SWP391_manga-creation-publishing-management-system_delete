package manga.service;

import manga.common.exception.BusinessRuleException;
import manga.dto.RankingCsvRow;
import manga.model.AuthenticatedUser;
import manga.repository.RankingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class RankingCsvImportService {

    @Autowired
    private RankingRepository rankingRepository;

    @Transactional
    public int importCsv(long periodId, MultipartFile file, AuthenticatedUser user) {
        if (user == null || !user.hasRole("ADMIN")) {
            throw new BusinessRuleException("Only ADMIN can upload ranking CSV");
        }

        Map<String, Object> period = rankingRepository.findPeriodById(periodId);
        if (!"OPEN".equalsIgnoreCase((String) period.get("status"))) {
            throw new BusinessRuleException("CSV upload is only allowed for OPEN ranking periods");
        }

        List<RankingCsvRow> rows = parseAndValidate(file);
        rankingRepository.replaceCsvEntries(periodId, user.getId(), rows);
        return rows.size();
    }

    private List<RankingCsvRow> parseAndValidate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessRuleException("CSV file is required");
        }

        List<RankingCsvRow> rows = new ArrayList<RankingCsvRow>();
        Set<Long> seenSeriesIds = new HashSet<Long>();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream(), "UTF-8"))) {
            String header = reader.readLine();
            if (header == null || !header.trim().equalsIgnoreCase("seriesId,seriesTitle,genre,voteCount,readerCount")) {
                throw new BusinessRuleException("Invalid CSV header. Expected: seriesId,seriesTitle,genre,voteCount,readerCount");
            }

            String line;
            int lineNumber = 1;
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                line = line.trim();
                if (line.isEmpty()) {
                    continue;
                }

                RankingCsvRow row = parseRow(line, lineNumber);
                if (!seenSeriesIds.add(row.getSeriesId())) {
                    throw new BusinessRuleException("Line " + lineNumber + ": duplicate seriesId " + row.getSeriesId());
                }
                if (!rankingRepository.seriesExists(row.getSeriesId())) {
                    throw new BusinessRuleException("Line " + lineNumber + ": seriesId " + row.getSeriesId() + " does not exist");
                }
                rows.add(row);
            }
        } catch (BusinessRuleException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new BusinessRuleException("Failed to read ranking CSV: " + ex.getMessage());
        }

        if (rows.isEmpty()) {
            throw new BusinessRuleException("CSV must contain at least one ranking row");
        }
        return rows;
    }

    private RankingCsvRow parseRow(String line, int lineNumber) {
        String[] parts = line.split(",");
        if (parts.length != 5) {
            throw new BusinessRuleException("Line " + lineNumber + ": expected 5 columns");
        }

        RankingCsvRow row = new RankingCsvRow();
        try {
            row.setSeriesId(Long.parseLong(parts[0].trim()));
            row.setSeriesTitle(parts[1].trim());
            row.setGenre(parts[2].trim());
            row.setVoteCount(Integer.parseInt(parts[3].trim()));
            row.setReaderCount(Integer.parseInt(parts[4].trim()));
        } catch (NumberFormatException ex) {
            throw new BusinessRuleException("Line " + lineNumber + ": invalid numeric value");
        }

        if (row.getSeriesId() < 0) {
            throw new BusinessRuleException("Line " + lineNumber + ": seriesId cannot be negative");
        }
        if (row.getSeriesTitle().length() == 0) {
            throw new BusinessRuleException("Line " + lineNumber + ": seriesTitle is required");
        }
        if (row.getGenre().length() == 0) {
            throw new BusinessRuleException("Line " + lineNumber + ": genre is required");
        }
        if (row.getVoteCount() < 0) {
            throw new BusinessRuleException("Line " + lineNumber + ": voteCount cannot be negative");
        }
        if (row.getReaderCount() <= 0) {
            throw new BusinessRuleException("Line " + lineNumber + ": readerCount must be greater than 0");
        }
        if (row.getVoteCount() > row.getReaderCount()) {
            throw new BusinessRuleException("Line " + lineNumber + ": voteCount cannot exceed readerCount");
        }
        return row;
    }
}
