# Ludwieg Tube Designer and Analyser

MATLAB tool for the preliminary design and performance analysis of a **Ludwieg tube wind tunnel with a free-jet test section**. Given the nozzle (design exit Mach number and exit diameter) and the facility hardware, it works out what the tunnel can deliver and what it needs:

- driver tube length, mass and minimum diameter for the target run time,
- freestream conditions in the test section (p, T, rho, u, mu, unit Reynolds number),
- minimum vacuum dump-tank volume, dump-tank pressure rise during the run, and the nozzle exit-to-back pressure ratio,
- storage-tank volume, compressor and vacuum pump-down times,
- the **usable test core** (upstream and downstream uniform-flow rhombus), the **largest model** that fits in it, and its **blockage**,
- **Reynolds-number matching**: the stagnation pressure needed for a target model Reynolds number, and the model size that matches it at the chosen pressure,
- the **operating envelope**: unit Reynolds number against stagnation pressure, with the **Reynolds-equivalent flight altitude**.

It is intended to be used with a nozzle designed with the method of characteristics, for example with
[Three-Dimensional-Nozzle-Design-Code](https://github.com/TheWa1kingDead/Three-Dimensional-Nozzle-Design-Code) and
[MOC_Nozzle_BLC_contour_export](https://github.com/TheWa1kingDead/MOC_Nozzle_BLC_contour_export).

---

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Inputs](#inputs)
- [What the script computes](#what-the-script-computes)
- [Console output](#console-output)
- [Figure](#figure)
- [Assumptions and limitations](#assumptions-and-limitations)
- [Repository layout](#repository-layout)
- [How to cite](#how-to-cite)
- [References](#references)
- [License](#license)

The equations behind every step are in [`docs/THEORY.md`](docs/THEORY.md).

---

## Requirements

- MATLAB **R2021a** or newer (LaTeX labels in `uilabel`, `uigridlayout`, `tiledlayout`, `xline`/`yline`).
- **Aerospace Toolbox**, for `atmosisa` (International Standard Atmosphere, used for the Reynolds-equivalent altitude).

---

## Quick start

1. Clone or download this repository.
2. Open `Ludwieg_tunnel_freejet_analysis.m` in MATLAB and press **Run**.
3. A dialog opens with all inputs, filled with the defaults from Section 1 of the script. Edit any value and press **OK**.
4. The results are printed in the Command Window and a 2 x 3 figure is drawn.

For batch runs or parameter sweeps set `use_dialog = false` in Section 1; the values written in the script are then used directly.

The default case is a Mach 6 nozzle with a 100 mm exit, 10 bar / 300 K driver, 10 ms run time and a 3 inch driver tube.

---

## Inputs

All inputs are in **Section 1** of the script and appear in the dialog in five columns.

**Run conditions**

| Variable | Default | Units | Meaning |
|---|---|---|---|
| `P0_driver` | `10e5` | Pa | Initial driver (stagnation) pressure |
| `T0_driver` | `300` | K | Initial driver (stagnation) temperature |
| `t_run` | `0.010` | s | Target run time |
| `M_exit` | `6` | - | Nozzle design exit Mach number |
| `target_Re_L` | `3e6` | - | Target Reynolds number based on model length |

**Tunnel geometry**

| Variable | Default | Units | Meaning |
|---|---|---|---|
| `P_vac` | `1e-3` | Pa | Initial vacuum (dump) tank pressure |
| `D_driver` | `3*25.4e-3` | m | Driver tube inner diameter |
| `D_exit` | `0.100` | m | Nozzle exit diameter (circular) |
| `n` | `1.1` | - | Polytropic index used in the dump-tank sizing correlation |
| `M_inlet_max` | `0.3` | - | Highest acceptable Mach number in the driver tube / nozzle inlet |

**Model**

| Variable | Default | Units | Meaning |
|---|---|---|---|
| `model_mode` | `'axisymmetric'` | - | `'axisymmetric'` (circular base) or `'rectangular'` (rectangular base) |
| `model_width` | `40e-3` | m | Spanwise width, rectangular model only |
| `alpha_upper` | `15` | deg | Upper surface angle, rectangular model |
| `alpha_lower` | `12` | deg | Lower surface angle, rectangular model |
| `alpha_axi` | `10` | deg | Angle used for the axisymmetric model length |

Model length from its base dimension:

- rectangular (example): `L = 2h / (tan(alpha_upper) + tan(alpha_lower))` 
- axisymmetric: `L = d / tan(alpha_axi)`

**Gas**

| Variable | Default | Units | Meaning |
|---|---|---|---|
| `mu0` | `1.716e-5` | Pa s | Sutherland reference viscosity |
| `T0_S` | `273.15` | K | Sutherland reference temperature |
| `S_C` | `110.4` | K | Sutherland constant |
| `g` | `1.4` | - | Ratio of specific heats |
| `R` | `287.05` | J/(kg K) | Gas constant |

**Facility infrastructure**

| Variable | Default | Units | Meaning |
|---|---|---|---|
| `ambient_p` | `101325` | Pa | Ambient pressure |
| `Q_vac_CMH` | `2000` | m^3/hr | Vacuum pump volumetric speed |
| `Q_comp_CFM` | `100` | CFM | Compressor free-air delivery |
| `V_comp` | `5` | m^3 | Compressor receiver (storage) volume |
| `P_storage_i` | `30e5` | Pa | High-pressure storage initial pressure |

Inputs are checked for invalid numbers, non-positive values and an unknown `model_mode` before any calculation.

---

## What the script computes

The script is organised in numbered sections; the same numbers are used here.

| Section | Result |
|---|---|
| 4. Derived tunnel quantities | Isentropic exit conditions, unit Reynolds number, throat area and equivalent diameter, choked mass flow, driver length (`L = t_run*a0/2`), driver mass, minimum driver diameter for `M_inlet_max`, required and available pressure ratios, minimum dump-tank volume, pump-down and compressor times, minimum storage volume |
| 5. Core-flow geometry | Mach angle and length of the uniform-flow rhombus downstream of the exit (free jet) and inside the nozzle (last characteristic) |
| 6-7. Dump-tank filling | Time history of dump-tank mass, temperature and pressure during the run (rigid adiabatic tank) |
| 8. Pressure ratio | Nozzle exit static pressure over back pressure vs time; time of perfect expansion |
| 9. Model sizing | Largest model base dimension whose nose-growth line stays inside the downstream rhombus; its length and blockage |
| 10. Reynolds matching | Driver pressure needed to reach `target_Re_L` with that model; model size and length that reach `target_Re_L` at the chosen `P0_driver`; dump volume at the new condition |
| 11. Operating envelope | Unit Reynolds number for `p0` from 3 to 100 bar, and the ISA altitude that has the same unit Reynolds number at the same Mach number |

A pass/fail line is printed first: whether `P0_driver/P_vac` exceeds the pressure ratio `p0/pe` needed to start the nozzle at `M_exit`.

---

## Console output

Grouped blocks are printed in this order:

1. Driver/vacuum suitability for the run.
2. **DERIVED TUNNEL PARAMETERS**: run time, driver length, diameters, masses, areas, area ratio, pressure ratios, mass flow, dump-tank volume, pumping times, storage volume.
3. **FREESTREAM CONDITIONS DURING RUN**: p0, p_inf, rho0, rho_inf, T_inf, a_inf, u_inf, mu_inf, unit Reynolds number.
4. **CORE RHOMBUS LENGTHS**: downstream, upstream and total uniform core.
5. **CORE GEOMETRY & MODEL SIZING**: time of perfect expansion, maximum model dimension, length and blockage.
6. **REYNOLDS NUMBER MATCHING** and **MODEL SIZE FROM Re_L MATCHING**.
7. **LUDWIEG OPERATING ENVELOPE**: unit Reynolds number and equivalent altitude at the chosen `P0_driver`.

---

## Figure

One 2 x 3 figure, titled with the main run parameters:

1. **Pressure ratio vs time**: `Pe/Pb` (log scale) with the instant of perfect expansion.
2. **Model envelope trade curve**: usable core height/diameter against distance from the exit (rhombus boundary), the model nose-growth line, the rhombus-limited maximum model and the model that matches the target Reynolds number.
3. **Frontal view at the nozzle exit plane**: exit circle, maximum model cross-section and Re-matched model, with blockage values.
4. **Core flow geometry (side view)**: upstream and downstream rhombus, maximum model and Re-matched model, nozzle exit plane at `x = 0`.
5. **Operating envelope**: unit Reynolds number vs `p0` (left axis) and Reynolds-equivalent altitude (right axis), with the target unit Reynolds number and the required `p0`.
6. **Summary panel** with the key numbers.

---

## Assumptions and limitations

- Calorically perfect gas, isentropic nozzle flow, ideal (shock-free) nozzle with a uniform exit.
- The driver conditions are taken as constant during the run (quasi-steady). The pressure drop across the expansion wave in a real Ludwieg tube (a few percent at low tube Mach number) is not modelled.
- Driver length is for a single wave pass, `t_run = 2L/a0`.
- The test core is bounded by straight Mach lines from the nozzle lip. Shear-layer growth of the free jet and the nozzle wall boundary layer reduce the real core; treat the model size as an upper limit.
- The model is placed with its nose at the nozzle exit plane.
- The rhombus is for a circular exit; it is also used for the rectangular model option.
- The minimum dump-tank volume uses the indraft-tunnel sizing correlation of Pope and Goin (1965), in imperial units (see [`docs/THEORY.md`](docs/THEORY.md)).
- Storage-tank sizing assumes isothermal blowdown through the choked throat; the constant 0.5787 corresponds to gamma = 1.4.
- Condensation of moisture in compressed air during the nozzle expansion is not accounted for. For best results use dry air, which is the working gas the nozzle is designed for.
- The altitude equivalence matches unit Reynolds number only (same Mach number, standard atmosphere); it does not match temperature or density.

---

## Repository layout

```
|-- Ludwieg_tunnel_freejet_analysis.m   main script (with local functions)
|-- docs/
|   `-- THEORY.md                       equations used in each section
|-- CHANGELOG.md
|-- CITATION.cff                        citation metadata (GitHub "Cite this repository")
`-- LICENSE                             MIT
```

---

## How to cite

If you use this tool, please cite it (GitHub **"Cite this repository"** uses [`CITATION.cff`](CITATION.cff)).

```bibtex
@software{reddy_ludwieg_designer_and_analyser_2026,
  author  = {Reddy, MRK},
  title   = {{Ludwieg Tube Designer and Analyser}: preliminary design and
             performance analysis of a Ludwieg tube wind tunnel with a
             free-jet test section},
  year    = {2026},
  version = {1.0.0},
  url     = {https://github.com/TheWa1kingDead/Ludwieg_Designer_and_Analyser}
}
```

---

## References

- Ludwieg, H., "Der Rohrwindkanal," *Zeitschrift für Flugwissenschaften* 3(7), 206-216, 1955.
- Pope, A. and Goin, K. L., *High-Speed Wind Tunnel Testing*, Wiley, 1965.
- Anderson, J. D., *Modern Compressible Flow: With Historical Perspective*, 3rd ed., McGraw-Hill, 2003.
- *U.S. Standard Atmosphere, 1976*, NOAA/NASA/USAF, NOAA-S/T 76-1562, 1976.
- Sutherland, W., "The viscosity of gases and molecular force," *Philosophical Magazine* 36(223), 507-531, 1893.

---

## License

Released under the [MIT License](LICENSE).

## Acknowledgements

This tool was developed by MRK Reddy under the guidance of **Prof. S.K. Karthick**, Department of Mechanical and Aerospace Engineering, Indian Institute of Technology Hyderabad, India.

## Contact

**MRK Reddy** · ORCID [0009-0006-8420-6672](https://orcid.org/0009-0006-8420-6672) · GitHub [@TheWa1kingDead](https://github.com/TheWa1kingDead)

Bug reports and suggestions: [Issues](../../issues).
