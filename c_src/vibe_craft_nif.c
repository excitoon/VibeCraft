/*
 * vibe_craft_nif.c
 *
 * Elixir NIF providing SDL2 window management and an OpenGL 3.3 Core
 * rendering context for VibeCraft.
 *
 * Exported functions (see nif_funcs[] at the bottom):
 *   create_window/3   – open a window + GL context
 *   destroy_window/1  – close a window
 *   poll_events/1     – drain the SDL2 event queue
 *   swap_buffers/1    – swap front/back buffers
 *   clear_screen/1    – clear colour + depth buffers
 *   upload_texture/4  – upload RGBA pixel data to the GPU
 *   draw_sprite/6     – draw a textured quad
 *   delete_texture/2  – free a GPU texture
 */

#include <erl_nif.h>
#include <GL/glew.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <stdio.h>
#include <string.h>

/* ── Window resource ─────────────────────────────────────────────────────── */

typedef struct {
    SDL_Window    *window;
    SDL_GLContext  gl_context;
    int            width;
    int            height;
    GLuint         shader_program;
    GLuint         vao;
    GLuint         vbo;
    GLint          u_projection;
    GLint          u_tex;
} WindowData;

static ErlNifResourceType *WINDOW_RES_TYPE;

static void window_destructor(ErlNifEnv *env, void *obj)
{
    (void)env;
    WindowData *wd = (WindowData *)obj;

    if (wd->vbo)            { glDeleteBuffers(1, &wd->vbo);          wd->vbo = 0; }
    if (wd->vao)            { glDeleteVertexArrays(1, &wd->vao);     wd->vao = 0; }
    if (wd->shader_program) { glDeleteProgram(wd->shader_program);   wd->shader_program = 0; }
    if (wd->gl_context)     { SDL_GL_DeleteContext(wd->gl_context);  wd->gl_context = NULL; }
    if (wd->window)         { SDL_DestroyWindow(wd->window);         wd->window = NULL; }
    SDL_Quit();
}

/* ── Shader helpers ──────────────────────────────────────────────────────── */

static const char *VERTEX_SHADER_SRC =
    "#version 330 core\n"
    "layout(location = 0) in vec2 a_pos;\n"
    "layout(location = 1) in vec2 a_uv;\n"
    "out vec2 v_uv;\n"
    "uniform mat4 u_projection;\n"
    "void main() {\n"
    "    gl_Position = u_projection * vec4(a_pos, 0.0, 1.0);\n"
    "    v_uv = a_uv;\n"
    "}\n";

static const char *FRAGMENT_SHADER_SRC =
    "#version 330 core\n"
    "in vec2 v_uv;\n"
    "out vec4 frag_color;\n"
    "uniform sampler2D u_tex;\n"
    "void main() {\n"
    "    frag_color = texture(u_tex, v_uv);\n"
    "}\n";

static GLuint compile_shader(GLenum type, const char *src)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &src, NULL);
    glCompileShader(shader);

    GLint ok = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetShaderInfoLog(shader, (GLsizei)sizeof(log), NULL, log);
        fprintf(stderr, "vibe_craft_nif: shader compile error: %s\n", log);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

static GLuint link_program(GLuint vert, GLuint frag)
{
    GLuint prog = glCreateProgram();
    glAttachShader(prog, vert);
    glAttachShader(prog, frag);
    glLinkProgram(prog);

    GLint ok = 0;
    glGetProgramiv(prog, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetProgramInfoLog(prog, (GLsizei)sizeof(log), NULL, log);
        fprintf(stderr, "vibe_craft_nif: program link error: %s\n", log);
        glDeleteProgram(prog);
        return 0;
    }
    return prog;
}

/* ── NIF helpers ─────────────────────────────────────────────────────────── */

static ERL_NIF_TERM ok_atom(ErlNifEnv *env)
{
    return enif_make_atom(env, "ok");
}

static ERL_NIF_TERM error_string(ErlNifEnv *env, const char *msg)
{
    return enif_make_tuple2(
        env,
        enif_make_atom(env, "error"),
        enif_make_string(env, msg, ERL_NIF_LATIN1));
}

/* ── NIF: create_window/3 ────────────────────────────────────────────────── */

