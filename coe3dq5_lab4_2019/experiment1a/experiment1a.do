onbreak {resume}

transcript on

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# load designs
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET VGA_Controller.v
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET experiment1a.v
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET tb_experiment1a.v

# specify library for simulation
vsim -t 100ps -L altera_mf_ver -lib rtl_work tb_experiment1a

# Clear previous simulation
restart -f

# activate waveform simulation
view wave

# add signals to waveform
add wave Clock_50
add wave uut/system_resetn
add wave -unsigned uut/pixel_X_pos
add wave -unsigned uut/pixel_Y_pos
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
