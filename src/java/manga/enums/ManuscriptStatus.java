package manga.enums;

/**
 * Manuscript status enum for the new visual workspace workflow.
 * 
 * Workflow: DRAFT → UNDER_REVIEW → APPROVED/REJECTED
 * - DRAFT: Mangaka creating workspace, can add/reorder pages
 * - UNDER_REVIEW: Tantou reviewing, production locked (BR-2: only one per chapter)
 * - APPROVED: Ready for publish, immutable (BR-4)
 * - REJECTED: Requires revision, immutable (BR-3)
 * - ARCHIVED: Historical record
 */
public enum ManuscriptStatus {
    DRAFT,           // Mangaka creating workspace
    UNDER_REVIEW,    // Tantou reviewing (BR-2: only one per chapter)
    APPROVED,        // Ready for publish (BR-4: immutable)
    PUBLISHED,       // Published and live
    REJECTED,        // Requires revision (BR-3: immutable)
    ARCHIVED         // Historical record
}

