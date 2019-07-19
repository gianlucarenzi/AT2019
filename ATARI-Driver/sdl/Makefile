######################################
# target
######################################
TARGET = abexvideo
BUILD_DIR = build
CC ?= gcc

# Librerie et al.

######################################
# source
######################################
# C sources
C_SOURCES =  \
	src/main.c \


C_SOURCES += \
	$(LIBRARY_C_SOURCES) \


# ASM sources
ASM_SOURCES =  \


# C includes
C_INCLUDES =  \
	-Iinc \


C_INCLUDES += \
	$(LIBRARY_C_INCLUDES) \


# compile gcc flags
ASFLAGS = $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

# SDL Includes
CFLAGS += $(shell sdl-config --cflags)

ifeq ($(DEBUG), 1)
	CFLAGS += -g -gdwarf-2 -O0 -pg

	ASM_SOURCES += \


endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = \


# libraries
LIBS = -lc -lm

# SDL Libs
LIBS += $(shell sdl-config --libs)

#-L/usr/lib/x86_64-linux-gnu -lSDL

LIBDIR = \


LDFLAGS = $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $(LDFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $(LDFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(BUILD_DIR):
	mkdir $@

#######################################
# clean up
#######################################
distclean:
	-rm -fR $(BUILD_DIR)


clean:
	-rm $(BUILD_DIR)/*.d
	-rm $(BUILD_DIR)/*.lst
	-rm $(BUILD_DIR)/*.o
	-rm $(BUILD_DIR)/*.map


#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
