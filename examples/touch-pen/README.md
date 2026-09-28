# Pressure Paint

A tiny black-on-white drawing canvas for testing pen and touchscreen pressure.

From this directory, compile with `haxe build-touch-pen.hxml`, then run
`hl touch-pen.hl`. HashLink must be able to find the rebuilt `limen.hdll`
and OpenGL graphics module (`opengl.limen`).

- Draw with a pen or finger. More pressure makes the brush thicker (2-32 canvas pixels).
- The window title shows the latest input source, pressure percentage and brush size.
- Press **Space** or **C** to clear, and **Esc** to quit.
- Multiple fingers and pens draw independently. Pen hovering does not draw.

The 960 x 640 canvas scales with the window and preserves drawing when resized.
Mouse input is ignored so emulated mouse events cannot duplicate pen/touch strokes.
Pressure is the value reported by the device and OS; touchscreens without pressure
support may report a constant value, so pressing harder will not change brush size.

Touch coordinates are normalized. Pen coordinates use window units, and pressure
arrives separately through `PenAxis.Pressure`, so the example retains it per pen.
Finger keys retain both full 64-bit device and finger IDs. Canceled touches and pens
leaving proximity release their state; losing window focus releases all pointers.
