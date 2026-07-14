# L2 HVAC Audit Data Translation — Measures Planning

## Revision Notes (Added after initial plan)

Three architectural gaps identified in original plan — see **Section 13** for full analysis and amended design decisions:

1. **Multi-system buildings:** Original plan assumed one system serves the whole building. L2 audits routinely describe 2–5 distinct systems each serving different zone subsets. The argument schema and dispatch logic must be array-oriented.
2. **HVAC layer decomposition:** "System type" is a conflation of three independent axes — generation (chiller/boiler/DX/HP), air handling (AHU/DOAS/ductwork), and zone terminal (VAV box/FCU/beam/radiant). These must be modeled separately; the monolithic choice argument doesn't hold.
3. **Architecture should be a Python MCP tool, not a Ruby measure:** Existing MCP operations (`add_baseline_system`, `add_doas_system`, `add_vrf_system`, `replace_air_terminals`, `replace_zone_terminal`) already cover most system creation paths and are directly callable from Python. A Python-layer orchestration tool is simpler, more maintainable, and avoids the measure-calling-measure problem entirely. BCL/ComStock measures should be leveraged for gaps, not reimplemented.

---

## Executive Summary

The user has L2 energy audit HVAC requirements that span system type identification, capacity specs, central plant details, distribution configuration, and controls metadata. This document outlines **three strategic options** for translating audit data into OpenStudio models, plus a recommended hybrid approach. **See Section 13 for revised recommendations superseding portions of Sections 3–6.**

---

## 1. L2 Audit Data Inventory

### 1.1 System Type Categories (Primary Router)
- **Terminal Equipment Only:** Split, DX, unitary heat pump, fan coil, chilled beam
- **Centralized with Distribution:** VAV (variable/constant volume), multizone CAV, induction, radiant
- **Advanced Thermal Network:** VRF (variable refrigerant flow)
- **Hybrid/Mixed:** Central plant + DOAS, multi-system buildings

### 1.2 Design Parameters (Numeric Mappings)
| Audit Field | OpenStudio Target | MCP Tool | Notes |
|---|---|---|---|
| System design capacity (kW, Btu/h, tons) | Zone/loop/component autosized settings | `get_sizing_zone_properties`, `get_sizing_system_properties`, `set_sizing_*` | May validate or override autosized values |
| Year installed | Metadata field or object name annotation | Custom property storage | Informational; affects replacement urgency |
| Equipment efficiency (rated) | Coil COP/EIR, boiler/chiller IPLV | `set_component_properties`, custom measure | Retrofit efficiency assumptions |

### 1.3 Central Plant (Boiler/Chiller/Tower)
| Audit Specification | OpenStudio Mapping | Handling Strategy |
|---|---|---|
| Boiler type (fire-tube, water-tube), fuel, capacity, efficiency | `Boiler` object properties + loop wiring | `add_baseline_system` or `add_supply_equipment` |
| Chiller type (centrifugal, screw, reciprocal), capacity | `Chiller` object properties + plant loop | `add_baseline_system` or `add_supply_equipment` |
| Cooling tower / fluid cooler type, capacity | `CoolingTower` / `CondenserLoop` | `add_baseline_system` includes tower autosizing |

### 1.4 Distribution System (Air & Water)
| Audit Field | OpenStudio Proxy | MCP Tool Path |
|---|---|---|
| Air distribution (VAV, CAV, multizone, dual-duct, induction, chilled beam, fan coil, perimeter radiation) | Air loop + terminal type | `add_baseline_system` (standard types) or `replace_air_terminals` (retrofit) |
| Water distribution (variable/constant flow) | Plant loop properties, pump operation | Implicit in baseline system selection; `set_component_properties` for pump |
| Outdoor air (economizer, heat recovery, DOAS) | AirLoopHVAC.airLoopControlType; OutsideAirController; ERV; DOAS loop | `add_doas_system` (DOAS), custom economizer settings |

### 1.5 Controls (Metadata & Operational)
| Audit Data | OpenStudio Representation | Impact |
|---|---|---|
| Pneumatic vs. DDC | Annotation / object name tag | Informational; no direct model impact (assume DDC in OS simulation) |
| Zone controls (core, perimeter, space types) | Thermostatic zones, setpoint managers | Implicit in ASHRAE baseline; can be customized |
| BAS (Building Automation System) | Control feedback loops; scheduling | Scope: if audit specifies demand-reset, enthalpy reset, etc., tune schedules/setpoints |

---

## 2. Key Design Constraints & Assumptions

### 2.1 OpenStudio SDK Baseline System Alignment
- **ASHRAE 90.1 Appendix G** provides 10 baseline system types (1-10).
  - Types 1-3: Unitary equipment (rooftop, split, DX heat pump).
  - Types 4-6: VAV with boiler/chiller central plant.
  - Types 7-8: Two-pipe or four-pipe fan coil + central plant.
  - Types 9-10: VRF with/without DOAS.
- **MCP has tools:** `add_baseline_system(system_type=N)` handles scaffolding, autosizing, and fuel selection.
- **Audit System → Baseline Type Mapping:**
  - Rooftop CAV DX → Type 1
  - Split heat pump → Type 1 (if air-source) or custom measure
  - VAV with boiler + chiller → Type 5/6
  - VRF → Type 9/10
  - DOAS + zone equipment → Hybrid (add_doas_system + replace_air_terminals)

### 2.2 Capacity & Efficiency Data
- Audit provides **design capacity** (e.g., 50 kW cooling, 30 kW heating).
- OpenStudio **autosizes** components based on load calcs during simulation.
- **Strategy:**
  - Input audit capacity as constraints or validation bounds.
  - Audit efficiency values may guide component selection (e.g., "upgrade to COP 3.5 chiller" if current rated is lower).
  - Year installed + condition → age cohort (affects replacement/retrofit decision).

### 2.3 Data Completeness Handling
- Audit may be **partial:** e.g., "VAV system observed; capacity unknown; chiller condition poor."
- Measures must handle **missing fields gracefully:**
  - Use OpenStudio defaults where audit data is absent.
  - Record what audit **did** specify for transparency.
  - Flag missing critical fields (e.g., system type required, capacity optional).

### 2.4 Template & Climate Scope
- ASHRAE baseline systems are template-specific (90.1-2013, 90.1-2016, 90.1-2019, etc.).
- Audit typically does not specify template; measure should accept it as a parameter or infer from building vintage.
- ComStock/common-measures patterns assume 90.1-2019 or DOE reference buildings; adjust if audit specifies earlier vintage.

---

## 3. Strategy Options

### **OPTION A: Single Meta Measure (Monolithic)**

