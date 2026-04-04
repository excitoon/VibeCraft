cmake_minimum_required(VERSION 3.15)
project(vibe_craft_nif C)

# ── Erlang/OTP include path ────────────────────────────────────────────────

execute_process(
  COMMAND erl -eval "io:format(\"~s\", [code:root_dir()])" -s init stop -noshell
  OUTPUT_VARIABLE ERL_ROOT
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE ERL_ROOT_RESULT
)

if(NOT ERL_ROOT_RESULT EQUAL 0 OR ERL_ROOT STREQUAL "")
  message(FATAL_ERROR "Could not determine Erlang root directory. Is 'erl' in PATH?")
endif()

execute_process(
  COMMAND erl -eval "io:format(\"~s\", [erlang:system_info(version)])" -s init stop -noshell
  OUTPUT_VARIABLE ERTS_VSN
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE ERTS_VSN_RESULT
)

if(NOT ERTS_VSN_RESULT EQUAL 0 OR ERTS_VSN STREQUAL "")
  message(FATAL_ERROR "Could not determine ERTS version. Is 'erl' in PATH?")
endif()

set(ERL_INCLUDE "${ERL_ROOT}/erts-${ERTS_VSN}/include")

# ── SDL2 ──────────────────────────────────────────────────────────────────
# Prefer cmake CONFIG (works with vcpkg on Windows and Homebrew on macOS).
# Fall back to pkg-config on systems where SDL2 has no cmake package file
# (e.g. older Ubuntu releases with libsdl2-dev).

find_package(SDL2 QUIET CONFIG)
if(SDL2_FOUND)
  set(SDL2_LINK_TARGET SDL2::SDL2)
else()
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(SDL2 REQUIRED IMPORTED_TARGET sdl2)
  set(SDL2_LINK_TARGET PkgConfig::SDL2)
endif()

# ── OpenGL + GLEW ─────────────────────────────────────────────────────────

find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)

# ── NIF shared library ─────────────────────────────────────────────────────

add_library(vibe_craft_nif SHARED c_src/vibe_craft_nif.c)

target_include_directories(vibe_craft_nif PRIVATE
  "${ERL_INCLUDE}"
)

if(MSVC)
  target_compile_options(vibe_craft_nif PRIVATE /O2 /W4)
else()
  target_compile_options(vibe_craft_nif PRIVATE -O2 -Wall -Wextra)
endif()

target_link_libraries(vibe_craft_nif PRIVATE
  ${SDL2_LINK_TARGET}
  OpenGL::GL
  GLEW::GLEW
)

# On macOS the linker rejects undefined symbols by default.  Erlang NIF
# symbols (enif_*) are provided by the Erlang VM at load time, so we must
# allow them to remain unresolved until then.
if(APPLE)
  target_link_options(vibe_craft_nif PRIVATE -undefined dynamic_lookup)
endif()

set_target_properties(vibe_craft_nif PROPERTIES
  PREFIX ""
  OUTPUT_NAME "vibe_craft_nif"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/priv"
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/priv"
)
