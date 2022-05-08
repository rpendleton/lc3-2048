.PHONY: all
all: 2048.obj

2048.obj: 2048.asm
	lc3as 2048.asm

.PHONY: clean
clean:
	rm -f 2048.obj 2048.sym
