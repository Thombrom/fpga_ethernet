# Ethernet on FPGA

This project aims to implement the ethernet protocol and various other internet protocols on top of that on an FPGA. The recieve and parsing modules should be fairly expandable to handle other types of payload and stacks. The transmission framework, however, is currently a bit hardcoded. It should probably be reworked to use block memory.

This code is the result of taking 6S.193 over IAP at MIT in 2022. 
