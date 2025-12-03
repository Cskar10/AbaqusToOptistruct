# AbaqusToOptistruct

Tcl scripts for Altair HyperMesh to fix beam element offsets after converting models from Abaqus to OptiStruct.

## Overview

When converting Abaqus models to OptiStruct format, beam element offsets may not be translated correctly. This toolkit corrects the OFFT (Offset Type) from BGG to BOO and recalculates the offset values accordingly.

## Scripts

### OFFT.tcl / AbaqusToOptistructBeams.tcl

Fixes 1D beam element offsets by:
- Converting OFFT from BGG to BOO
- Recalculating offset values (swapping Y and Z components)
- Automatically updating all affected beam elements

## Usage

1. Open your converted model in HyperMesh
2. Source the script in the Tcl console:
   ```tcl
   source "/path/to/OFFT.tcl"
   ```
3. The script automatically runs on all beam elements when sourced

### Available Commands

| Command | Description |
|---------|-------------|
| `fixBeamOffsets` | Fix all beam element offsets in the model |
| `fixBeam <elemId>` | Fix a single beam element by ID |
| `analyzeBeams` | Analyze beam elements in the model |

## Requirements

- Altair HyperMesh 2026 or compatible version
- OptiStruct user profile

## Author

Christos Skarakis

## License

See repository for license information.