
BUILD_DIR := build
SRC_DIR := src

-include env.mk

JERRY_SNAPSHOT ?= "jerry-snapshot"
IMAGE_COMPRESS ?= "image_compress.py"
PACK ?= "pack.py"

BUILD_FILES_DIR := $(BUILD_DIR)/files

APP_NAME := $(shell python3 -c 'import json, sys;print(json.load(sys.stdin)["identifier"])' < $(SRC_DIR)/app.json)
APP_FILE_NAME = $(APP_NAME).wapp
APP_FILE := $(BUILD_DIR)/$(APP_FILE_NAME)
ADB_TARGET = /sdcard/$(APP_FILE_NAME)

CODE := $(addprefix $(BUILD_FILES_DIR)/code/,$(patsubst %.js,%,$(notdir $(wildcard $(SRC_DIR)/code/*.js))))
ICONS := $(addprefix $(BUILD_FILES_DIR)/icons/,$(patsubst %.png,%,$(notdir $(wildcard $(SRC_DIR)/icons/*.png))))
DISPLAY_NAMES := $(addprefix $(BUILD_FILES_DIR)/display_name/,$(notdir $(wildcard $(SRC_DIR)/display_name/*)))
LAYOUTS := $(addprefix $(BUILD_FILES_DIR)/layout/,$(notdir $(wildcard $(SRC_DIR)/layout/*)))
CONFIG := $(addprefix $(BUILD_FILES_DIR)/config/,$(notdir $(wildcard $(SRC_DIR)/config/*)))
APP_JSON := $(BUILD_DIR)/app.json

ALL_TARGETS := $(APP_JSON) $(CODE) $(DISPLAY_NAMES) $(CONFIG) $(ICONS) $(LAYOUTS)

.PHONY: all clean make_dirs install
.SECONDEXPANSION:

all: make_dirs $(APP_FILE)

clean:
	-rm -r build

make_dirs:
#	@mkdir -p $(sort $(dir $(ALL_TARGETS)))
	@mkdir -p $(BUILD_FILES_DIR)/config $(BUILD_FILES_DIR)/code $(BUILD_FILES_DIR)/icons $(BUILD_FILES_DIR)/display_name $(BUILD_FILES_DIR)/layout

install: all
	adb push $(APP_FILE) $(ADB_TARGET)
	adb shell am broadcast \
    	-a "nodomain.freeyourgadget.gadgetbridge.Q_UPLOAD_FILE" \
    	--es EXTRA_HANDLE APP_CODE \
    	--es EXTRA_PATH "${ADB_TARGET}" \
		--ez EXTRA_GENERATE_FILE_HEADER false

$(APP_FILE): $(ALL_TARGETS)
	@echo Packing to $@
	@$(PACK) -i $(BUILD_DIR) -o $@


$(CODE): %:$$(addsuffix .js,$(SRC_DIR)/code/$$(notdir %))
	@echo Snapshotting $<
	@$(JERRY_SNAPSHOT) generate -f '' $< -o $@

$(ICONS): %:$$(addsuffix .png,$(SRC_DIR)/icons/$$(notdir %))
	@echo "Compressing image $<"
	@$(IMAGE_COMPRESS) -i $< -o $@

define COPY_FILES
echo Copying $< to $@
cp $< $@
endef

define COPY_MINIFY_JSON
echo Copying \& minifying $< to $@
python3 -c 'import json, sys;json.dump(json.load(sys.stdin), sys.stdout)' < $< > $@
endef

$(DISPLAY_NAMES): %:$(SRC_DIR)/display_name/$$(notdir %)
	@$(COPY_FILES)

$(LAYOUTS): %:$(SRC_DIR)/layout/$$(notdir %)
	@$(COPY_MINIFY_JSON)

$(CONFIG): %:$(SRC_DIR)/config/$$(notdir %)
	@$(COPY_MINIFY_JSON)

$(APP_JSON): %:$(SRC_DIR)/app.json
	@$(COPY_MINIFY_JSON)
