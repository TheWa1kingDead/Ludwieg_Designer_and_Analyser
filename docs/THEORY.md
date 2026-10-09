# Theory and method

Equations used in `Ludwieg_tunnel_freejet_analysis.m`, in the order of the script sections.

Notation: $p_0$, $T_0$ driver (stagnation) pressure and temperature, $M_e$ exit Mach number, $D_e$ nozzle exit diameter, $r_e = D_e/2$, $\gamma$ ratio of specific heats, $R$ gas constant, $t_r$ run time.

---

## Section 4: Derived tunnel quantities

### Isentropic exit (freestream) conditions

$$
\frac{T_e}{T_0} = \left(1+\frac{\gamma-1}{2}M_e^2\right)^{-1}, \quad
\frac{p_e}{p_0} = \left(\frac{T_e}{T_0}\right)^{\frac{\gamma}{\gamma-1}}, \quad
\frac{\rho_e}{\rho_0} = \left(\frac{T_e}{T_0}\right)^{\frac{1}{\gamma-1}}
$$

$$
\frac{A_e}{A^*} = \frac{1}{M_e}\left[\frac{2}{\gamma+1}\left(1+\frac{\gamma-1}{2}M_e^2\right)\right]^{\frac{\gamma+1}{2(\gamma-1)}}
$$

$$
\rho_0 = \frac{p_0}{R T_0}, \quad a_e = \sqrt{\gamma R T_e}, \quad u_e = M_e a_e, \quad Re' = \frac{\rho_e u_e}{\mu_e}
$$

with Sutherland's law

$$
\mu(T) = \mu_0\left(\frac{T}{T_{ref}}\right)^{3/2}\frac{T_{ref}+S}{T+S}
$$

### Throat and mass flow

$$
A_e = \frac{\pi}{4}D_e^2, \qquad A^* = \frac{A_e}{A_e/A^*}, \qquad D^*_{eq} = \sqrt{4A^*/\pi}
$$

$$
\dot m = A^*\sqrt{\frac{\gamma}{R}}\left(\frac{2}{\gamma+1}\right)^{\frac{\gamma+1}{2(\gamma-1)}}\frac{p_0}{\sqrt{T_0}}
$$

### Driver tube

For a Ludwieg tube the run lasts until the expansion wave, reflected from the closed end, returns to the nozzle. For a single pass

$$
t_r = \frac{2L_d}{a_0} \quad\Rightarrow\quad L_d = \frac{t_r a_0}{2}, \qquad a_0 = \sqrt{\gamma R T_0}
$$

Driver volume and mass for the chosen diameter: $V_d = \frac{\pi}{4}D_d^2 L_d$, $m_d = \rho_0 V_d$.

The minimum tube diameter keeps the tube Mach number at or below $M_{i,max}$:

$$
D_{d,min} = \sqrt{\frac{4}{\pi}\,A^*\,\left.\frac{A}{A^*}\right|_{M_{i,max}}}
$$

### Starting pressure ratio

Required (ideal nozzle exhausting at its design pressure): $PR_v = p_0/p_e$.
Available: $PR_{av} = p_0/p_{vac}$. The run is flagged as possible when $PR_{av} \ge PR_v$.

### Minimum dump-tank volume

Empirical indraft-tunnel correlation, evaluated in imperial units ($A^*$ in ft$^2$, temperatures in deg R, $V$ in ft$^3$) and converted to m$^3$:

$$
V_{dump} = \frac{28.35\,A^*\,T_e\,t_r\,PR_v}{\sqrt{T_0}\left[1-\left(p_{vac}/p_e\right)^{1/n}\right]}
$$

with $n$ the polytropic index of the tank compression.

### Pump-down and compressor times

Vacuum pump of constant volumetric speed $Q$ evacuating $V_{dump}$ from ambient to $p_{vac}$:

$$
t_{vac} = \frac{V_{dump}}{Q}\ln\frac{p_{amb}}{p_{vac}}
$$

Compressor of free-air delivery $Q_c$ (CFM) filling a receiver of volume $V_c$ (ft$^3$) from $p_i$ to $p_f$ (psi):

$$
t_{comp} = \frac{V_c\,(p_f - p_i)}{14.7\,Q_c} \quad \text{[min]}
$$

### Minimum storage volume

Isothermal blowdown of the storage tank through the choked throat:

$$
p_s(t) = p_{s,i}\exp\left(-\frac{0.5787\,A^* a_0\,t}{V_s}\right)
$$

