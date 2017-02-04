SOURCES = list.ll lisp.ll eval.ll print.ll read.ll object.ll token.ll
BITCODE = $(SOURCES:.ll=.bc)

TEST_HARNESS_SOURCES = test-reader-main.ll test-eval-main.ll
TEST_HARNESS_BITCODE = $(TEST_HARNESS_SOURCES:.ll=.bc)
TEST_HARNESSES = $(TEST_HARNESS_BITCODE:%-main.bc=%.bc)

.PHONY: clean test

all: test-reader.bc test-eval.bc

%.bc: %.ll
	llvm-as -o $@ $<

$(TEST_HARNESSES): %.bc: $(BITCODE) %-main.bc
	llvm-link $^ -o $@

clean:
	rm -f $(BITCODE) $(TEST_HARNESSES) $(TEST_HARNESS_BITCODE)

test: $(TEST_HARNESSES)
	./run-tests.sh

count:
	@echo "Total non-comment, non-blank source lines:"
	@./count.sh $(SOURCES)
