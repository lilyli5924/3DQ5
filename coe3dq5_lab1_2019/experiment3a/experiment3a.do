onbreak {resume}
transcript on

set PrefMain(saveLines) 50000
.main clear

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# load designs

# insert files specific to your design here

vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET experiment3a.v
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET tb_experiment3a.v

# specify library for simulation
vsim -t 100ps -L altera_mf_ver -lib rtl_work tb_experiment3a

# Clear previous simulation
restart -f

add wave /CLOCK
add wave /RESETN
add wave -radix unsigned /uut/BCD_COUNT_O

run 1us

destroy .structure
destroy .signals
destroy .source

simstats
