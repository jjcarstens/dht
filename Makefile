# Makefile targets:
#
# all/install   build and install the package
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_COMPILE_PATH path to the build's ebin directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

ADAFRUIT_PYTHON_DHT_VERSION = 9aa64777957b42fab63d5853fbdf29985c24d713

TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SRC_TOP = $(TOP)/src
ADAFRUIT_PYTHON_DHT_SRC = $(SRC_TOP)/adafruit_python_dht-$(ADAFRUIT_PYTHON_DHT_VERSION)/source

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj
DL = $(TOP)/dl

GNU_TARGET_NAME = $(notdir $(CROSSCOMPILE))
GNU_HOST_NAME =

MAKE_ENV = KCONFIG_NOTIMESTAMP=1

ifneq ($(CROSSCOMPILE),)
MAKE_OPTS += CROSS_COMPILE="$(CROSSCOMPILE)-"
endif

SRC = $(ADAFRUIT_PYTHON_DHT_SRC)/common_dht_read.c

BEAGLE_BONE_TARGETS := bbb
RPI_TARGETS := rpi rpi0
RPI2_TARGETS := rpi2 rpi3 rpi3 rpi3a rpi4

ifneq ($(filter $(MIX_TARGET),$(RPI_TARGETS)),)
	SRC += $(wildcard ${ADAFRUIT_PYTHON_DHT_SRC}/Raspberry_Pi/*.c) $(ADAFRUIT_PYTHON_DHT_SRC)/_Raspberry_Pi_Driver.c
else ifneq ($(filter $(MIX_TARGET),$(RPI2_TARGETS)),)
	SRC += $(wildcard ${ADAFRUIT_PYTHON_DHT_SRC}/Raspberry_Pi_2/*.c) $(ADAFRUIT_PYTHON_DHT_SRC)/_Raspberry_Pi_2_Driver.c
else ifneq ($(filter $(MIX_TARGET),$(BEAGLE_BONE_TARGETS)),)
	SRC += $(wildcard ${ADAFRUIT_PYTHON_DHT_SRC}/Beaglebone_Black/*.c)
else
	# TODO: Make host driver
	# SRC += $(ADAFRUIT_PYTHON_DHT_SRC)/_Host_Driver.c
endif

ifeq ($(shell uname -s),Darwin)
# Fixes to build on OSX
MAKE = $(shell which gmake)
ifeq ($(MAKE),)
    $(error gmake required to build. Install by running "brew install homebrew/core/make")
endif

SED = $(shell which gsed)
ifeq ($(SED),)
    $(error gsed required to build. Install by running "brew install gnu-sed")
endif

MAKE_OPTS += SED=$(SED)
PATCH_DIRS = $(TOP)/patches/adafruit_python_dht

ifeq ($(CROSSCOMPILE),)
$(warning Native OS compilation is not supported on OSX. Skipping compilation.)

# Do a fake install for host
TARGETS = fake_install
endif
endif
TARGETS ?= install

calling_from_make:
	mix compile

all: $(TARGETS)

install: $(PREFIX)/dht

$(PREFIX)/dht: $(PREFIX) prep
	$(CC) $(CFLAGS) $(LDFLAGS) -L$(BUILD)/lib -I$(BUILD)/include -o $(PREFIX)/dht $(SRC)

prep: $(BUILD) $(SRC_TOP)/.patched
	# Install - this is a little lame...
	mkdir -p $(BUILD)/include/adafruit_python_dht/src
	cp $(ADAFRUIT_PYTHON_DHT_SRC)/{**/*,*}.h $(BUILD)/include/adafruit_python_dht/src

fake_install: $(PREFIX)
	printf "#!/bin/sh\nexit 0\n" > $(PREFIX)/dht

$(SRC_TOP)/.extracted: $(DL)/adafruit_python_dht-$(ADAFRUIT_PYTHON_DHT_VERSION).tar.gz
	# sha256sum -c adafruit_python_dht.hash
	tar x -C $(SRC_TOP) -f $(DL)/adafruit_python_dht-$(ADAFRUIT_PYTHON_DHT_VERSION).tar.gz
	touch $(SRC_TOP)/.extracted

$(SRC_TOP)/.patched: $(SRC_TOP)/.extracted
	cd $(ADAFRUIT_PYTHON_DHT_SRC); \
	for patchdir in $(PATCH_DIRS); do \
	    for patch in $$(ls $$patchdir); do \
		patch -p1 < "$$patchdir/$$patch"; \
	    done; \
	done
	touch $(SRC_TOP)/.patched

$(DL)/adafruit_python_dht-$(ADAFRUIT_PYTHON_DHT_VERSION).tar.gz: $(DL)
	curl -L https://github.com/adafruit/Adafruit_Python_DHT/archive/$(ADAFRUIT_PYTHON_DHT_VERSION).tar.gz > $@

$(PREFIX) $(BUILD) $(DL):
	mkdir -p $@

clean:
	if [ -n "$(MIX_COMPILE_PATH)" ]; then $(RM) -r $(BUILD); fi

.PHONY: all clean calling_from_make fake_install install