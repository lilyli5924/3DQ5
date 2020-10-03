onbreak {resume}

transcript on

cd simulation/modelsim

if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

# load designs
vlog -sv -work gate_work experiment1b.vo
vlog -sv -work gate_work ../../tb_experiment1b.v

# specify library for simulation
vsim -t 100ps -L cycloneive_ver -L altera_ver -lib gate_work tb_experiment1b

# Clear previous simulation
restart -f

# activate waveform simulation
view wave

# add waves to waveform
add wave Clock_50
add wave VGA_Hsync
add wave VGA_Vsync
add wave -hexadecimal VGA_red
add wave -hexadecimal VGA_green
add wave -hexadecimal VGA_blue

# format signal names in waveform
configure wave -signalnamewidth 1

# run complete simulation
run -all

simstats
