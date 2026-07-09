# OOC constraints for the physical TX_EGRESS_CORE wrapper.
# Reuse the cluster constraints; missing debug-only cluster ports are ignored.
source [file normalize [file join [file dirname [info script]] spadmic_tx_egress_cluster.sdc]]
