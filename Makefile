ARCH = x86_64

RUSTC = rustc
LD=ld
AS=nasm
CC=gcc

TARGET = target.json
LINKSCRIPT = app.ld

RUSTFLAGS = -g -O --cfg baremetalos --target=$(TARGET) -Z no-landing-pads

LINKFLAGS = -T $(LINKSCRIPT) --gc-sections -z max-page-size=0x20000

ASFLAGS=-f elf64

CFLAGS = -g -O -c -m64 -nostdlib -fomit-frame-pointer -mno-red-zone

LIBCORESRC=libcore/lib.rs
LIBCORE=libcore.rlib

RLIBCSRC=rlibc/src/lib.rs
RLIBC=librlibc.rlib

MAINSRC=hello.rs
MAIN=hello.o

STARTSRC=start.asm
START=start.o

LIBBAREMETALSRC=libBareMetal.c
LIBBAREMETAL=libBareMetal.o

LIBALLOCSRC=liballoc.c
LIBALLOC=liballoc.o

SRCS=$(wildcard *.rs)

OBJS=$(START) $(MAIN) $(LIBBAREMETAL) $(LIBALLOC) $(RLIBC) $(LIBCORE)

BIN=hellors.app

IMAGEDIR=../BareMetal/bin/
BMFS=$(IMAGEDIR)bmfs
IMAGE=$(IMAGEDIR)bmfs.image


.PHONY: all clean install

all: $(BIN)

install: $(BIN)
	$(BMFS) $(IMAGE) delete $(BIN)
	$(BMFS) $(IMAGE) create $(BIN) 2
	$(BMFS) $(IMAGE) write $(BIN)

clean:
	rm -f $(OBJS) $(BIN)

$(BIN): $(OBJS) $(LINKSCRIPT)
	$(LD) -o $@ $(LINKFLAGS) --start-group $(OBJS) --end-group

$(LIBCORE): $(LIBCORESRC) $(TARGET)
	$(RUSTC) $(RUSTFLAGS) -o $@ --crate-type=lib --emit=link $(LIBCORESRC)

$(RLIBC): $(RLIBCSRC) $(LIBCORE) $(TARGET)
	$(RUSTC) $(RUSTFLAGS) -o $@ --crate-type=lib --emit=link --extern core=$(LIBCORE) $(RLIBCSRC)

$(MAIN): $(MAINSRC) $(LIBCORE) $(SRCS) $(TARGET)
	$(RUSTC) $(RUSTFLAGS) -o $@ --emit=obj --extern core=$(LIBCORE) $(MAINSRC)

$(LIBBAREMETAL): $(LIBBAREMETALSRC)
	$(CC) $(CFLAGS) -o $@ $(LIBBAREMETALSRC)

$(LIBALLOC): $(LIBALLOCSRC)
	$(CC) $(CFLAGS) -o $@ $(LIBALLOCSRC)

$(START): $(STARTSRC)
	$(AS) -o $@ $(ASFLAGS) $(STARTSRC)
