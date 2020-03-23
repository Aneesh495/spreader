/*
 * Spreader: Container Terminal Operating System
 * High-Throughput C11 ISO 6346 Container Checksum & Specification Engine
 */

#include "iso6346.h"
#include <ctype.h>
#include <string.h>

int iso6346_char_value(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c == 'A') return 10;
    if (c >= 'B' && c <= 'K') {
        return (c - 'B') + 12;
    }
    if (c >= 'L' && c <= 'U') {
        return (c - 'L') + 23;
    }
    if (c >= 'V' && c <= 'Z') {
        return (c - 'V') + 34;
    }
    return -1;
}

int iso6346_compute_check_digit(const char *id_10chars) {
    if (!id_10chars) return -1;
    if (strlen(id_10chars) < 10) return -1;

    // Verify first 4 characters are uppercase letters
    for (int i = 0; i < 4; i++) {
        if (id_10chars[i] < 'A' || id_10chars[i] > 'Z') return -1;
    }
    // Verify next 6 characters are digits
    for (int i = 4; i < 10; i++) {
        if (id_10chars[i] < '0' || id_10chars[i] > '9') return -1;
    }

    static const int weights[10] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512};
    int total = 0;

    for (int i = 0; i < 10; i++) {
        int val = iso6346_char_value(id_10chars[i]);
        if (val < 0) return -1;
        total += val * weights[i];
    }

    int rem = total % 11;
    return rem % 10;
}

bool iso6346_validate(const char *id_11chars) {
    if (!id_11chars) return false;
    if (strlen(id_11chars) != 11) return false;

    int expected = iso6346_compute_check_digit(id_11chars);
    if (expected < 0) return false;

    int actual = id_11chars[10] - '0';
    return expected == actual;
}

bool iso6346_parse_size_type(const char *iso_type, int *length_ft, int *height_tenths_ft, bool *is_reefer) {
    if (!iso_type || strlen(iso_type) != 4) return false;

    // Length code: element 0
    int len = 0;
    switch (iso_type[0]) {
        case '2': len = 20; break;
        case '4': len = 40; break;
        case 'L': len = 45; break;
        case 'M': len = 48; break;
        default: return false;
    }

    // Height code: element 1
    int h = 0;
    switch (iso_type[1]) {
        case '0': h = 80; break; // 8ft 0in
        case '2': h = 85; break; // 8ft 6in
        case '5': h = 95; break; // 9ft 6in High Cube
        default: return false;
    }

    // Type group: element 2
    char type_code = iso_type[2];
    bool reefer = (type_code == 'R');

    if (length_ft) *length_ft = len;
    if (height_tenths_ft) *height_tenths_ft = h;
    if (is_reefer) *is_reefer = reefer;

    return true;
}
