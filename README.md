# Real-Time-Image-Processing-on-Zynq-FPGA-PES-DHL-Project-
This project was developed as part of the PES-DHL (Digital Hardware Lab) course and implements a real-time image processing pipeline using VHDL on a Zynq-based FPGA platform. The system performs color filtering, region labeling, and feature extraction on video streams using a modular hardware design.

## Overview

The project focuses on detecting and analyzing colored regions in live video input using a pipelined architecture. Major stages include:

RGB to HSV color space conversion

HSV-based color filtering

Run-Length Encoding (RLE)

Connected Component (Region) Labeling

Feature Extraction (bounding box, centroid, area)

## Architecture

Video Input → RGB2HSV → HSV Filter → RLE → Region Labeling → Feature Extraction

Each block is designed in VHDL and processes one pixel per clock cycle. The pipeline is built to work in real-time, suitable for high-resolution inputs like 640×480.

## Module Highlights

RGB2HSV

Converts each RGB pixel to HSV format using fixed-point arithmetic

Uses a pipelined design for high throughput

Performs custom division for hue/saturation calculations

HSV Filter

Thresholds HSV values to isolate target colors (e.g. blue, red)

Outputs a 1-bit binary mask for filtered pixels

Run-Length Encoder (RLE)

Encodes contiguous ‘1’ pixels in a row into (start, end, row) tuples

Tracks runs efficiently with counters and control logic

Region Labeling

Assigns region labels using a union-find approach

Stores label equivalences in memory

Outputs unique labeled regions

Feature Extraction

Calculates each region’s area, centroid, and bounding box

Uses accumulators and state machines to track region features in real-time

## Tools Used

Xilinx Vivado

Zynq-7000 FPGA board

VHDL (RTL)

AXI-Stream video interfaces

Testbenches for each module

## Results

Full pipeline latency: ~11 clock cycles per pixel (RGB to HSV)

Processes 1 pixel per clock in real-time

Modular structure allows individual testing and scaling

Verified on test images with various filtering thresholds

## Learning Outcomes

Built and debugged a complex multi-stage hardware image pipeline

Applied digital design techniques: pipelining, clock domain control, fixed-point arithmetic

Learned how to interface streaming video protocols on FPGAs

Practiced hardware-software co-design and verification

## Possible Extensions

Multi-object tracking

Communication with ARM core (Zynq PS) for adaptive filtering

UART/HDMI interface for visual output

Integration with learned filters or adaptive thresholding

## Author

Kaan Gürsoy
M.Sc. Electrical Engineering, Karlsruhe Institute of Technology (KIT)
GitHub: https://github.com/kaangursoy1

Let me know if you’d like to tailor this even more based on your waveforms, module names, or simulation screenshots.
