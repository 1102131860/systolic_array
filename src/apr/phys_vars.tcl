
# VARIABLES RELATED TO PHYSICAL DESIGN
# =====================================================
#  - Used in floorplanning and power network synthesis

# A lot of the variables in this design will make sense to you once you understand that the CELL_HEIGHT
# is and what the PG_TILE dimension is (The pg_tile is one "spatial period" (which you can think of as 
# one unit or tile) of the power grid in lower level metal. Upper level metals are thicker, so have a 
# larger minimum width (hard to fabricate thick but narrow metal structures). To still leave space for routing
# we double the power pitch at higher level metals, making the repeatible unit twice as wide and hence the term
# super_pgtile. 


# ===== Size primitives =====
# SUPERTILE_SIZE: definition of a supertile
# M2M3_TRACK_CHANNEL_WIDTH: width of M2/M3 metal and spacing to next track
set M2M3_TRACK_CHANNEL_WIDTH 0.2
set CELL_HEIGHT 1.8
set SUPERTILE_SIZE [expr 8*$CELL_HEIGHT]

# ===== Core dimensions =====
# CORE_WIDTH_IN_SUPERTILES: the core dimension in units of supertiles
# CORE_HEIGHT_IN_SUPERTILES: the core dimension in units of supertiles

set CORE_WIDTH_IN_SUPERTILES  15;
set CORE_HEIGHT_IN_SUPERTILES 15;

set MIN_SPACE [expr $CELL_HEIGHT/2]

set CORE_WIDTH  [expr $CORE_WIDTH_IN_SUPERTILES * $SUPERTILE_SIZE]
set CORE_HEIGHT [expr $CORE_HEIGHT_IN_SUPERTILES * $SUPERTILE_SIZE]

# ===== Core power ring =====
# Take the time to read what these variables are setting, and compare these values with actual measurements
# based on what is generated after the floorplan stage.
#
# POWER_RING_CLEARANCE: spacing between adjacent power rings, and between the core and innermost ring edge
# POWER_RING_SPACE: space between the IO pads and outermost ring edge
# POWER_RING_WIDTH: width of a core power ring
# POWER_RING_CHANNEL_WIDTH: combined width of the rings, clearances, and spacing
# RING_HLAYER: horizontal ring metal
# RING_VLAYER: vertical ring metal
set POWER_RING_CLEARANCE 2.0
set POWER_RING_SPACE 1.2
set POWER_RING_WIDTH 1.0
# set POWER_RING_CHANNEL_WIDTH [expr 2*$POWER_RING_WIDTH + 2*$POWER_RING_CLEARANCE + $POWER_RING_SPACE]
set POWER_RING_CHANNEL_WIDTH 0
set RING_HLAYER M6
set RING_VLAYER M7

# ===== Chip Finishing =====
# METAL_FILL_SPACING: minimum spacing between metal fill and non-fill metals
set METAL_FILL_SPACING 2.0