Requiring $p_s(t_r) \ge 1.2\,p_0$ gives

$$
V_{s,min} = -\frac{0.5787\,A^* a_0\,t_r}{\ln\left(1.2\,p_0/p_{s,i}\right)}
$$

where $0.5787 = \left(\frac{2}{\gamma+1}\right)^{\frac{\gamma+1}{2(\gamma-1)}}$ for $\gamma = 1.4$.

---

## Section 5: Uniform test core (rhombus)

Downstream of the exit of an ideal nozzle the uniform core is bounded by the Mach waves from the nozzle lip, which meet on the axis at

$$
\mu_e = \arcsin\frac{1}{M_e}, \qquad L_{down} = \frac{r_e}{\tan\mu_e}
$$

Inside the nozzle, the last characteristic of the MOC design runs from the axis to the exit lip with the same Mach angle, so the upstream uniform region has the same length,

$$
L_{up} = \frac{r_e}{\tan\mu_e} = L_{down}
$$

The total uniform-core extent is $L_{up} + L_{down}$. The available core diameter at a distance $x$ downstream of the exit is

$$
D_{avail}(x) = 2\max\left(0,\; r_e - x\tan\mu_e\right)
$$

---

## Sections 6-7: Dump-tank filling

The dump tank is a rigid adiabatic control volume receiving the nozzle mass flow at stagnation enthalpy $c_pT_0$:

$$
\frac{dm}{dt} = \dot m, \qquad m\frac{dT}{dt} = \dot m\left(\gamma T_0 - T\right), \qquad p = \frac{mRT}{V_{dump}}
$$

integrated with an explicit Euler step from $p = p_{vac}$, $T = T_0$. The driver conditions are held constant over the run.

## Section 8: Pressure ratio

$$
PR(t) = \frac{p_e}{p_b(t)}, \qquad p_b = p_{dump}
$$

$PR > 1$ under-expanded, $PR = 1$ perfectly expanded, $PR < 1$ over-expanded. The time of perfect expansion is where $PR$ is closest to 1.

## Section 9: Model sizing

The model base dimension $d$ (diameter or height) and its length are linked by

$$
L(d) = \frac{d}{\tan\alpha_{axi}} \quad\text{(axisymmetric)}, \qquad
L(h) = \frac{2h}{\tan\alpha_u + \tan\alpha_l} \quad\text{(rectangular)}
$$

With the nose at the exit plane, the largest model has its base on the rhombus boundary:

$$
d - D_{avail}\big(L(d)\big) = 0
$$

solved with `fzero`. Blockage is the model frontal area over $A_e$.

## Section 10: Reynolds number matching

For a model of length $L$:

$$
Re_L = \frac{\rho_e u_e L}{\mu_e}
$$

At fixed $M_e$ and $T_0$, $u_e$ and $\mu_e$ are fixed, so the required freestream density, and from it the driver pressure, are

$$
\rho_{req} = \frac{Re_{L,target}\,\mu_e}{u_e L}, \qquad p_{0,req} = \frac{\rho_{req} R T_e}{p_e/p_0}
$$

Conversely, at the chosen $p_0$ the model length that gives the target is $L_{Re} = Re_{L,target}\,\mu_e/(\rho_e u_e)$.

## Section 11: Operating envelope and Reynolds-equivalent altitude

For $p_0$ from 3 to 100 bar the tunnel unit Reynolds number is $Re'_{tunnel}(p_0) = \rho_e u_e/\mu_e$.
For the International Standard Atmosphere (`atmosisa`, 0 to 84.852 km) at the same Mach number,

$$
Re'_{flight}(h) = \frac{\rho(h)\,M_e\,a(h)}{\mu(T(h))}
$$

The Reynolds-equivalent altitude is the $h$ for which $Re'_{flight}(h) = Re'_{tunnel}(p_0)$, found by interpolation. Values above the sea-level flight Reynolds number are left undefined.

---

## References

- Ludwieg, H., "Der Rohrwindkanal," *Zeitschrift für Flugwissenschaften* 3(7), 206-216, 1955.
- Pope, A. and Goin, K. L., *High-Speed Wind Tunnel Testing*, Wiley, 1965.
- Anderson, J. D., *Modern Compressible Flow: With Historical Perspective*, 3rd ed., McGraw-Hill, 2003.
- *U.S. Standard Atmosphere, 1976*, NOAA/NASA/USAF, NOAA-S/T 76-1562, 1976.
