
APP_FILE := CleanWatchFace.wapp
BUILD_DIR = build/files
SRC_DIR = src
ADB_TARGET = /sdcard/$(APP_FILE)

-include env.mk

JERRY_SNAPSHOT ?= "jerry-snapshot"
IMAGE_COMPRESS ?= "image_compress.py"
PACK ?= "pack.py"

CODE := $(addprefix $(BUILD_DIR)/code/,$(patsubst %.js,%,$(notdir $(wildcard $(SRC_DIR)/code/*.js))))
ICONS := $(addprefix $(BUILD_DIR)/icons/,$(patsubst %.png,%,$(filter-out preview.png background.png,$(notdir $(wildcard $(SRC_DIR)/icons/*.png)))))
DISPLAY_NAMES := $(addprefix $(BUILD_DIR)/display_name/,$(notdir $(wildcard $(SRC_DIR)/display_name/*)))
LAYOUTS := $(addprefix $(BUILD_DIR)/layout/,$(notdir $(wildcard $(SRC_DIR)/layout/*)))
CONFIG := $(addprefix $(BUILD_DIR)/config/,$(notdir $(wildcard $(SRC_DIR)/config/*)))
APP_JSON := $(BUILD_DIR)/../app.json
PREVIEW := $(BUILD_DIR)/icons/!preview.rle
BACKGROUND := $(BUILD_DIR)/icons/background

ALL_TARGETS := $(APP_JSON) $(CODE) $(DISPLAY_NAMES) $(BACKGROUND) $(PREVIEW) $(CONFIG) $(ICONS) $(LAYOUTS)

.PHONY: all clean make_dirs install
.SECONDEXPANSION:

all: make_dirs $(APP_FILE)

clean:
	rm -r build
	rm $(APP_FILE)

make_dirs:
	@mkdir -p $(sort $(dir $(ALL_TARGETS)))

install: all
	adb push $(APP_FILE) $(ADB_TARGET)
	adb shell am broadcast \
    	-a "nodomain.freeyourgadget.gadgetbridge.Q_UPLOAD_FILE" \
    	--es EXTRA_HANDLE APP_CODE \
    	--es EXTRA_PATH "${ADB_TARGET}" \
		--ez EXTRA_GENERATE_FILE_HEADER false

$(APP_FILE): $(ALL_TARGETS)
	@echo Packing to $@
	@$(PACK) -i $(BUILD_DIR)/.. -o $@


$(CODE): %:$$(addsuffix .js,$(SRC_DIR)/code/$$(notdir %))
	@echo Snapshotting $<
	@$(JERRY_SNAPSHOT) generate -f '' $< -o $@

$(ICONS): %:$$(addsuffix .png,$(SRC_DIR)/icons/$$(notdir %))
	@echo "Compressing image $<"
	@$(IMAGE_COMPRESS) -i $< -o $@ -w 24 -h 24 -f rle

$(PREVIEW): $(wildcard $(SRC_DIR)/icons/preview.png)
	@if [ -n "$<" ]; then \
		echo "Creating preview image $@"; \
		$(IMAGE_COMPRESS) -i $< -o $@ -w 192 -h 192 -f rle; \
	fi

$(BACKGROUND): $(wildcard $(SRC_DIR)/icons/background.png)
	@if [ -n "$<" ]; then \
		echo "Creating background image $@"; \
		$(IMAGE_COMPRESS) -i $< -o $@ -w 240 -h 240 -f raw; \
	fi


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
