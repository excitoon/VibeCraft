BUILD_DIR := _build/nif

ifdef CMAKE_TOOLCHAIN_FILE
  CMAKE_OPTS := -DCMAKE_TOOLCHAIN_FILE=$(CMAKE_TOOLCHAIN_FILE)
else
  CMAKE_OPTS :=
endif

all:
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release $(CMAKE_OPTS) -S .
	cmake --build $(BUILD_DIR) --config Release

clean:
	test -d $(BUILD_DIR) && cmake --build $(BUILD_DIR) --target clean 2>/dev/null || true
	rm -rf $(BUILD_DIR) priv/vibe_craft_nif.so priv/vibe_craft_nif.dll

.PHONY: all clean
