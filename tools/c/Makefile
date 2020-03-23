# Spreader: C11 Native Performance Extensions Makefile

CC ?= clang
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -pedantic -O3 -Iinclude
SRC = src/iso6346.c
OBJ = $(SRC:.c=.o)
TEST_BIN = bin/test_iso6346

all: $(OBJ) $(TEST_BIN)

bin:
	mkdir -p bin

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TEST_BIN): bin $(OBJ) tests/test_iso6346.c
	$(CC) $(CFLAGS) $(OBJ) tests/test_iso6346.c -o $@

test: $(TEST_BIN)
	./$(TEST_BIN)

clean:
	rm -rf $(OBJ) bin

.PHONY: all test clean
