# GateMate Prallel RGB Interface

This is an implementation of a parallel RGB interface for the GateMate FPGAs by Cologne Chip.
The implementation is targeted for the open source FMC Video IO card:

https://github.com/kschauwecker/fmc_video_io_card/

The motivation for implementing a parallel RGB interface on this FPGA is, that the FPGA
IOs don't support the TMDS standard, which is required for HDMI. There have been some demonstrations
showing that it is still possible to drive an HDMI signal through the FPGA IOs for low resolutions,
but these approaches are unlikely to work for high-resolution / high-frame-rate modes.

The targeted FMC card has as a parallel RGB to HDMI converter IC. With that it should be possible to
drive a high-resolution HDMI output directly from the FPGA.

*This project is still work in progress!*