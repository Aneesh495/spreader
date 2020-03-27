/*
 * Spreader: Container Terminal Operating System
 * Unit Test Suite for C11 Zero-Allocation Streaming EDIFACT Tokenizer
 */

#include "edifact_fast.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    int count;
    char last_tag[16];
    size_t last_elem_count;
} test_context_t;

static int on_segment(const edifact_segment_t *seg, void *user_data) {
    test_context_t *ctx = (test_context_t *)user_data;
    ctx->count++;

    size_t tag_copy_len = seg->tag.len < 15 ? seg->tag.len : 15;
    memcpy(ctx->last_tag, seg->tag.ptr, tag_copy_len);
    ctx->last_tag[tag_copy_len] = '\0';
    ctx->last_elem_count = seg->element_count;

    return 0; // Continue tokenizing
}

static void test_default_delimiters(void) {
    edifact_delimiters_t d = edifact_default_delims();
    assert(d.component_sep == ':');
    assert(d.element_sep == '+');
    assert(d.decimal_mark == '.');
    assert(d.release_ind == '?');
    assert(d.segment_term == '\'');
}

static void test_una_parsing(void) {
    const char *una_hdr = "UNA:+.? 'UNB+UNOA:2+SENDER+RECEIVER+261118:1200+1'";
    edifact_delimiters_t d;
    size_t hdr_len = 0;

    bool has_una = edifact_parse_una(una_hdr, strlen(una_hdr), &d, &hdr_len);
    assert(has_una == true);
    assert(hdr_len == 9);
    assert(d.component_sep == ':');
    assert(d.element_sep == '+');
    assert(d.segment_term == '\'');
}

static void test_sample_baplie_tokenization(void) {
    const char *baplie =
        "UNB+UNOA:2+SPREADER+PORTROTT+261118:1200+1001'\n"
        "UNH+1+BAPLIE:D:95B:UN:SMDG22'\n"
        "BGM+BAY+MSG001+9'\n"
        "TDT+20+0124W+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'\n"
        "LOC+5+NLRTM:139:6'\n"
        "EQD+CN+MSKU1234567+42G1:102:5++4'\n"
        "UNT+6+1'\n"
        "UNZ+1+1001'\n";

    test_context_t ctx;
    memset(&ctx, 0, sizeof(ctx));

    int seg_count = edifact_tokenize(baplie, strlen(baplie), NULL, on_segment, &ctx);
    assert(seg_count == 8);
    assert(ctx.count == 8);
    assert(strcmp(ctx.last_tag, "UNZ") == 0);
    assert(ctx.last_elem_count == 2);
}

static void test_split_components(void) {
    const char *raw = "42G1:102:5";
    edifact_slice_t elem = { .ptr = raw, .len = strlen(raw) };
    edifact_slice_t comps[8];

    size_t count = edifact_split_components(elem, ':', '?', comps, 8);
    assert(count == 3);

    assert(comps[0].len == 4);
    assert(strncmp(comps[0].ptr, "42G1", 4) == 0);

    assert(comps[1].len == 3);
    assert(strncmp(comps[1].ptr, "102", 3) == 0);

    assert(comps[2].len == 1);
    assert(strncmp(comps[2].ptr, "5", 1) == 0);
}

static void test_release_escape(void) {
    // Escaped delimiter inside element: ?' is an escaped quote, followed by ' as segment terminator
    const char *msg = "FTX+AAI+++TEXT?:WITH?:COLONS?+AND?''UNT+1+1'";
    test_context_t ctx;
    memset(&ctx, 0, sizeof(ctx));

    int seg_count = edifact_tokenize(msg, strlen(msg), NULL, on_segment, &ctx);
    assert(seg_count == 2);
    assert(strcmp(ctx.last_tag, "UNT") == 0);
}

int main(void) {
    printf("[C11 TEST] Running zero-allocation streaming EDIFACT tokenizer suite...\n");
    test_default_delimiters();
    test_una_parsing();
    test_sample_baplie_tokenization();
    test_split_components();
    test_release_escape();
    printf("[C11 TEST] All EDIFACT tokenizer tests passed successfully!\n");
    return 0;
}