**Structure:** One measure with comprehensive audit data input.

**Arguments ~30–50:**
- `system_type_primary` (Choice: rooftop_cav_dx, split_hp, vav_chiller_boiler, vrf, doas_plus_fan_coil, chilled_beam, etc.)
- `heating_fuel_type` (Choice: Natural Gas, Electric, District Hot Water)
- `cooling_source` (Choice: Air-Cooled, Water-Cooled, District Chilled Water)
- `design_heating_capacity_kw` (Double, optional)
- `design_cooling_capacity_tons` (Double, optional)
- `boiler_fuel`, `boiler_capacity_kw`, `boiler_efficiency_percent` (if central plant)
- `chiller_type`, `chiller_capacity_tons` (if central plant)
- `cooling_tower_type`, `cooling_tower_fan` (if water-cooled)
- `air_distribution_type` (Choice: vav_rhf, cav, multizone, induction, chilled_beam, fan_coil)
- `water_distribution_type` (Choice: variable_flow, constant_flow)
- `outdoor_air_control` (Choice: economizer_temp, economizer_enthalpy, heat_recovery, doas, none)
- `control_type` (Choice: pneumatic, ddc) [informational]
- `zone_control_strategy` (String: core_perimeter, space_types, all_zones)
- `year_installed` (Integer, optional) [metadata]
- `condition_assessment` (Choice: excellent, good, average, poor) [metadata]

**Logic Flow:**
1. Validate input consistency (e.g., "if vrf => no central plant boiler")
2. Dispatch to sub-routine based on system_type_primary
3. Call MCP tools in sequence: `add_baseline_system()`, `set_component_properties()`, `replace_air_terminals()`, etc.
4. Return summary: "Created VAV system with 250-ton chiller, 150-ton boiler; DOAS with ERV; capacity flags: chiller undersized vs. audit"

**Pros:**
- Single entry point; user provides one comprehensive argument dict
- Clear data flow; all audit fields in one place
- Consolidated testing

**Cons:**
- ~50+ arguments → complex argument schema; hard to follow in UI/docs
- Single massive measure: hard to unit-test components in isolation
- If one sub-system fails (e.g., DOAS creation), entire measure fails
- Long maintenance surface; changes to one system type require measure re-edit + re-test

**Best For:** Simple one-off audit translations; building type known; all audit data available.

---

### **OPTION B: Modular Measure Collection (Micro-Measures)**

**Structure:** Multiple specialized measures + one orchestrator ("meta") measure.

**Measures:**
1. **`import_l2_hvac_audit` (Meta/Router)** — accepts full audit data, validates, calls sub-measures
   - Arguments: system_type_primary, design_capacities, central_plant_spec, distribution_type, controls
   - Run: Dispatches to appropriate sub-measures based on system_type_primary
   - Output: Summary of sub-measure results + warnings

2. **`apply_hvac_rooftop_cav_dx_from_audit`** — handle rooftop/split unitary DX
   - Arguments: design_cooling_cap, heating_fuel, cooling_source, year_installed
   - Uses `add_baseline_system(type=1)` + capacity override

3. **`apply_hvac_vrf_from_audit`** — VRF-specific logic
   - Arguments: design_cooling_cap, heating_enabled, doas_present, year_installed
   - Uses `add_vrf_system()` + DOAS integration

4. **`apply_hvac_vav_central_plant_from_audit`** — VAV + boiler/chiller
   - Arguments: chiller_capacity_tons, boiler_capacity_kw, chiller_type, boiler_fuel, air_dist_type, outdoor_air_type
   - Uses `add_baseline_system(type=5/6)` + plant component tuning

5. **`apply_hvac_doas_plus_terminals_from_audit`** — DOAS + zone equipment
   - Arguments: doas_outdoor_air_cfm, zone_terminal_type (fan_coil, chilled_beam, vav_box), outdoor_air_economizer
   - Uses `add_doas_system()` + `replace_air_terminals()`

6. **`set_hvac_central_plant_from_audit`** — boiler/chiller/tower details
   - Arguments: boiler_fuel, boiler_capacity, boiler_efficiency, chiller_capacity, cooling_tower_type
   - Uses `add_supply_equipment()` or `set_component_properties()`

7. **`set_hvac_controls_from_audit`** — DDC/zone control metadata
   - Arguments: control_type_text (pneumatic/ddc), zone_strategy, condition_assessment
   - Stores metadata; sets zone setpoint schedules if specified

8. **Optional: `validate_hvac_audit_data`** — pre-flight validation
   - Checks consistency (e.g., system_type is compatible with distribution_type)
   - Returns True/False + error list

**Workflow:**
- User or meta-measure calls `import_l2_hvac_audit()` with full audit dict.
- Meta-measure parses system_type, calls appropriate sub-measure(s).
- Each sub-measure returns success/failure + details.
- Meta-measure aggregates results, returns unified summary.

**Orchestration Logic (Pseudo-Code):**
```python
def run_meta_measure(audit_data):
    system_type = audit_data['system_type_primary']
    
    if system_type == 'rooftop_cav_dx':
        measure_result = apply_rooftop_cav_dx(audit_data)
    elif system_type == 'vrf':
        apply_vrf_result = apply_vrf(audit_data)
        measure_result = apply_vrf_result
    elif system_type == 'vav_central':
        apply_vav_result = apply_vav_central_plant(audit_data)
        central_plant_result = set_central_plant(audit_data)
        measure_result = merge_results([apply_vav_result, central_plant_result])
    # ... more branches ...
    
    return measure_result
```

**Pros:**
- **Modularity:** Each sub-measure single-responsibility; reusable in other contexts
- **Testability:** Unit-test each sub-measure independently
- **Composability:** User could call sub-measures manually if meta-measure overkill
- **Maintenance:** Change to one system type doesn't touch others
- **Extensibility:** Add new system type → add one new sub-measure, update meta logic

**Cons:**
- More files to maintain (8–10 measures vs. 1)
- Sub-measure orchestration adds complexity (error handling, chaining)
- User sees multiple measures in UI; potential confusion about which to call
- Integration tests more complex (need to mock sub-measure results or call real ones)

**Best For:** Complex heterogeneous audits; frequent updates to system-type logic; reuse of sub-measures across workflows.

---

### **OPTION C: Hybrid Approach (Recommended)**

**Structure:** One primary measure (cleaner than Option A) + helper functions (not separate measures) + tight leverage of existing MCP tools.

**Single Measure: `import_hvac_from_l2_audit.rb`** (~250–300 lines)

