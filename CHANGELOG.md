# Changelog

All notable changes to this project are listed here. Versions follow [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-10

First public release.

- Editable parameter dialog with all inputs; `use_dialog = false` runs with the values in the script.
- Isentropic freestream conditions, choked mass flow, driver tube length and mass, minimum driver diameter for a maximum inlet Mach number.
- Minimum vacuum dump-tank volume, dump-tank filling transient and nozzle exit-to-back pressure ratio vs time.
- Storage-tank volume, vacuum pump-down time and compressor fill time.
- Upstream and downstream uniform-core rhombus, rhombus-limited model size and blockage for axisymmetric or rectangular models.
- Reynolds-number matching in both directions (required p0 for a model, model size for a p0).
- Operating envelope with Reynolds-equivalent altitude from the International Standard Atmosphere.
- Six-panel summary figure with LaTeX labels.
