# Development Log

## 2026-11-18: Sprint 0 start

Decisions (details in `sprint-0-design.md`):

- Godot 4.7.2 from Homebrew, not pinned locally. CI pins the version later. Web export templates are installed when the first web export is needed.
- Compatibility renderer, 480x270 internal resolution, `viewport` stretch with integer scaling, nearest-neighbor filtering, 2D pixel snap.
- GUT 9.7.1 vendored in `addons/gut/` from the release zip. Verified to run on Godot 4.7.2.
- No autoloads. Input goes through Input Map actions only. Touch is a virtual joystick for movement (aiming/casting on touch is a later design decision).
- Work happens on the `sprint-0-foundation` branch, not on `main`.