**Arguments (~25–30, grouped logically):**
```
# Primary System Classification
- hvac_system_type (Choice: rooftop_dx, split_hp, vav_w_central_plant, vrf, 
                              doas_plus_fan_coils, doas_plus_chilled_beams, etc.)
- heating_fuel_type (Choice: natural_gas, electric, district_hot_water)
- cooling_source_type (Choice: air_cooled, water_cooled, district_chilled_water)

# Design Capacities (Optional, used to validate/override autosizing)
- design_heating_capacity_kw (Double, default: 0 = use autosized)
- design_cooling_capacity_tons (Double, default: 0 = use autosized)

# Central Plant Specifics (if applicable)
- central_plant_present (Boolean, default: true for system_types with central plant)
- boiler_fuel (Choice: natural_gas, electric, propane) [if central_plant_present]
- boiler_capacity_kw (Double, optional)
- boiler_efficiency_percent (Double, default: 80)
- chiller_type (Choice: centrifugal, screw, reciprocal) [if central_plant_present]
- chiller_capacity_tons (Double, optional)
- cooling_tower_fan_type (Choice: two_speed_fan, var_speed_fan) [if water_cooled]

# Air Distribution
- air_distribution_type (Choice: vav_reheat, vav_no_reheat, cav, induction,
                                   chilled_beam, fan_coil, perimeter_radiation)
- outdoor_air_control (Choice: none, economizer_temperature, economizer_enthalpy,
                               heat_recovery, doas)

# Controls & Metadata (Informational)
- control_type (Choice: pneumatic, ddc) [stored as note; no model impact]
- zone_control_strategy (Choice: core_perimeter, all_zones, space_types)
- year_installed (Integer, default: 2015)
- condition_assessment (Choice: excellent, good, average, poor) [stored as note]

# Retrofit-Specific
- replace_existing_hvac (Boolean, default: true)
- preserve_existing_sizing (Boolean, default: false)
```

**Internal Helper Functions (Ruby methods, NOT separate measures):**
```ruby
def map_audit_system_type_to_baseline_type(system_type, cooling_source)
  # rooftop_dx => 1; split_hp + air_cooled => 1; vav_w_central + water_cooled => 5, etc.
end

def create_hvac_from_audit_type(model, system_type, args)
  baseline_type = map_audit_system_type_to_baseline_type(...)
  # Call SDK directly OR leverage MCP recipe for standard types
  # For custom types (e.g., DOAS + chilled beams), use multiple tool calls
end

def apply_capacity_overrides(model, design_heating_kw, design_cooling_tons)
  # Iterate sizing zones/systems; set hard-sized values if audit data provided
end

def apply_distribution_system_refinements(model, air_dist_type, outdoor_air_type)
  # If air_dist_type != standard baseline => replace terminals, add DOAS, etc.
end

def store_hvac_audit_metadata(model, year_installed, condition, control_type)
  # Annotate building.setDescription() or add custom data structures
end
```

**Run Method (~80–100 lines):**
1. Parse & validate arguments (guard against missing critical fields)
2. Call `create_hvac_from_audit_type()` → creates base HVAC scaffold
3. If `design_capacities` provided → `apply_capacity_overrides()`
4. If `air_distribution_type` requires custom terminals → `apply_distribution_system_refinements()`
5. Call `store_hvac_audit_metadata()` → annotate model with audit provenance
6. Return registration summary: "Created VAV system (Type 5); chiller 250t, boiler 150t; DOAS w/ ERV; metadata: installed 2012, condition=average"

**Pros (Best of A & B):**
- **Clean interface:** Single measure, ~30 focused arguments (vs. 50+ for Option A)
- **Testability:** Helper functions unit-testable in isolation; integration tests for full workflow
- **Maintainability:** All code in one file; easy to trace data flow; no measure orchestration overhead
- **Leverage:** Uses existing MCP tools (`add_baseline_system`, `add_doas_system`, `replace_air_terminals`) rather than reinventing HVAC wiring
- **Clarity:** Ruby/Python code comments explain audit field → OS mapping; transparent to reviewers
- **Extensibility:** Add new system type → add helper function + update switch logic; no new measure file

**Cons:**
- Measure file larger (~250–300 lines) vs. modular approach
- If future user wants to call sub-components independently, they can't (workaround: expose helper internally or document SDK calls)

**Best For:** This project; pragmatic balance between modularity and simplicity.

---

## 4. Recommended Approach: **OPTION C (Hybrid)**

### 4.1 Rationale
- **L2 audit has cohesive data model:** All fields relate to one HVAC system (or set of systems serving building). Single measure input is natural.
- **OpenStudio baseline systems are well-defined:** Safer to route through `add_baseline_system()` (proven, tested) than reinvent 10 HVAC archetypes.
- **Audit metadata is supplementary:** Year, condition, controls don't drive model physics; store as annotations, not separate measure calls.
- **Mixed complexity:** Some audits simple (rooftop DX), others complex (VAV + DOAS + ERV). Single measure with helper functions scales both.
- **Reusability:** If user later needs heat pump retrofit or DOAS retrofit independent of L2 framework, they use existing MCP tools directly; meta-measure doesn't block them.

### 4.2 Implementation Roadmap

**Phase 1: Core Measure**
- Implement `import_hvac_from_l2_audit` (Ruby or Python)
- Argument schema covering system types 1–3 (unitary), 5–6 (VAV), 9–10 (VRF), DOAS+terminals
- Helper function: System type → baseline type mapping
- Run method: Dispatch to `add_baseline_system()`, validate, return summary

**Phase 2: Distribution System Refinement** (Helper function)
- Handle air distribution variants (economizer, ERV, DOAS integration)
- Call `add_doas_system()` if `outdoor_air_control == 'doas'`
- Call `replace_air_terminals()` for chilled beam / fan coil retrofits
- Documented as internal helper (not separate measure)

**Phase 3: Capacity & Efficiency Inputs** (Helper function)
- Accept audit design capacities (kW, tons) as validation/override hints
- Use `set_sizing_zone_properties()` / `set_sizing_system_properties()` if audit specifies hard-sized values
- Flag autosized components that differ significantly from audit (warning, not error)

**Phase 4: Metadata & Controls** (Helper function)
- Store year_installed, condition_assessment, control_type in building description or custom model fields
- Optional: Create notes object or annotation object in model
- No direct simulation impact; for audit trail + future retrofit planning

**Phase 5: Testing & Validation**
- Unit tests for system type mapping function
- Integration tests:
  - Audit rooftop CAV DX → verify Type 1 system created, capacity set
  - Audit VAV + boiler/chiller → verify Type 5/6 created with correct fuels
  - Audit DOAS + chilled beams → verify DOAS loop + beam terminals
- Contract test: Audit data round-trip (export → parse → validate)

