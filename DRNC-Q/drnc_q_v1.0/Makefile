CXX ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wextra -Wpedantic -Werror

.PHONY: all check release sanitize clean
all: drnq

drnq: drnq.cpp
	$(CXX) $(CXXFLAGS) drnq.cpp -o drnq

check: drnq
	./tests/run_tests.sh

release: drnq.cpp
	$(CXX) $(CXXFLAGS) -static -s drnq.cpp -o drnq

sanitize: drnq.cpp
	$(CXX) -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined -fno-omit-frame-pointer drnq.cpp -o drnq-sanitize
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 ./drnq-sanitize run examples/classes.drq
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 ./drnq-sanitize run examples/quantum_gates.drq
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 ./drnq-sanitize run examples/standard_library.drq
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 ./drnq-sanitize run examples/full_drncq_demo.drq

clean:
	rm -f drnq drnq-sanitize
