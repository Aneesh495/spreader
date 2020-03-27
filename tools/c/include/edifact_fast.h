/*
 * Spreader: Container Terminal Operating System
 * Zero-Allocation C11 Streaming ISO 9735 EDIFACT Tokenizer
 */

#ifndef SPREADER_EDIFACT_FAST_H
#define SPREADER_EDIFACT_FAST_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EDIFACT_MAX_ELEMENTS 64
#define EDIFACT_MAX_COMPONENTS 16

/**
 * ISO 9735 character service delimiters.
 */
typedef struct {
    char component_sep; // Default ':'
    char element_sep;   // Default '+'
    char decimal_mark;  // Default '.'
    char release_ind;   // Default '?'
    char segment_term;  // Default '\''
} edifact_delimiters_t;

/**
 * Non-owning view into a substring buffer.
 */
typedef struct {
    const char *ptr;
    size_t len;
} edifact_slice_t;

/**
 * Parsed segment view referencing raw buffer slices.
 */
typedef struct {
    edifact_slice_t tag;
    edifact_slice_t elements[EDIFACT_MAX_ELEMENTS];
    size_t element_count;
} edifact_segment_t;

/**
 * Callback invoked for each parsed segment.
 * Returns 0 to continue tokenization, non-zero to abort early.
 */
typedef int (*edifact_segment_cb)(const edifact_segment_t *seg, void *user_data);

/**
 * Returns standard ISO 9735 service default delimiters.
 */
edifact_delimiters_t edifact_default_delims(void);

/**
 * Inspects a buffer for a UNA service string advice header and extracts delimiters.
 * If present, advances buffer offset by 9 bytes (UNA + 6 delimiter chars).
 */
bool edifact_parse_una(const char *buf, size_t len, edifact_delimiters_t *out_delims, size_t *out_header_len);

/**
 * Stream-tokenizes an EDIFACT message buffer in a single zero-copy pass.
 * Invokes cb for each segment.
 * Returns total number of segments parsed, or -1 on syntax error.
 */
int edifact_tokenize(const char *buf, size_t len, const edifact_delimiters_t *delims, edifact_segment_cb cb, void *user_data);

/**
 * Splits an element slice into component slices based on component_sep.
 * Handles release_ind escape characters.
 */
size_t edifact_split_components(edifact_slice_t elem, char comp_sep, char release_ind, edifact_slice_t *out_comps, size_t max_comps);

#ifdef __cplusplus
}
#endif

#endif /* SPREADER_EDIFACT_FAST_H */