---

## 5. Argument Design (Option C Detail)

### 5.1 System Type Enumeration
**Choice argument `hvac_system_type`:**
```
rooftop_cav_with_dx_cooling           # ASHRAE Type 1: CAV rooftop unit
rooftop_cav_with_electric_resistance  # ASHRAE Type 2: CAV rooftop, electric heating
split_air_source_heat_pump            # ASHRAE Type 3: Split or mini-split HP
rooftop_hvac_with_gas_boiler_central_chiller  # ASHRAE Type 5: Rooftop CAV + boiler+chiller plant
vav_with_boiler_and_central_chiller   # ASHRAE Type 6: VAV + boiler+chiller
fan_coil_with_central_plant           # ASHRAE Type 7/8: Fan coil + boiler+chiller
vrf_with_electric_heating             # ASHRAE Type 9: VRF air-to-air
vrf_with_doas_and_heating             # ASHRAE Type 10: VRF + DOAS
doas_with_fan_coils                   # DOAS + FCU (post-retrofit or specialty)
doas_with_chilled_beams               # DOAS + chilled/active beams (advanced comfort)
existing_unknown_mixed_system         # Cannot classify; preserve as-is (no retrofit)
```

### 5.2 Capacity & Efficiency Arguments
- `design_heating_capacity_kw` (Double, min: 0, max: 10000, default: 0)
  - Description: "Audit-specified heating design capacity in kW. Leave 0 to use autosized."
- `design_cooling_capacity_tons` (Double, min: 0, max: 5000, default: 0)
  - Description: "Audit-specified cooling design capacity in tons. Leave 0 to use autosized."
- `boiler_efficiency_percent` (Double, min: 70, max: 95, default: 0.80)
- `chiller_efficiency_ip_eer` (Double, min: 8, max: 30, default: 11.0)
  - Description: "Chiller EER (IP units, Btu/Wh). Common range: 10–14 for real units."

### 5.3 Condition & Metadata
- `year_installed` (Integer, min: 1950, max: 2025, default: 2015)
- `condition_assessment` (Choice: excellent, good, average, poor, unknown)
  - Description: "Audit observation: general equipment condition. Informs replacement urgency."
- `control_type_audit` (Choice: pneumatic, direct_digital_control, unknown)
  - Description: "Audit-observed control system type. Informational; model assumes DDC for simulation."

### 5.4 Retrofit Behavior
- `replace_existing_hvac` (Boolean, default: true)
  - Description: "If true, remove existing HVAC loops/zones and rebuild from audit data. If false, preserve existing and layer new systems (advanced, risky)."
- `preserve_existing_sizing` (Boolean, default: false)
  - Description: "If true, don't override autosized values with audit capacity data. Useful if audit capacity is uncertain."

---

## 6. Dispatch Logic (Pseudo-Code)

```python
def run(runner, user_arguments, model):
    # Parse arguments
    system_type = get_choice_argument(user_arguments, 'hvac_system_type')
    heating_fuel = get_choice_argument(user_arguments, 'heating_fuel_type')
    cooling_source = get_choice_argument(user_arguments, 'cooling_source_type')
    design_heating_kw = get_double_argument(user_arguments, 'design_heating_capacity_kw')
    design_cooling_tons = get_double_argument(user_arguments, 'design_cooling_capacity_tons')
    air_dist_type = get_choice_argument(user_arguments, 'air_distribution_type')
    outdoor_air_ctl = get_choice_argument(user_arguments, 'outdoor_air_control')
    year_installed = get_int_argument(user_arguments, 'year_installed')
    condition = get_choice_argument(user_arguments, 'condition_assessment')
    replace_existing = get_bool_argument(user_arguments, 'replace_existing_hvac')
    
    # Validate input consistency
    if system_type.start_with?('vrf') and cooling_source == 'water_cooled':
        runner.registerError("VRF cannot be water-cooled. Choose air_cooled.")
        return false
    
    # Remove existing HVAC if requested
    if replace_existing:
        remove_existing_hvac(model)
    
    # Create HVAC based on audit type
    if system_type == 'rooftop_cav_with_dx_cooling':
        baseline_type = 1
        add_baseline_system_result = call_mcp_add_baseline_system(
            model, baseline_type, heating_fuel, cooling_source
        )
        
    elsif system_type == 'vav_with_boiler_and_central_chiller':
        baseline_type = 6
        boiler_fuel = get_choice_argument(user_arguments, 'boiler_fuel_type')
        boiler_eff = get_double_argument(user_arguments, 'boiler_efficiency_percent')
        chiller_type = get_choice_argument(user_arguments, 'chiller_type')
        chiller_eff = get_double_argument(user_arguments, 'chiller_efficiency_iplv')
        
        add_baseline_system_result = call_mcp_add_baseline_system(
            model, baseline_type, boiler_fuel, cooling_source,
            {boiler_info: {type: 'Boiler', fuel: boiler_fuel, efficiency: boiler_eff},
             chiller_info: {type: chiller_type, efficiency: chiller_eff}}
        )
        
    elsif system_type == 'doas_with_chilled_beams':
        # Create DOAS loop
        doas_result = call_mcp_add_doas_system(model, {outdoor_air_method: outdoor_air_ctl})
        
        # Replace zone equipment with chilled beams
        replace_result = call_mcp_replace_air_terminals(
            model, air_loop_name: (find first air loop), 
            terminal_type: 'CooledBeam' or 'FourPipeBeam'
        )
    
    # (more branches for other system types)
    
    # Apply capacity overrides if provided
    if design_heating_kw > 0 or design_cooling_tons > 0:
        apply_capacity_overrides(model, design_heating_kw, design_cooling_tons)
        runner.registerInfo("Capacity overrides applied: heating=#{design_heating_kw} kW, cooling=#{design_cooling_tons} tons")
    
    # Apply distribution refinements
    if air_dist_type != 'standard' or outdoor_air_ctl != 'none':
        apply_distribution_refinements(model, air_dist_type, outdoor_air_ctl)
    
    # Store metadata
    store_audit_metadata(model, year_installed, condition, control_type_audit)
    
    # Return summary
    runner.registerFinalCondition("HVAC imported from L2 audit: #{system_type}; " \
        "heating_fuel=#{heating_fuel}; cooling_source=#{cooling_source}; " \
        "year=#{year_installed}; condition=#{condition}")
    return true
end
```

---

## 7. Anticipated System Type Coverage

