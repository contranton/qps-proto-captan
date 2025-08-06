package require fileutil

set path_script [ file dirname [file normalize [ info script ] ] ]
set path_top ${path_script}/../..
set path_src ${path_top}/fw/srcs
set path_build ${path_top}/fw/build

file mkdir ${path_build}
cd ${path_build}

proc find_files file_ext {
    global path_src
    fileutil::findByPattern ${path_src} *.${file_ext}
}

# Vivado commands start below

set_part xc7a200tffg1156-2L

read_vhdl -vhdl2008 [find_files vhd]
read_verilog [find_files v]
read_verilog -sv [find_files sv]

set_property top main [get_filesets sources_1]

synth_design
write_checkpoint -force synth.dcp
