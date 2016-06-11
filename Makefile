SOURCES = main.ll string.ll list.ll
BITCODE = $(SOURCES:.ll=.bc)

.PHONY: clean test

all: llisp.bc

%.bc: %.ll
	llvm-as -o $@ $<

llisp.bc: $(BITCODE)
	llvm-link $(BITCODE) -o $@

clean:
	rm -f $(BITCODE)

test: llisp.bc
	./run-tests.sh
