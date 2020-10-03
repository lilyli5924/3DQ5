onbreak {resume}

transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# load designs
vlog -sv -work rtl_work single_port_RAM0.v
vlog -sv -work rtl_work single_port_RAM1.v
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET experiment2a.v
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET tb_experiment2a.v

# specify library for simulation
vsim -t 1ps -L altera_mf_ver -lib rtl_work tb_experiment2a

# Clear previous simulation
restart -f

# activate waveform simulation
view wave

# add signals to waveform
add wave Clock_50
add wave Resetn
add wave -unsigned Address
add wave -decimal Read_data
add wave -decimal Write_data
add wave Write_enable

# format signal names in waveform
configure wave -signalnamewidth 1

# run complete simulation
run -all

simstats
