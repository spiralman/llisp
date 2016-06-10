SOURCES = main.ll string.ll list.ll
BITCODE = $(SOURCES:.ll=.bc)
TESTS = $(wildcard test/test-*.llisp)

.PHONY: clean test

all: llisp.bc

%.bc: %.ll
	llvm-as -o $@ $<

llisp.bc: $(BITCODE)
	llvm-link $(BITCODE) -o $@

clean:
	rm -f $(BITCODE)

test: llisp.bc
	for test in $(TESTS); do \
	  lli llisp.bc $$test; \
	done