| Audit Description | Baseline Type | MCP Tool Route | Notes |
|---|---|---|---|
| Rooftop unit, CAV, DX cooling, gas heating | 1 | `add_baseline_system(1)` | Standard; fully supported |
| Rooftop unit, CAV, DX cooling, electric heating | 2 | `add_baseline_system(2)` | Less common; supported |
| Split/mini-split air-source heat pump | 3 | `add_baseline_system(3)` | Increasingly common retrofit |
| Unitary vs. heat pump (unknown) | 1 or 3 | User selects via argument | Audit determines |
| VAV + central boiler + chiller | 5 or 6 | `add_baseline_system(5)` or `(6)` | Typical large building |
| Fan coil + chiller (hydro) | 7 or 8 | `add_baseline_system(7)` or `(8)` | High-rise / hotels |
| VRF air-conditioner (cooling only) | 9 | `add_vrf_system()` + disable heating | New construction retrofit |
| VRF heat pump | 9 | `add_vrf_system()` + enable heating | Common retrofit |
| VRF + DOAS (advanced comfort) | 10 | `add_vrf_system()` + `add_doas_system()` | Best-practice retrofit |
| DOAS + fan coils (retrofit to existing) | N/A | `add_doas_system()` + `replace_air_terminals()` | Not a baseline type; custom |
| DOAS + chilled beams (advanced) | N/A | `add_doas_system()` + `replace_air_terminals()` | Premium retrofit; beam-specific setup |
| Multi-zone CAV (dual-duct, etc.) | N/A | Custom / discuss with user | Corner case; may need custom wiring |
| Radiant (hydronic heating/cooling) | N/A | Future measure (`add_radiant_system` exists in MCP) | Out of scope for L2 initial; document as future |
| Unknown/existing mixed system | N/A | `existing_unknown_mixed_system` choice | Keep as-is; user documents manually |

---

## 8. Error Handling & Validation

### 8.1 Pre-Run Validation
- **System type vs. cooling source:** VRF cannot be water-cooled; DX systems cannot be district.
- **Central plant requires plant:** VAV type 5/6 require boiler + chiller specs.
- **DOAS requires outdoor air:** DOAS system must specify economizer/ERV type.
- **Missing critical fields:** Heating fuel, cooling source required; design capacities optional.

### 8.2 Applicability Guards
- **If no existing HVAC:** Measure creates new loops (expected path).
- **If existing HVAC and replace_existing=false:** Warn user that result may be double-stacked (risky).
- **If audit system type = "unknown_mixed":** `registerAsNotApplicable("Cannot retrofit unknown system; user must manually configure HVAC.")` + return true.

### 8.3 Output Messages
- **Initial condition:** "Building has X air loops, Y plant loops. Proceeding to replace with audit-specified system: [type]."
- **Final condition:** "HVAC retrofit complete. [System type] created with [n] zones served; [capacities]; metadata stored (year=[Y], condition=[Z])."
- **Warnings:** "Audit capacity [X tons] differs from autosized [Y tons]; verify audit data or override via preserve_existing_sizing."
- **Errors:** "System type [X] incompatible with cooling source [Y]; measure halted."

---

## 9. Testing Strategy

### 9.1 Unit Tests
- `test_system_type_mapping()` — verify rooftop_cav → 1, vav → 5, vrf → 9, etc.
- `test_argument_validation()` — ensure VRF + water-cooled rejected, etc.
- `test_capacity_override_logic()` — fake model with zones; verify sizing properties updated

### 9.2 Integration Tests
- **Test 1:** Create small office model; audit data: rooftop CAV DX, 50 ton cooling
  - Expected: Type 1 system created, cooling loop autosizes
- **Test 2:** Create medium office; audit: VAV + boiler (150 kW) + chiller (300 tons)
  - Expected: Type 5 system, boiler efficiency set, chiller capacity hard-sized to 300 tons
- **Test 3:** Create DOAS + chilled beams scenario
  - Expected: DOAS loop created with ERV; chilled beam terminals replace VAV; heating/cooling split between loops
- **Test 4:** Metadata round-trip
  - Expected: year_installed, condition_assessment, control_type stored; retrievable in model description

### 9.3 Regression Tests
- Ensure existing `add_baseline_system` tests still pass (no SDK regressions)
- Ensure existing `add_doas_system` tests still pass (no conflicts)

---

## 10. Documentation Plan

### 10.1 Measure SKILL.md
- Overview: "Import HVAC system specifications from L2 energy audit into OpenStudio model."
- Audit data schema: Each argument explained with audit field mapping
- System type table: Rooftop, split, VAV, VRF, DOAS+terminals → baseline types
- Capacity & efficiency guidelines: Typical ranges from ComStock/AHSRAE standards
- Workflow: "Run this measure after geometry is set; before populate constructions/loads/schedules."

### 10.2 Example Arguments JSON
```json
{
  "hvac_system_type": "vav_with_boiler_and_central_chiller",
  "heating_fuel_type": "natural_gas",
  "cooling_source_type": "water_cooled",
  "design_heating_capacity_kw": 150,
  "design_cooling_capacity_tons": 250,
  "central_plant_present": true,
  "boiler_fuel": "natural_gas",
  "boiler_capacity_kw": 150,
  "boiler_efficiency_percent": 0.85,
  "chiller_type": "centrifugal",
  "chiller_capacity_tons": 250,
  "cooling_tower_fan_type": "var_speed_fan",
  "air_distribution_type": "vav_reheat",
  "outdoor_air_control": "economizer_enthalpy",
  "control_type": "ddc",
  "zone_control_strategy": "core_perimeter",
  "year_installed": 2012,
  "condition_assessment": "average",
  "replace_existing_hvac": true,
  "preserve_existing_sizing": false
}
```

### 10.3 Audit Data Mapping Table
| L2 Audit Field | Measure Argument | OpenStudio Target | Notes |
|---|---|---|---|
| System type | hvac_system_type | Air loop + zone terminals | Routes to ASHRAE baseline type |
| Year installed | year_installed | Model annotation | Metadata for retrofit planning |
| Design capacity (cooling) | design_cooling_capacity_tons | Chiller/air loop sizing | Overrides autosized if > 0 |
| System condition (audit observed) | condition_assessment | Model notes | Informs replacement urgency |

---

## 11. Future Extensions

### Phase 2 (Post-Initial Delivery):
1. **Heat pump retrofit variant:** `retrofit_existing_hvac_with_heat_pump` — accepts existing system + retrofit specs
2. **HVAC scheduling:** Accept audit operating hours (e.g., "9–18 weekdays, 8–16 Sat") → translate to OS schedules
3. **Demand-reset logic:** Accept "chiller has enthalpy reset" → configure setpoint managers
4. **Radiant system support:** Add radiant floor/ceiling as air_distribution_type option (requires `add_radiant_system` tool setup)

