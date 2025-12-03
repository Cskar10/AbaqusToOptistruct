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
# Procedure Name   : ::abaqusToOptistruct::beam::fixAllBeamOffsets
# Description      : Fix all beam element offsets in the model
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
    
    hm_usermessage "Processing $totalCount beam elements..."
    
    set fixedCount 0
    set fixedElems {}
    set processed 0
    set lastPercent -1
    
    # Phase 1: Update offset values for all beams that need fixing
    foreach elemId $elemIds {
        incr processed
        
        # Update progress every 1%
        set percent [expr {($processed * 100) / $totalCount}]
        if {$percent != $lastPercent && $percent % 1 == 0} {
            hm_usermessage "Fixing beam offsets: $percent% ($processed/$totalCount)"
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
            
            # Extract offset components
            set offA1 [lindex $offsetA 0]
            set offA2 [lindex $offsetA 1]
            set offA3 [lindex $offsetA 2]
            
            set offB1 [lindex $offsetB 0]
            set offB2 [lindex $offsetB 1]
            set offB3 [lindex $offsetB 2]
            
            # Swap: new_y = old_z, new_z = 0
            set newA1 $offA1
            set newA2 $offA3
            set newA3 0.0
            
            set newB1 $offB1
            set newB2 $offB3
            set newB3 0.0
            
            # Build the offset strings with braces for HyperMesh
            set offsetAStr "\{$newA1 $newA2 $newA3\}"
            set offsetBStr "\{$newB1 $newB2 $newB3\}"
            
            # Set the new offset values
            eval "*setvalue elems id=$elemId STATUS=2 offseta=$offsetAStr"
            eval "*setvalue elems id=$elemId STATUS=2 offsetb=$offsetBStr"
            
            lappend fixedElems $elemId
            incr fixedCount
            
        } err]} {
            if {$debug} {
                puts "Error fixing element $elemId: $err"
            }
        }
    }
    
    # Phase 2: Run autoupdate once on all fixed elements
    if {$fixedCount > 0} {
        hm_usermessage "Updating $fixedCount beam elements..."
        *createmark elems 1 {*}$fixedElems
        *autoupdate1delems mark=1 orient=0 allshells=0 thickness=avg offsetnormal=pos offsetlateral=neg adjustoffset=all offsetends=startend
        *clearmark elems 1
    }
    
    puts "Fixed offsets on $fixedCount beam element(s)"
    hm_usermessage "Fixed offsets on $fixedCount beam element(s)"
    
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
