AS=nasm

SRCS=\
main.s \

BIN=bin/boot.img

.PHONY: all clean
.SUFFIXES: .obj .s

all: $(BIN)

$(BIN): $(SRCS)
	$(AS) -f bin $< -o $@

clean:
	rm -f *.err $(BIN)