### Phase 3 (AI-Assisted):
1. **Auto-infer system type:** Given audit text snippet + zone/area data → ML classifier suggests hvac_system_type + confidence
2. **Audit data validation:** Compare proposed HVAC to typical sizes for building type/climate (flag outliers)

---

## 12. Decision Tree for User

**Choose approach based on:**

| Criterion | Option A (Monolithic) | Option B (Modular) | **Option C (Hybrid - Recommended)** |
|---|---|---|---|
| **Audit data completeness** | All in single measure | Sub-measures called conditionally | Single measure, helpers decouple logic |
| **System type variety** | Okay for 5–6 types | Great for 10+ types | Great for 10+ types; cleaner code |
| **User experience** | Simple (one measure) | Confusing (which to call?) | Simple (one measure, clear flow) |
| **Maintenance burden** | High (one 500-line measure) | Medium (8–10 measures + orchestration) | **Low (one measure ~250–300 lines + helpers)** |
| **Testing** | Medium (one big test suite) | Complex (sub-measure mocking) | **Easy (modular test functions)** |
| **Future extension** | Messy (edit monolith) | Easy (add sub-measure) | Easy (add helper + switch branch) |
| **Leverage MCP tools** | Yes (calls add_baseline_system, etc.) | Yes (each sub-measure does) | **Yes (cleaner integration)** |

---

## Summary: Go with Option C

**Recommended first measure:** `import_hvac_from_l2_audit`
- Single entry point; ~30 focused arguments; 250–300 lines Ruby/Python
- Dispatch logic routes to ASHRAE baseline types and MCP tools
- Helper functions for system-type mapping, capacity overrides, distribution refinements, metadata storage
- Integration with existing tools: `add_baseline_system`, `add_doas_system`, `replace_air_terminals`
- Clear testing path: unit tests for helpers, integration tests for end-to-end workflows
- Extensible: Add new system type → add case branch + optional new helper

**Phase 1 delivery:** Rooftop DX, VAV + central plant, VRF, DOAS+terminals
**Phase 2 additions:** Radiant, heat pump retrofits, scheduling, controls refinement

> ⚠️ **This summary is superseded by Section 13 below**, which addresses three gaps:
> multi-system buildings, HVAC layer decomposition, and leverage of existing measures.

---

## 13. Revised Design Decisions — Three Open Issues

### 13.1 Issue: Multiple Systems Serving Different Spaces

**Problem with original plan:**
The argument schema treats the building as having one system. Real L2 audits routinely describe:
- "North retail floor served by 3× rooftop DX units; server room has dedicated precision cooling; office floors have VAV with central chiller."
- "Perimeter zones: fan coil units; interior zones: VAV; lobby: PTAC."

In OpenStudio, each distinct system is a separate `AirLoopHVAC` (or zone-level equipment), each with its own set of `ThermalZone` connections. The single-system argument schema cannot express this.

**Revised approach: Array-of-systems input**

The tool accepts `hvac_systems` as a JSON array. Each element is a system spec:

```json
{
  "hvac_systems": [
    {
      "system_id": "RTU-1",
      "zones_served": ["Retail_NW", "Retail_NE", "Lobby"],
      "generation": "dx_cooling_gas_heating",
      "air_handler": "psz_ac",
      "terminal": "CAV",
      "cooling_capacity_tons": 15,
      "year_installed": 2008,
      "condition": "average"
    },
    {
      "system_id": "VAV-Main",
      "zones_served": ["Office_1", "Office_2", "Conference"],
      "generation": "chiller_boiler",
      "air_handler": "vav",
      "terminal": "VAV_Reheat",
      "chiller_capacity_tons": 150,
      "boiler_fuel": "natural_gas",
      "outdoor_air": "economizer_enthalpy",
      "year_installed": 2015,
      "condition": "good"
    },
    {
      "system_id": "Server-CRAC",
      "zones_served": ["Server_Room"],
      "generation": "dx_cooling",
      "air_handler": "single_zone",
      "terminal": "CAV",
      "cooling_capacity_tons": 5,
      "year_installed": 2018,
      "condition": "excellent"
    }
  ],
  "replace_existing_hvac": true
}
```

**Zone assignment strategies (in priority order):**
1. **Explicit zone names:** `zones_served: ["Zone A", "Zone B"]` — exact match, direct API call
2. **Floor/story pattern:** `zones_served: "floor:2"` — match by story number (requires geometry)
3. **Space-type pattern:** `zones_served: "space_type:Office"` — match zones whose space type contains "Office"
4. **Wildcard glob:** `zones_served: "Office_*"` — match zone names by prefix
5. **Catch-all remainder:** `zones_served: "remaining"` — assign all zones not yet claimed by other systems

**Dispatch loop (Python pseudocode):**
```python
def apply_hvac_systems(audit_data: dict) -> dict:
    results = []
    assigned_zones = set()
    
    for spec in audit_data["hvac_systems"]:
        zones = resolve_zones(model, spec["zones_served"], assigned_zones)
        if not zones:
            results.append({"system_id": spec["system_id"], "ok": False,
                            "error": "No unassigned zones matched zone selector"})
            continue
        
        result = apply_single_system(model, spec, zones)
        if result["ok"]:
            assigned_zones.update(zones)
        results.append(result)
    
    return {"ok": all(r["ok"] for r in results), "systems": results}
```

**Key implication:** A shared central plant (chiller/boiler/tower) created by one system spec should be reused by subsequent systems that need it, not duplicated. The tool must check for existing plant loops before creating new ones.

```python
def get_or_create_chw_plant_loop(model, chiller_spec):
    existing = [l for l in model.getPlantLoops() if "Chilled Water" in l.name().get()]
    if existing and chiller_spec.get("reuse_existing_plant", True):
        return existing[0]
    return create_chw_loop(model, chiller_spec)
```

---

### 13.2 Issue: Delivery System and Fan System — Layer Decomposition

**Problem with original plan:**
`hvac_system_type` is a monolithic choice that conflates three independent HVAC design axes. The audit often specifies these axes separately:

- An auditor might write: **"Chiller plant (water-cooled), DOAS with ERV, four-pipe fan coil units in each zone"** — none of the 10 ASHRAE baseline types directly represents this exact combination.
- Or: **"Packaged RTU (gas/DX) with VAV terminal boxes and hot water reheat"** — this IS Type 5, but the audit described it as three separate observations.

**Three-layer HVAC taxonomy:**

