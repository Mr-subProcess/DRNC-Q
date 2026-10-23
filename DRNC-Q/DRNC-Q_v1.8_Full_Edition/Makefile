CXX ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wextra -Wpedantic -Werror
SAN_CXX ?= $(shell command -v clang++ >/dev/null 2>&1 && echo clang++ || echo $(CXX))

.PHONY: all check release sanitize clean
all: drnq

drnq: drnq.cpp qpc_backend.inc
	$(CXX) $(CXXFLAGS) drnq.cpp -o drnq

check: drnq
	./tests/run_tests.sh

release: drnq.cpp qpc_backend.inc
	$(CXX) $(CXXFLAGS) -static-libstdc++ -static-libgcc -s drnq.cpp -o drnq

sanitize: drnq.cpp qpc_backend.inc
	$(SAN_CXX) -std=c++17 -O1 -g0 -Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined -fno-omit-frame-pointer drnq.cpp -o drnq-sanitize
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 BIN="$(CURDIR)/drnq-sanitize" ./tests/run_tests.sh

clean:
	rm -f drnq drnq-sanitize
