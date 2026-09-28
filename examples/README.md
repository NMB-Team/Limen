# LIMEN Examples

Small examples showing the basic parts of the LIMEN API without hiding them behind an engine or framework.

## Examples

### [Window](window/)

A minimal platform example covering window creation, display enumeration and native event handling.

### [OpenGL](gl/)

A small rendering example using LIMEN's OpenGL integration.

### [File dialog](file-dialog/)

A minimal asynchronous open-file dialog with multiple selection and filters.

### [Clipboard](clipboard/)

A binary clipboard round-trip using a custom MIME type, including availability and MIME enumeration.

### [Touch and Pen](touch-pen/)

A black-on-white drawing canvas with pressure-sensitive pen and touch strokes.

## Requirements

The examples target HashLink and expect LIMEN's native modules to be available to the runtime.

At minimum, the window example needs `limen.hdll`. The OpenGL and Touch and Pen examples also need the OpenGL graphics module (`opengl.limen`).

Build LIMEN first and make sure HashLink can find the produced native modules before running an example.

## Running

Each example contains its own `.hxml` file and is intended to be built from its own directory. This is especially important for the OpenGL example because its shader files are loaded relative to the current working directory.

See the README inside each example directory for the exact commands.
