# AbaqusToOptistruct

Tcl scripts for Altair HyperMesh to fix beam element offsets after converting models from Abaqus to OptiStruct.

## Overview

When converting Abaqus models to OptiStruct format, beam element offsets may not be translated correctly. This toolkit corrects the OFFT (Offset Type) from BGG to BOO and recalculates the offset values accordingly.

## Scripts

### AbaqusToOptistructBeams.tcl

Fixes 1D beam element offsets by:
- Converting OFFT from BGG to BOO
- Recalculating offset values (swapping Y and Z components)
- Rounding offsets to the nearest millimeter to minimize offset groups
- Batch processing elements with identical offsets for optimal performance
- Automatically updating all affected beam elements

## Usage

1. Open your converted model in HyperMesh
2. Source the script in the Tcl console:
   ```tcl
   source "/path/to/AbaqusToOptistructBeams.tcl"
   ```
3. The script automatically runs on all beam elements when sourced

### Available Commands

| Command | Description |
|---------|-------------|
| `fixBeamOffsets` | Fix all beam element offsets in the model |

## Performance

The script uses optimized batch processing to handle large models efficiently:
- Elements are grouped by their rounded offset values
- Offsets are applied to entire groups using mark-based operations
- A single autoupdate is performed at the end for all fixed elements

This approach significantly reduces processing time for models with many beam elements (e.g., 35K+ beams).

## Requirements

- Altair HyperMesh 2026 or compatible version
- OptiStruct user profile

## Author

Christos Skarakis