static ERL_NIF_TERM nif_create_window(ErlNifEnv *env, int argc,
                                       const ERL_NIF_TERM argv[])
{
    (void)argc;

    unsigned title_len = 0;
    if (!enif_get_list_length(env, argv[0], &title_len))
        return enif_make_badarg(env);

    char *title = (char *)enif_alloc(title_len + 1);
    if (!enif_get_string(env, argv[0], title, (unsigned)title_len + 1, ERL_NIF_LATIN1)) {
        enif_free(title);
        return enif_make_badarg(env);
    }

    int width = 0, height = 0;
    if (!enif_get_int(env, argv[1], &width) ||
        !enif_get_int(env, argv[2], &height) ||
        width <= 0 || height <= 0) {
        enif_free(title);
        return enif_make_badarg(env);
    }

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        ERL_NIF_TERM err = error_string(env, SDL_GetError());
        enif_free(title);
        return err;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                        SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    SDL_Window *window = SDL_CreateWindow(
        title,
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        width, height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    enif_free(title);

    if (!window) {
        SDL_Quit();
        return error_string(env, SDL_GetError());
    }

    SDL_GLContext ctx = SDL_GL_CreateContext(window);
    if (!ctx) {
        SDL_DestroyWindow(window);
        SDL_Quit();
        return error_string(env, SDL_GetError());
    }

    glewExperimental = GL_TRUE;
    GLenum glew_err = glewInit();
    if (glew_err != GLEW_OK) {
        SDL_GL_DeleteContext(ctx);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return error_string(env,
            (const char *)glewGetErrorString(glew_err));
    }

    GLuint vert = compile_shader(GL_VERTEX_SHADER,   VERTEX_SHADER_SRC);
    GLuint frag = compile_shader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER_SRC);
    GLuint prog = (vert && frag) ? link_program(vert, frag) : 0;
    if (vert) glDeleteShader(vert);
    if (frag) glDeleteShader(frag);

    if (!prog) {
        SDL_GL_DeleteContext(ctx);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return error_string(env, "shader compilation or linking failed");
    }

    GLuint vao = 0, vbo = 0;
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    /* Pre-allocate a quad's worth of vertex data (4 × (2+2) floats). */
    glBufferData(GL_ARRAY_BUFFER, 16 * (GLsizeiptr)sizeof(float), NULL,
                 GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                          4 * (GLsizei)sizeof(float), (void *)0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                          4 * (GLsizei)sizeof(float),
                          (void *)(2 * sizeof(float)));
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    WindowData *wd =
        (WindowData *)enif_alloc_resource(WINDOW_RES_TYPE, sizeof(WindowData));
    wd->window         = window;
    wd->gl_context     = ctx;
    wd->width          = width;
    wd->height         = height;
    wd->shader_program = prog;
    wd->vao            = vao;
    wd->vbo            = vbo;
    wd->u_projection   = glGetUniformLocation(prog, "u_projection");
    wd->u_tex          = glGetUniformLocation(prog, "u_tex");

    ERL_NIF_TERM res = enif_make_resource(env, wd);
    enif_release_resource(wd);
    return enif_make_tuple2(env, ok_atom(env), res);
}

/* ── NIF: destroy_window/1 ───────────────────────────────────────────────── */

static ERL_NIF_TERM nif_destroy_window(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    /* Eagerly release resources; the destructor will skip freed members. */
    if (wd->vbo)            { glDeleteBuffers(1, &wd->vbo);          wd->vbo = 0; }
    if (wd->vao)            { glDeleteVertexArrays(1, &wd->vao);     wd->vao = 0; }
    if (wd->shader_program) { glDeleteProgram(wd->shader_program);   wd->shader_program = 0; }
    if (wd->gl_context)     { SDL_GL_DeleteContext(wd->gl_context);  wd->gl_context = NULL; }
    if (wd->window)         { SDL_DestroyWindow(wd->window);         wd->window = NULL; }
    SDL_Quit();

    return ok_atom(env);
}

/* ── NIF: poll_events/1 ──────────────────────────────────────────────────── */

static ERL_NIF_TERM nif_poll_events(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    ERL_NIF_TERM list = enif_make_list(env, 0);
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        ERL_NIF_TERM ev_term;
        switch (event.type) {
        case SDL_QUIT:
            ev_term = enif_make_atom(env, "quit");
            break;
        case SDL_KEYDOWN:
            ev_term = enif_make_tuple2(
                env,
                enif_make_atom(env, "keydown"),
                enif_make_int(env, (int)event.key.keysym.sym));
            break;
        case SDL_KEYUP:
            ev_term = enif_make_tuple2(
                env,
                enif_make_atom(env, "keyup"),
                enif_make_int(env, (int)event.key.keysym.sym));
            break;
        default:
            continue;
        }
        list = enif_make_list_cell(env, ev_term, list);
    }
    return list;
}

/* ── NIF: swap_buffers/1 ─────────────────────────────────────────────────── */

static ERL_NIF_TERM nif_swap_buffers(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    SDL_GL_SwapWindow(wd->window);
    return ok_atom(env);
}

/* ── NIF: clear_screen/1 ─────────────────────────────────────────────────── */

static ERL_NIF_TERM nif_clear_screen(ErlNifEnv *env, int argc,
                                      const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return ok_atom(env);
}

