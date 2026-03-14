BUILD_DIR := _build/nif

all:
	cmake -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release -S .
	cmake --build $(BUILD_DIR)

clean:
	test -d $(BUILD_DIR) && cmake --build $(BUILD_DIR) --target clean 2>/dev/null || true
	rm -rf $(BUILD_DIR) priv/vibe_craft_nif.so

.PHONY: all clean
