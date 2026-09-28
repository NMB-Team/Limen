# Tray example

Creates a tray icon with Open, an Enabled checkbox, a submenu, a separator and Quit.

Build and run from this directory with `limen.hdll` available to HashLink:

```sh
haxe build-tray.hxml
hl extray.hl
```

Tray operations must run on the main thread after `Platform.init()`. Callbacks are
dispatched by `Platform.pollEvent()` (including through `Platform.processEvents()`),
or by `Tray.update()` if the application does not poll platform events.

Use `entry.label`, `entry.enabled` and `entry.checked` to change entries. Checkbox
callbacks receive the state at activation; setting `checked` does not invoke them.
`entry.remove()` also destroys its submenu. A submenu's `parentEntry` provides
access to its label and enabled state.

`menu.clear()` removes its entries. `menu.destroy()` invalidates the menu and its
entries; destroying a submenu also removes its parent entry. SDL keeps an empty
root menu until the tray is destroyed, and `tray.createMenu()` can wrap it again.
Repeated `createMenu()` calls return the same live menu.

`tray.destroy()` releases all entries, submenus and callbacks. `Platform.quit()`
destroys all remaining trays. Repeated removal or destruction is safe; other
operations on destroyed objects throw. Pending activations of removed entries
are discarded. Keep trays alive explicitly until they are no longer needed.

Icons use Limen's `Surface`; SDL copies the icon during creation or `setIcon()`, so
the surface can be destroyed afterwards. A null icon requests SDL's default.
Tray availability, default icons and tooltip display depend on the desktop
environment. This example requires a desktop with system tray support.
