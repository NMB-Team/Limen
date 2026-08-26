# OpenGL Example

A compact interactive rendering example for LIMEN's OpenGL backend.

## Build

Run the commands from **this directory**:

```sh
haxe build-gl.hxml
```

This produces:

```text
exgl.hl
```

## Run

Still from this directory, run:

```sh
hl exgl.hl
```

The current working directory matters because the example loads its shaders from:

```text
./shaders/
```

HashLink must also be able to find both `limen.hdll` and `opengl.limen`.