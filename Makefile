SOURCES = list.ll lisp.ll eval.ll print.ll read.ll object.ll token.ll
MAIN_SOURCE = llisp.ll
MAIN_BITCODE = $(MAIN_SOURCE:.ll=.bc)
MAIN_LINKED = $(MAIN_BITCODE:%.bc=%.out.bc)
MAIN_COMPILED = $(MAIN_LINKED:%.out.bc=%.s)
MAIN = $(MAIN_COMPILED:%.s=%)
BITCODE = $(SOURCES:.ll=.bc)

TEST_HARNESS_SOURCES = test-reader-main.ll test-eval-main.ll test-lisp-main.ll
TEST_HARNESS_BITCODE = $(TEST_HARNESS_SOURCES:.ll=.bc)
TEST_HARNESSES = $(TEST_HARNESS_BITCODE:%-main.bc=%.bc)

.PHONY: clean test

all: test-reader.bc test-eval.bc test-lisp.bc $(MAIN)
	@echo $(MAIN_SOURCE) $(MAIN_BITCODE) $(MAIN_LINKED) $(MAIN)

%.bc: %.ll
	llvm-as -o $@ $<

$(TEST_HARNESSES): %.bc: $(BITCODE) %-main.bc
	llvm-link $^ -o $@

$(MAIN_LINKED): %.bc: $(BITCODE) $(MAIN_BITCODE)
	llvm-link $^ -o $@

$(MAIN_COMPILED): $(MAIN_LINKED)
	llc $^ -o $@

$(MAIN): $(MAIN_COMPILED)
	gcc $^ -o $@

clean:
	rm -f $(BITCODE) $(TEST_HARNESSES) $(TEST_HARNESS_BITCODE) $(MAIN_BITCODE) $(MAIN_LINKED) $(MAIN_COMPILED) $(MAIN)

test: $(TEST_HARNESSES)
	./run-tests.sh

count:
	@echo "Total non-comment, non-blank source lines:"
	@./count.sh $(SOURCES)
