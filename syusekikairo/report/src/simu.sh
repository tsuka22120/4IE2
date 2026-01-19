iverilog -o simu simu.v main.v
vvp simu
gtkwave simu.vcd