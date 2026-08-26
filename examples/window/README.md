# Window Example

A minimal LIMEN platform example showing how to create a native window and process common window, keyboard and mouse events.

## Build

Run the commands from this directory:

```sh
haxe build-window.hxml
```

This produces:

```text
exwindow.hl
```

## Run

```sh
hl exwindow.hl
```

HashLink must be able to find LIMEN's native module (`limen.hdll`) and the graphics driver selected by `Platform.init(GraphicsDriver.None)`.

The window example does not use a graphics backend. HashLink only needs to find `limen.hdll`.

## Relevant API

The example is intentionally small and mainly uses:

```haxe
Platform.init();
Window.create(...);
Platform.pollEvent(event);
window.destroy();
Platform.quit();
```

Use this example as the starting point when you only need LIMEN's platform, window and input functionality.
