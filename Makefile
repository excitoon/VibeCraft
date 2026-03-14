ERL_ROOT   := $(shell erl -eval 'io:format("~s", [code:root_dir()])' -s init stop -noshell 2>/dev/null)
ERTS_VSN   := $(shell erl -eval 'io:format("~s", [erlang:system_info(version)])' -s init stop -noshell 2>/dev/null)
ERL_INC    := $(ERL_ROOT)/erts-$(ERTS_VSN)/include

SDL2_CFLAGS := $(shell sdl2-config --cflags 2>/dev/null)
SDL2_LDFLAGS := $(shell sdl2-config --libs 2>/dev/null)

CC      ?= gcc
CFLAGS  := -O2 -Wall -Wextra -fPIC -shared \
           -I$(ERL_INC) $(SDL2_CFLAGS)
LDFLAGS := $(SDL2_LDFLAGS) -lGL -lGLEW

PRIV_DIR := priv
NIF_SO   := $(PRIV_DIR)/vibe_craft_nif.so

all: $(NIF_SO)

$(PRIV_DIR):
	mkdir -p $(PRIV_DIR)

$(NIF_SO): c_src/vibe_craft_nif.c | $(PRIV_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(NIF_SO)

.PHONY: all clean
