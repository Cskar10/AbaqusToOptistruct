################################################################################################################################
#
# Release          : HW2026
# File             : AbaqusToOptistructBeams.tcl
# Date             : Dec 02, 2025
# Created by       : Christos Skarakis
# Purpose          : Fix beam element offsets after Abaqus to OptiStruct conversion
#                    Converts OFFT from BGG to BOO and recalculates offset values
#
################################################################################################################################

namespace eval ::abaqusToOptistruct::beam {
    variable debug 0
}

################################################################################################################################
# Procedure Name   : ::abaqusToOptistruct::beam::roundToMm
# Description      : Round a value to the nearest millimeter
# Arguments        : value - the value to round
# Returns          : Rounded value
################################################################################################################################
proc ::abaqusToOptistruct::beam::roundToMm {value} {
    return [expr {round($value)}]
}

################################################################################################################################
# Procedure Name   : ::abaqusToOptistruct::beam::fixAllBeamOffsets
# Description      : Fix all beam element offsets in the model (optimized batch processing)
# Returns          : Number of elements fixed
################################################################################################################################
proc ::abaqusToOptistruct::beam::fixAllBeamOffsets {} {
    variable debug
    
    # Get all 1D elements (config 60 = bar/beam)
    *createmark elems 1 "by config" 60
    set elemIds [hm_getmark elems 1]
    *clearmark elems 1
    
    set totalCount [llength $elemIds]
    
    if {$totalCount == 0} {
        puts "No beam elements found in model"
        hm_usermessage "No beam elements found"
        return 0
    }
    
    hm_usermessage "Analyzing $totalCount beam elements..."
    puts "Analyzing $totalCount beam elements..."
    
    # Dictionary to group elements by their rounded offset key
    # Key format: "offA1,offA2,offA3,offB1,offB2,offB3"
    array set offsetGroups {}
    set fixedElems {}
    set processed 0
    set lastPercent -1
    
    # Phase 1: Collect all elements and group by rounded offset values
    foreach elemId $elemIds {
        incr processed
        
        # Update progress every 5%
        set percent [expr {($processed * 100) / $totalCount}]
        if {$percent != $lastPercent && $percent % 5 == 0} {
            hm_usermessage "Analyzing beam offsets: $percent% ($processed/$totalCount)"
            set lastPercent $percent
        }
        
        if {[catch {
            # Get current OFFT value
            set offt [hm_getvalue elems id=$elemId dataname=1dofft]
            
            # Skip if already BOO
            if {$offt eq "BOO"} {
                continue
            }
            
            # Get current offset values
            set offsetA [hm_getvalue elems id=$elemId dataname=offseta]
            set offsetB [hm_getvalue elems id=$elemId dataname=offsetb]
            
            # Extract and transform offset components
            # Swap: new_y = old_z, new_z = 0, round to nearest mm
            set newA1 [roundToMm [lindex $offsetA 0]]
            set newA2 [roundToMm [lindex $offsetA 2]]
            set newA3 0
            
            set newB1 [roundToMm [lindex $offsetB 0]]
            set newB2 [roundToMm [lindex $offsetB 2]]
            set newB3 0
            
            # Create key for grouping
            set key "${newA1},${newA2},${newA3},${newB1},${newB2},${newB3}"
            
            # Add element to its offset group
            if {[info exists offsetGroups($key)]} {
                lappend offsetGroups($key) $elemId
            } else {
                set offsetGroups($key) [list $elemId]
            }
            
            lappend fixedElems $elemId
            
        } err]} {
            if {$debug} {
                puts "Error analyzing element $elemId: $err"
            }
        }
    }
    
    set fixedCount [llength $fixedElems]
    set groupCount [array size offsetGroups]
    
    if {$fixedCount == 0} {
        puts "No beam elements need fixing (all already BOO)"
        hm_usermessage "No beam elements need fixing"
        return 0
    }
    
    puts "Found $fixedCount elements to fix in $groupCount offset groups"
    hm_usermessage "Applying offsets to $fixedCount elements in $groupCount groups..."
    
    # Phase 2: Apply offsets in batch per group using mark-based operations
    set groupNum 0
    foreach {key elemList} [array get offsetGroups] {
        incr groupNum
        
        # Parse the offset values from key
        set parts [split $key ","]
        set newA1 [lindex $parts 0]
        set newA2 [lindex $parts 1]
        set newA3 [lindex $parts 2]
        set newB1 [lindex $parts 3]
        set newB2 [lindex $parts 4]
        set newB3 [lindex $parts 5]
        
        set elemCount [llength $elemList]
        if {$groupNum % 10 == 0 || $groupNum == $groupCount} {
            hm_usermessage "Applying offset group $groupNum/$groupCount"
        }
        
        # Build offset strings
        set offsetAStr "\{$newA1 $newA2 $newA3\}"
        set offsetBStr "\{$newB1 $newB2 $newB3\}"
        
        # Create mark with all elements in this group and apply offset to entire mark
        *createmark elems 1 {*}$elemList
        eval "*setvalue elems mark=1 STATUS=2 offseta=$offsetAStr"
        eval "*setvalue elems mark=1 STATUS=2 offsetb=$offsetBStr"
        *clearmark elems 1
    }
    
    # Phase 3: Run autoupdate once on all fixed elements
    hm_usermessage "Updating $fixedCount beam elements..."
    puts "Updating $fixedCount beam elements..."
    *createmark elems 1 {*}$fixedElems
    *autoupdate1delems mark=1 orient=0 allshells=0 thickness=avg offsetnormal=pos offsetlateral=neg adjustoffset=all offsetends=startend
    *clearmark elems 1
    
    puts "Fixed offsets on $fixedCount beam element(s) in $groupCount groups"
    hm_usermessage "Fixed offsets on $fixedCount beam element(s) in $groupCount groups"
    
    return $fixedCount
}

################################################################################################################################
# Global commands
################################################################################################################################
proc fixBeamOffsets {} {
    return [::abaqusToOptistruct::beam::fixAllBeamOffsets]
}

proc fixBeam {elemId} {
    set result [::abaqusToOptistruct::beam::quickFix $elemId]
    if {$result} {
        puts "Fixed beam element $elemId"
    } else {
        puts "No fix needed for beam element $elemId (OFFT is not BGG)"
    }
    return $result
}

proc analyzeBeams {} {
    ::abaqusToOptistruct::beam::analyzeBeams
}

################################################################################################################################
# Auto-run fixBeamOffsets when script is sourced
################################################################################################################################
puts ""
puts "Running beam offset fix..."
set ::abaqusToOptistruct::beam::fixCount [::abaqusToOptistruct::beam::fixAllBeamOffsets]
puts ""
