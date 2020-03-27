# Spreader: C11 Native Performance Extensions Makefile

CC ?= clang
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -pedantic -O3 -Iinclude
SRC = src/iso6346.c src/edifact_fast.c
OBJ = $(SRC:.c=.o)
TEST_ISO = bin/test_iso6346
TEST_EDI = bin/test_edifact

all: $(OBJ) $(TEST_ISO) $(TEST_EDI)

bin:
	mkdir -p bin

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TEST_ISO): bin src/iso6346.o tests/test_iso6346.c
	$(CC) $(CFLAGS) src/iso6346.o tests/test_iso6346.c -o $@

$(TEST_EDI): bin src/edifact_fast.o tests/test_edifact.c
	$(CC) $(CFLAGS) src/edifact_fast.o tests/test_edifact.c -o $@

test: $(TEST_ISO) $(TEST_EDI)
	./$(TEST_ISO)
	./$(TEST_EDI)

clean:
	rm -rf src/*.o bin

.PHONY: all test clean
