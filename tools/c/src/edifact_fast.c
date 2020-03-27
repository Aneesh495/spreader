/*
 * Spreader: Container Terminal Operating System
 * Zero-Allocation C11 Streaming ISO 9735 EDIFACT Tokenizer
 */

#include "edifact_fast.h"
#include <ctype.h>
#include <string.h>

edifact_delimiters_t edifact_default_delims(void) {
    edifact_delimiters_t d;
    d.component_sep = ':';
    d.element_sep   = '+';
    d.decimal_mark  = '.';
    d.release_ind   = '?';
    d.segment_term  = '\'';
    return d;
}

bool edifact_parse_una(const char *buf, size_t len, edifact_delimiters_t *out_delims, size_t *out_header_len) {
    if (!buf || len < 9) return false;
    if (buf[0] != 'U' || buf[1] != 'N' || buf[2] != 'A') return false;

    if (out_delims) {
        out_delims->component_sep = buf[3];
        out_delims->element_sep   = buf[4];
        out_delims->decimal_mark  = buf[5];
        out_delims->release_ind   = buf[6];
        // buf[7] is reserved, typically space ' '
        out_delims->segment_term  = buf[8];
    }
    if (out_header_len) {
        *out_header_len = 9;
    }
    return true;
}

int edifact_tokenize(const char *buf, size_t len, const edifact_delimiters_t *delims, edifact_segment_cb cb, void *user_data) {
    if (!buf || !cb) return -1;

    edifact_delimiters_t d = delims ? *delims : edifact_default_delims();

    size_t pos = 0;
    // Check for optional UNA header
    if (len >= 9 && buf[0] == 'U' && buf[1] == 'N' && buf[2] == 'A') {
        edifact_delimiters_t una_delims;
        size_t una_len = 0;
        if (edifact_parse_una(buf, len, &una_delims, &una_len)) {
            d = una_delims;
            pos += una_len;
        }
    }

    int segment_count = 0;
    bool in_escape = false;

    while (pos < len) {
        // Skip whitespace between segments
        while (pos < len && (buf[pos] == '\r' || buf[pos] == '\n' || buf[pos] == ' ' || buf[pos] == '\t')) {
            pos++;
        }
        if (pos >= len) break;

        // Start of segment
        edifact_segment_t seg;
        memset(&seg, 0, sizeof(seg));

        size_t elem_start = pos;
        bool is_tag = true;

        while (pos < len) {
            char c = buf[pos];

            if (in_escape) {
                in_escape = false;
                pos++;
                continue;
            }

            if (c == d.release_ind) {
                in_escape = true;
                pos++;
                continue;
            }

            if (c == d.element_sep) {
                size_t elem_len = pos - elem_start;
                if (is_tag) {
                    seg.tag.ptr = buf + elem_start;
                    seg.tag.len = elem_len;
                    is_tag = false;
                } else {
                    if (seg.element_count < EDIFACT_MAX_ELEMENTS) {
                        seg.elements[seg.element_count].ptr = buf + elem_start;
                        seg.elements[seg.element_count].len = elem_len;
                        seg.element_count++;
                    }
                }
                pos++;
                elem_start = pos;
            } else if (c == d.segment_term) {
                size_t elem_len = pos - elem_start;
                if (is_tag) {
                    seg.tag.ptr = buf + elem_start;
                    seg.tag.len = elem_len;
                } else {
                    if (seg.element_count < EDIFACT_MAX_ELEMENTS) {
                        seg.elements[seg.element_count].ptr = buf + elem_start;
                        seg.elements[seg.element_count].len = elem_len;
                        seg.element_count++;
                    }
                }
                pos++; // Consume segment terminator
                break;
            } else {
                pos++;
            }
        }

        // Only invoke callback if segment has a non-empty tag
        if (seg.tag.len > 0) {
            segment_count++;
            if (cb(&seg, user_data) != 0) {
                break; // Early exit requested by callback
            }
        }
    }

    return segment_count;
}

size_t edifact_split_components(edifact_slice_t elem, char comp_sep, char release_ind, edifact_slice_t *out_comps, size_t max_comps) {
    if (!elem.ptr || elem.len == 0 || !out_comps || max_comps == 0) return 0;

    size_t comp_count = 0;
    size_t start = 0;
    bool in_escape = false;

    for (size_t i = 0; i < elem.len; i++) {
        char c = elem.ptr[i];

        if (in_escape) {
            in_escape = false;
            continue;
        }

        if (c == release_ind) {
            in_escape = true;
            continue;
        }

        if (c == comp_sep) {
            if (comp_count < max_comps) {
                out_comps[comp_count].ptr = elem.ptr + start;
                out_comps[comp_count].len = i - start;
                comp_count++;
            }
            start = i + 1;
        }
    }

    // Final component
    if (comp_count < max_comps) {
        out_comps[comp_count].ptr = elem.ptr + start;
        out_comps[comp_count].len = elem.len - start;
        comp_count++;
    }

    return comp_count;
}
