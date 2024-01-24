The project consists in a basic implementation of a FFT image filter.
It works with 256x256 pixel greyscale images, since the FFT is implemented as not runtime-configurable.

The data is sent as 32-bit floats through UART (Nbaud = 115200) in single bytes, and deserialized by the uart_t module.
The module mem_write_uart rebuilds the data in float format and writes it in the implemented Block RAM.
The data is stored as a 32+32 bit complex number.
The module fft_filter exploits 4 FFT stages and a filtering submodule (fft_imgfilter), using the Xilinx FFT v7 core in floating-point, non-real-time, Burst Radix-2 Lite mode.
The stages are: forward FFT of rows (fft_row module), fwd FFT of columns (fft_column), filtering, inverse FFT of rows (fft_row module) and inverse FFT of columns (fft_column).
The filter algorithm is a basic threshold clipper, exploiting a float-comparator IP.
Each stage substitutes the input data with the results in the memory.
The real part of the result is then read from the memory, divided in bytes (mem_read_uart module) and sent back via UART (uart_t module).
