/*
 * Spreader: Container Terminal Operating System
 * Unit Test Suite for C11 ISO 6346 Checksum and Parser
 */

#include "iso6346.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static void test_char_values(void) {
    assert(iso6346_char_value('A') == 10);
    assert(iso6346_char_value('B') == 12);
    assert(iso6346_char_value('K') == 21);
    assert(iso6346_char_value('L') == 23);
    assert(iso6346_char_value('U') == 32);
    assert(iso6346_char_value('V') == 34);
    assert(iso6346_char_value('Z') == 38);

    assert(iso6346_char_value('0') == 0);
    assert(iso6346_char_value('9') == 9);

    assert(iso6346_char_value('a') == -1);
    assert(iso6346_char_value('?') == -1);
}

static void test_compute_check_digit(void) {
    // Standard ISO test vectors
    assert(iso6346_compute_check_digit("CSQU305438") == 3);
    assert(iso6346_compute_check_digit("MSKU012345") == 9);

    // Invalid inputs
    assert(iso6346_compute_check_digit(NULL) == -1);
    assert(iso6346_compute_check_digit("SHORT") == -1);
    assert(iso6346_compute_check_digit("1234567890") == -1); // Missing letter prefix
}

static void test_validate(void) {
    assert(iso6346_validate("CSQU3054383") == true);
    assert(iso6346_validate("MSKU0123459") == true);

    // Corrupted check digit
    assert(iso6346_validate("CSQU3054384") == false);
    assert(iso6346_validate("MSKU0123450") == false);

    // Malformed lengths
    assert(iso6346_validate("CSQU305438") == false);
    assert(iso6346_validate("CSQU30543833") == false);
    assert(iso6346_validate(NULL) == false);
}

static void test_parse_size_type(void) {
    int len = 0;
    int h = 0;
    bool reefer = false;

    // 20ft standard dry
    assert(iso6346_parse_size_type("22G1", &len, &h, &reefer) == true);
    assert(len == 20);
    assert(h == 85);
    assert(reefer == false);

    // 40ft High-Cube reefer
    assert(iso6346_parse_size_type("45R1", &len, &h, &reefer) == true);
    assert(len == 40);
    assert(h == 95);
    assert(reefer == true);

    // 45ft High-Cube dry
    assert(iso6346_parse_size_type("L5G1", &len, &h, &reefer) == true);
    assert(len == 45);
    assert(h == 95);
    assert(reefer == false);

    // Invalid codes
    assert(iso6346_parse_size_type("9999", &len, &h, &reefer) == false);
    assert(iso6346_parse_size_type("22G", &len, &h, &reefer) == false);
    assert(iso6346_parse_size_type(NULL, &len, &h, &reefer) == false);
}

int main(void) {
    printf("[C11 TEST] Running ISO 6346 checksum and parser suite...\n");
    test_char_values();
    test_compute_check_digit();
    test_validate();
    test_parse_size_type();
    printf("[C11 TEST] All ISO 6346 tests passed successfully!\n");
    return 0;
}
