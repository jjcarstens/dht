# Makefile for building the DHT* port executable
#
# Makefile targets:
#
# all/install   build and install
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
#
# CC            C compiler. MUST be set if crosscompiling
# CFLAGS        compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_INCLUDE_DIR include path to ei.h (Required for crosscompile)
# ERL_EI_LIBDIR path to libei.a (Required for crosscompile)
# LDFLAGS       linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei_st

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -Werror
CFLAGS += -std=gnu99

DHT_BIN = $(PREFIX)/dht

RPI := rpi rpi0
RPI2 := rpi2 rpi3 rpi3a rpi4
BBB := bbb

SRC = src/main.c src/erlcmd.c

ifneq ($(filter $(MIX_TARGET),$(RPI)),)
TARGET=1
SRC += src/pi_dht_read.c src/pi_mmio.c src/common_dht_read.c
else ifneq ($(filter $(MIX_TARGET),$(RPI2)),)
TARGET=2
SRC += src/pi_2_dht_read.c src/pi_2_mmio.c src/common_dht_read.c
else ifneq ($(filter $(MIX_TARGET),$(BBB)),)
TARGET=3
SRC += $(wildcard src/bbb*.c) src/common_dht_read.c
endif

ifeq ($(MIX_TARGET), host)
ifneq ($(findstring Raspberry,$(shell cat /proc/device-tree/model)),)
$(info Detected Raspbian OS. Compiling for Raspberry Pi)
TARGET=2
SRC += src/pi_2_dht_read.c src/pi_2_mmio.c src/common_dht_read.c
else
$(info Target does not seem to have GPIO. Mocking out behavior for host)
TARGET=0
endif
CC = gcc
endif

CC ?= $(CROSSCOMPILER)-gcc

OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

calling_from_make:
	mix compile

all: $(BUILD) $(PREFIX) $(DHT_BIN)

$(OBJ): Makefile

$(BUILD)/%.o: src/%.c
	$(CC) -D TARGET=$(TARGET) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

$(PREFIX) $(BUILD):
	mkdir -p $@

$(DHT_BIN): $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	$(RM) $(DHT_BIN) $(OBJ)

format:
	astyle \
	    --style=kr \
	    --indent=spaces=4 \
	    --align-pointer=name \
	    --align-reference=name \
	    --convert-tabs \
	    --attach-namespaces \
	    --max-code-length=100 \
	    --max-instatement-indent=120 \
	    --pad-header \
	    --pad-oper \
	    src/*.c

.PHONY: all clean calling_from_make