/* ── NIF: upload_texture/4 ───────────────────────────────────────────────── */

static ERL_NIF_TERM nif_upload_texture(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    ErlNifBinary pixels;
    if (!enif_inspect_binary(env, argv[1], &pixels))
        return enif_make_badarg(env);

    int width = 0, height = 0;
    if (!enif_get_int(env, argv[2], &width) ||
        !enif_get_int(env, argv[3], &height) ||
        width <= 0 || height <= 0)
        return enif_make_badarg(env);

    if (pixels.size != (size_t)(width * height * 4))
        return enif_make_badarg(env);

    GLuint tex_id = 0;
    glGenTextures(1, &tex_id);
    glBindTexture(GL_TEXTURE_2D, tex_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data);
    glBindTexture(GL_TEXTURE_2D, 0);

    return enif_make_tuple2(env, ok_atom(env),
                            enif_make_uint(env, (unsigned)tex_id));
}

/* ── NIF: draw_sprite/6 ──────────────────────────────────────────────────── */

static ERL_NIF_TERM nif_draw_sprite(ErlNifEnv *env, int argc,
                                     const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    unsigned int tex_id = 0;
    if (!enif_get_uint(env, argv[1], &tex_id))
        return enif_make_badarg(env);

    int x = 0, y = 0, w = 0, h = 0;
    if (!enif_get_int(env, argv[2], &x) ||
        !enif_get_int(env, argv[3], &y) ||
        !enif_get_int(env, argv[4], &w) ||
        !enif_get_int(env, argv[5], &h) ||
        w <= 0 || h <= 0)
        return enif_make_badarg(env);

    float x0 = (float)x,       y0 = (float)y;
    float x1 = (float)(x + w), y1 = (float)(y + h);
    float fw  = (float)wd->width,  fh = (float)wd->height;

    /* Column-major orthographic projection: origin top-left, Y down. */
    float proj[16] = {
         2.0f / fw,  0.0f,       0.0f, 0.0f,
         0.0f,      -2.0f / fh,  0.0f, 0.0f,
         0.0f,       0.0f,      -1.0f, 0.0f,
        -1.0f,       1.0f,       0.0f, 1.0f
    };

    /* Triangle strip: TL → TR → BL → BR */
    float verts[16] = {
        x0, y0,  0.0f, 0.0f,
        x1, y0,  1.0f, 0.0f,
        x0, y1,  0.0f, 1.0f,
        x1, y1,  1.0f, 1.0f
    };

    glUseProgram(wd->shader_program);
    glUniformMatrix4fv(wd->u_projection, 1, GL_FALSE, proj);
    glUniform1i(wd->u_tex, 0);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, (GLuint)tex_id);

    glBindVertexArray(wd->vao);
    glBindBuffer(GL_ARRAY_BUFFER, wd->vbo);
    glBufferSubData(GL_ARRAY_BUFFER, 0, (GLsizeiptr)sizeof(verts), verts);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);

    return ok_atom(env);
}

/* ── NIF: delete_texture/2 ───────────────────────────────────────────────── */

static ERL_NIF_TERM nif_delete_texture(ErlNifEnv *env, int argc,
                                        const ERL_NIF_TERM argv[])
{
    (void)argc;
    WindowData *wd = NULL;
    if (!enif_get_resource(env, argv[0], WINDOW_RES_TYPE, (void **)&wd))
        return enif_make_badarg(env);

    unsigned int tex_id = 0;
    if (!enif_get_uint(env, argv[1], &tex_id))
        return enif_make_badarg(env);

    GLuint id = (GLuint)tex_id;
    glDeleteTextures(1, &id);
    return ok_atom(env);
}

/* ── NIF load callback ───────────────────────────────────────────────────── */

static int nif_load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
    (void)priv;
    (void)info;

    WINDOW_RES_TYPE = enif_open_resource_type(
        env, NULL, "window_resource",
        window_destructor,
        ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER,
        NULL);

    return (WINDOW_RES_TYPE == NULL) ? -1 : 0;
}

/* ── NIF function table ──────────────────────────────────────────────────── */

static ErlNifFunc nif_funcs[] = {
    {"create_window",   3, nif_create_window,   0},
    {"destroy_window",  1, nif_destroy_window,  0},
    {"poll_events",     1, nif_poll_events,      0},
    {"swap_buffers",    1, nif_swap_buffers,     0},
    {"clear_screen",    1, nif_clear_screen,     0},
    {"upload_texture",  4, nif_upload_texture,   0},
    {"draw_sprite",     6, nif_draw_sprite,      0},
    {"delete_texture",  2, nif_delete_texture,   0}
};

ERL_NIF_INIT(Elixir.VibeCraft.GFX.NIF, nif_funcs, nif_load, NULL, NULL, NULL)
