/*
 * Spreader: Container Terminal Operating System
 * High-Throughput C11 ISO 6346 Container Checksum & Specification Engine
 */

#ifndef SPREADER_ISO6346_H
#define SPREADER_ISO6346_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Returns the numeric weight assigned to a letter or digit according to ISO 6346 Table 1.
 * Omitted multiples of 11: A=10, B=12..K=21, L=23..U=32, V=34..Z=38.
 * Returns -1 if the character is not a valid uppercase ASCII letter or digit.
 */
int iso6346_char_value(char c);

/**
 * Computes the 11th check digit from the first 10 characters (4-letter prefix + 6-digit serial).
 * Returns the integer check digit (0..9) on success, or -1 if input is malformed.
 */
int iso6346_compute_check_digit(const char *id_10chars);

/**
 * Validates a complete 11-character ISO container identifier (e.g. "MSKU1234567").
 * Returns true if valid format and check digit matches, false otherwise.
 */
bool iso6346_validate(const char *id_11chars);

/**
 * Parses a 4-character ISO 6346 size/type code (e.g. "22G1", "45R1").
 * Populates length in feet, height in tenths of feet, and reefer flag.
 * Returns true on successful parse, false if unrecognized.
 */
bool iso6346_parse_size_type(const char *iso_type, int *length_ft, int *height_tenths_ft, bool *is_reefer);

#ifdef __cplusplus
}
#endif

#endif /* SPREADER_ISO6346_H */