```
Layer 1 — GENERATION (energy source / plant)
  ├── dx_cooling_gas_heating      → PSZ-AC / packaged rooftop (no plant loop)
  ├── dx_cooling_electric_heating → PSZ-AC with electric strip
  ├── heat_pump_dx                → PSZ-HP / split heat pump
  ├── chiller_boiler              → Central plant (CHW + HW loops)
  ├── chiller_only                → CHW loop (electric/gas reheat at terminal)
  ├── boiler_only                 → HW loop (no cooling, e.g., warehouse)
  ├── vrf_outdoor_unit            → VRF system (separate from DOAS)
  ├── district_chilled_water      → CHW from utility
  └── district_hot_water          → HW from utility

Layer 2 — AIR HANDLING (AHU / distribution)
  ├── psz                         → Packaged single zone (one AHU per zone)
  ├── vav_multizone               → Multi-zone VAV (single AHU → multiple zones)
  ├── cav_multizone               → Multi-zone CAV
  ├── doas_dedicated              → Dedicated OA-only air loop (DOAS), zone equip separate
  ├── fan_coil_no_central_ahu     → No central AHU; FCU handles both air + OA via DOAS
  └── none                        → No central air; VRF or radiant handles zone conditioning

Layer 3 — ZONE TERMINAL (zone delivery)
  ├── vav_reheat_hw               → VAV box + HW reheat coil (requires HW loop)
  ├── vav_reheat_electric         → VAV box + electric reheat
  ├── vav_no_reheat               → VAV box only
  ├── pfp_electric                → Parallel fan-powered + electric reheat
  ├── pfp_hw                      → Parallel fan-powered + HW reheat
  ├── cav                         → Constant air volume
  ├── fan_coil_4pipe              → 4-pipe FCU (CHW + HW)
  ├── fan_coil_2pipe              → 2-pipe FCU (cooling only)
  ├── chilled_beam_active         → Active 4-pipe beam (CHW + HW)
  ├── chilled_beam_passive        → Passive 2-pipe cooling beam
  ├── radiant_floor               → Radiant hydronic floor (CHW + HW)
  ├── radiant_ceiling             → Radiant hydronic ceiling
  ├── vrf_indoor_cassette         → VRF indoor unit (tied to VRF outdoor)
  └── ptac_pthp                   → Zone-level packaged terminal
```

**Revised argument schema per system spec:**
```json
{
  "system_id": "Main-Office",
  "zones_served": ["Office_*"],
  "generation": "chiller_boiler",
  "air_handler": "doas_dedicated",
  "terminal": "fan_coil_4pipe",
  "outdoor_air": "energy_recovery",
  "chiller_capacity_tons": 200,
  "boiler_fuel": "natural_gas"
}
```

**Mapping three-layer spec to MCP tool calls:**

| Generation | Air Handler | Terminal | MCP Tool Sequence |
|---|---|---|---|
| dx_cooling_gas_heating | psz | cav | `add_baseline_system(3)` |
| heat_pump_dx | psz | cav | `add_baseline_system(4)` |
| dx_cooling_gas_heating | vav_multizone | vav_reheat_hw | `add_baseline_system(5)` |
| dx_cooling_electric | vav_multizone | pfp_electric | `add_baseline_system(6)` |
| chiller_boiler | vav_multizone | vav_reheat_hw | `add_baseline_system(7)` |
| chiller_boiler | vav_multizone | pfp_electric | `add_baseline_system(8)` |
| chiller_boiler | doas_dedicated | fan_coil_4pipe | `add_doas_system(zone_equipment_type="FanCoil")` |
| chiller_boiler | doas_dedicated | chilled_beam_active | `add_doas_system(zone_equipment_type="FourPipeBeam")` |
| vrf_outdoor_unit | doas_dedicated | vrf_indoor_cassette | `add_vrf_system()` + `add_doas_system()` |
| chiller_boiler | vav_multizone → post-retrofit | chilled_beam_active | `add_baseline_system(7)` then `replace_air_terminals("FourPipeBeam")` |
| boiler_only | none | radiant_floor | `add_radiant_system(radiant_type="Floor")` |

Combinations not in this table require either a custom wiring measure or are invalid.

**Validation matrix (generation × terminal compatibility):**
```
chiller_boiler      → compatible with: vav_reheat_hw, pfp_hw, fan_coil_4pipe, chilled_beam_active, radiant_*
chiller_only        → compatible with: vav_no_reheat, pfp_electric, fan_coil_2pipe, chilled_beam_passive
dx_cooling_*        → compatible with: vav_reheat_electric, cav, pfp_electric (no HW loop)
heat_pump_dx        → compatible with: cav, vav_no_reheat (HP is zone-level; no separate terminal)
vrf_outdoor_unit    → compatible with: vrf_indoor_cassette ONLY
boiler_only         → compatible with: radiant_*, fan_coil_4pipe (heating only)
district_* sources  → same compatibility as chiller_boiler / boiler_only equiv.
```

---

### 13.3 Issue: Leverage Existing Measures (BCL + ComStock)

**Problem with original plan:**
Option C proposes writing a new Python/Ruby tool that re-implements HVAC creation logic. But much of this logic already exists in tested, maintained measures. Not leveraging them means:
- Duplicating complex HVAC SDK wiring code
- Missing version-specific SDK quirks already handled in openstudio-standards
- Maintenance divergence when standards gem updates

**Inventory of what already exists (what not to reinvent):**

#### MCP Python tools (call directly; already tested):
| Tool | Covers |
|---|---|
| `add_baseline_system(type=1–10)` | All ASHRAE 90.1 baseline types; creates full system with plant loops |
| `add_doas_system(zone_equipment_type)` | DOAS + FanCoil / FourPipeBeam / ChilledBeam / Radiant |
| `add_vrf_system()` | VRF outdoor + indoor + optional DOAS |
| `add_radiant_system(radiant_type)` | Radiant floor/ceiling hydronic |
| `replace_air_terminals(air_loop, terminal_type)` | Bulk terminal swap on existing air loop |
| `replace_zone_terminal(zone, terminal_type)` | Per-zone terminal swap |
| `add_supply_equipment(loop, equip_type)` | Add boiler/chiller/tower to existing plant loop |
| `set_component_properties(object, props)` | Set efficiency/capacity on existing component |

#### ComStock bundled measures (call via `apply_measure`; in `/opt/comstock-measures/`):
The ComStock repository contains system-type-specific upgrade measures. Need to verify exact names in container, but known classes include:
- **HP-RTU measures:** Replace gas/DX rooftop with heat pump RTU (ComStock HVAC upgrade suite)
- **VRF replacement:** Replace zone-by-zone systems with VRF + DOAS
- **DOAS retrofit:** Add DOAS to existing building with zone equipment
- **System efficiency upgrades:** Chiller/boiler efficiency setters (may overlap with `set_component_properties`)
- `create_typical_building_from_model` — whole-building HVAC/constructions/loads from prototype (useful when audit data is sparse and building type is known)

