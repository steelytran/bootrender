AS=nasm

SRC=main.s
BIN=bin/boot.img

.PHONY: all clean
.SUFFIXES: .s

all: $(BIN)

$(BIN): $(SRC)
	$(AS) -f bin $< -o $@

clean:
	rm -f *.err $(BIN)
