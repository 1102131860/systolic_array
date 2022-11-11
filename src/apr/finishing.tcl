
# FINAL FINISHING
# ==========================================================================

# Load variable definitions
source ${SRC_DIR}/config.tcl
source ${SRC_DIR}/phys_vars.tcl

# ==========================================================================
# INSERT ANTENNA DIODES.
# Plasma  etch applied to metal layers in the fabrication process causes charge 
# to be deposited on metal wires, This charge, if connected to only a gate terminal
# of a MOSFET, will cause a voltage build-up that can damage the MOS device. 
# Two techniques are commonly used to alleviate this issue. 
# (1) Switching to another metal level during routing (to reduce the maximum dose 
#     of charge exposed to the MOS)
# (2) Inserting a diode in a manner that when the metal is being etched, the charge
#     has a path to bleed through the diode insted of building up at the gate. Note that
#     the diode is connected with it's p terminal to GND, and it's n terminal to the net.
#     Therefore, cmos voltage levels will not forward-bias the diode.
# SAPR tools can insert antenna diodes (which are in the stdcell library) for you to 
# avoid a lot of post-layout antenna violation headaches.
# ==========================================================================

if {$FIX_ANTENNA} {
   if { $USE_ANTENNA_DIODES && [file exists [which $ANTENNA_RULES_FILE]] && $ROUTING_DIODES != ""} {
      source $ANTENNA_RULES_FILE
      set_route_zrt_detail_options \
         -antenna true \
         -diode_libcell_names $ROUTING_DIODES \
         -insert_diodes_during_routing true
      route_zrt_detail -incremental true
   }
}

# Replace fill with decap instead of fill. Can't hurt (other than in terms of gate leakage :))
remove_stdcell_filler -stdcell
if {$FINISH_WITH_DECAP} {
   insert_stdcell_filler \
      -cell_with_metal $DECAP_CELLS \
      -connect_to_power VDD \
      -connect_to_ground VSS \
      -respect_keepout
   
   insert_stdcell_filler \
      -cell_with_metal $FILL_CELLS \
      -connect_to_power VDD \
      -connect_to_ground VSS \
      -respect_keepout
}

# Connect P/G: Connect power and ground pins to power and ground nets. For standard single-vdd 
# designs, this connection can be made automatically (no options fed to the derive_pg_connection
# command.

derive_pg_connection
verify_pg_nets


# Check LVS/DRC
# ==========================================================================
verify_zrt_route
verify_lvs -ignore_min_area