These should be **used as-is via `apply_measure`** when they match the audit specification,  not reimplemented. The meta-tool's dispatch logic becomes:
```
if audit combination matches existing ComStock measure → call apply_measure(measure_name, args)
else if combination maps to standard MCP tools → call MCP tool sequence
else → flag as requiring custom measure + document the gap
```

#### BCL measures (download required; less reliable for bundled deployment):
BCL has hundreds of HVAC measures. The deployment risk (measures not pre-installed) makes BCL a secondary source. Use BCL measures only when:
- The specific audit scenario has no ComStock or MCP equivalent
- The BCL measure is stable and well-maintained (check version + test coverage)
- Fetching the measure on first use is acceptable (via `run_osw` with BCL measure reference)

**Revised architecture: Python MCP tool, not a Ruby measure**

The original Option C proposed a Ruby measure. This was wrong in retrospect:
- Ruby measures can't call other Ruby measures directly at runtime — they'd need to be chained in the OSW workflow
- Python MCP tool can call MCP operations (`add_baseline_system_op()`, `add_doas_system_op()`, etc.) in sequence in pure Python
- Error handling, result aggregation, and logging are cleaner in Python
- The tool is testable with pytest (consistent with project testing standards)

**Revised architecture:**

```
New Python MCP skill: hvac_audit_import/
├── tools.py        — register("import_hvac_from_l2_audit") MCP tool
├── operations.py   — apply_hvac_systems(audit_data_json) → {"ok", "systems", ...}
├── resolver.py     — resolve_zones(), classify_to_layers(), map_to_tools()
└── validator.py    — validate_system_spec(), check_layer_compatibility()
```

`operations.py::apply_hvac_systems()` calls existing operations in `hvac_systems/operations.py` directly:
```python
from mcp_server.skills.hvac_systems.operations import (
    add_baseline_system, add_doas_system, add_vrf_system,
    add_radiant_system, replace_air_terminals
)
```

A Ruby measure wrapper is needed **only if** the user needs to apply audit data through an OSW workflow (e.g., for `mcp_run_osw`). In that case, the Ruby measure is a thin adapter that calls `openstudio-standards` SDK calls mirroring what the Python tool does — and is developed after the Python tool is stable and tested.

---

### 13.4 Revised Implementation Plan

**What changes from original Option C:**

| Aspect | Original Option C | Revised Plan |
|---|---|---|
| **Input schema** | Single system, flat arguments | Array of system specs, each with generation + air_handler + terminal axes |
| **Language** | Ruby measure | Python MCP skill (Ruby wrapper optional/later) |
| **Dispatch to** | MCP tools (via SDK calls inside Ruby) | Existing Python MCP operations directly |
| **Leverage existing** | Mentioned but not detailed | Explicit: map each combination to existing tool first; only gap-fill |
| **Multi-system** | Not handled | Core feature: array input, zone assignment, shared plant loop reuse |
| **Layer decomposition** | Monolithic `hvac_system_type` | Three explicit axes: generation, air_handler, terminal |
| **BCL/ComStock** | Not leveraged | ComStock bundled measures called via `apply_measure` for retrofit scenarios |

**Phase 1 (Python MCP tool — single system, common cases):**
- Input: single system spec JSON (not array, for simplicity)
- Classification: map generation + air_handler + terminal → MCP tool call
- Zone assignment: accepts `thermal_zone_names` list (same as existing tools)
- Coverage: the 8 most common layer combinations (covers ~80% of real buildings)

**Phase 2 (Array input + zone assignment):**
- Extend to accept array of system specs
- Add zone resolver: explicit names / floor pattern / space-type glob / "remaining"
- Add shared plant loop detection and reuse
- Add validation matrix enforcement

**Phase 3 (ComStock integration + Ruby wrapper):**
- Map HP-RTU, VRF-replacement, DOAS-retrofit audit specs to ComStock bundled measures via `apply_measure`
- Add Ruby measure wrapper for OSW workflow compatibility
- Document gap combinations requiring custom measures

---

### 13.5 Revised Common Combinations Coverage Table

| Audit Description | Layer: Generation | Layer: Air Handler | Layer: Terminal | Resolution |
|---|---|---|---|---|
| Rooftop gas/DX, CAV | dx_cooling_gas_heating | psz | cav | `add_baseline_system(3)` |
| Rooftop gas/DX, VAV | dx_cooling_gas_heating | vav_multizone | vav_reheat_hw | `add_baseline_system(5)` |
| Chiller + boiler, VAV+HW reheat | chiller_boiler | vav_multizone | vav_reheat_hw | `add_baseline_system(7)` |
| Chiller + boiler, VAV+PFP | chiller_boiler | vav_multizone | pfp_electric | `add_baseline_system(8)` |
| Chiller + boiler, DOAS + FCU | chiller_boiler | doas_dedicated | fan_coil_4pipe | `add_doas_system(FanCoil)` |
| Chiller + boiler, DOAS + 4-pipe beams | chiller_boiler | doas_dedicated | chilled_beam_active | `add_doas_system(FourPipeBeam)` |
| VRF outdoor + DOAS | vrf_outdoor_unit | doas_dedicated | vrf_indoor_cassette | `add_vrf_system()` + `add_doas_system()` |
| Boiler + radiant floor | boiler_only | none | radiant_floor | `add_radiant_system("Floor")` |
| HP-RTU retrofit (replace DX rooftop w/ HP) | heat_pump_dx | psz | cav | `add_baseline_system(4)` or ComStock HP-RTU measure |
| Chiller + DOAS + chilled beams (passive) | chiller_only | doas_dedicated | chilled_beam_passive | `add_doas_system(ChilledBeams)` |
| PTAC/PTHP zone-level | dx_or_hp_zone_level | none | ptac_pthp | `add_baseline_system(1)` or `(2)` |
| District CHW + DOAS + FCU | district_chilled_water | doas_dedicated | fan_coil_2pipe | `add_doas_system(FanCoil)` with `cooling_fuel="DistrictCooling"` |
| Fan coil perimeter + VAV interior (MIXED) | chiller_boiler | vav_multizone (interior) + doas (perimeter) | vav_reheat_hw + fan_coil_4pipe | Two system specs: VAV spec + FCU spec |

**Combinations requiring custom wiring (no existing tool covers exactly):**
- Dual-duct VAV systems
- Induction terminal units (rarely modeled in OpenStudio)
- Multi-zone CAV (large older buildings)
- Chilled water + VRF hybrid (rare)

