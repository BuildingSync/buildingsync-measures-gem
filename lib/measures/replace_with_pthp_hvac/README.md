# Replace HVAC with PTHP

Removes HVAC dedicated to selected zones and installs packaged terminal heat pumps while preserving unrelated systems and plant loops.

## Use this measure when

- A retrofit or comparison case replaces complete serving systems with PTHPs.
- Every zone on an affected shared air loop is selected.

Do not use it for efficiency-only changes.

## Arguments

| Argument | Meaning | Units/default |
|---|---|---|
| `target_zone_names` | Comma-separated exact zones whose HVAC will be replaced | Required |
| `standards_template` | Template used for replacement creation | Default `90.1-2019` |

## BuildingSync mapping

| Measure argument | Candidate BuildingSync field(s) | Selection rule | Conversion | Confidence/notes |
|---|---|---|---|---|
| Replacement selection — L200 (preferred) | On the proposed `HVACSystem` (`@Status = "Proposed"`): `HeatingAndCoolingSystems/CoolingSources/CoolingSource/CoolingSourceType/DX/DXSystemType = "Packaged terminal heat pump (PTHP)"` + `HeatingSources/HeatingSource/HeatingSourceType/HeatPump/HeatPumpType = "Packaged Terminal"` + associated `Delivery/DeliveryType/ZoneEquipment`; verify `CoolingSourceID`, `HeatingSourceID`, and delivery IDREFs | Require matching proposed terminal heat-pump cooling, heating, and zone-delivery records | Exact enums plus IDREF relationships | High when all records are linked |
| Replacement selection — L100/L000 fallback only | Proposed `HVACSystem/PrincipalHVACSystemType = "Packaged Terminal Heat Pump"` | Use only if proposed L200 evidence is unavailable and not contradictory | Exact enum | Medium |
| MANUAL CHECK | Proposed status is unclear, either exact enum is absent, cooling/heating/delivery records cannot be joined, or central-air delivery is indicated | Confirm PTHP topology and full existing shared-system scope | Manual classification | Required if any listed condition applies |
| `target_zone_names` | Proposed HVAC/component `LinkedPremises/ThermalZone/LinkedThermalZoneID/@IDref`; Space and Section alternatives use `LinkedSpaceID/@IDref` and `LinkedSectionID/@IDref` | Resolve every served premise and include all zones on shared existing loops | Comma-separated names | Incomplete scope is rejected when detectable |
| `standards_template` | No direct field | Workflow policy | None | Not an audited property |

## Usage

1. Resolve every premise served by the replacement system.
2. Confirm complete shared-loop scope.
3. Run this measure, then apply audited efficiencies with focused modifiers.

## Limitations

Existing plant loops are preserved. OpenStudio model edits are not transactional, so production workflows should checkpoint the model before replacement.
