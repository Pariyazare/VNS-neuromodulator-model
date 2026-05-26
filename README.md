# VNS-neuromodulator-model

This repository contains MATLAB code for a mathematical model used to simulate neuromodulator dynamics in response to different vagus nerve stimulation (VNS) parameters.

The model was developed to explore how stimulation parameters, including current amplitude, frequency, and number of pulses, may influence neuromodulatory activity and VNS-dependent cortical plasticity.

The goal of the model is to identify stimulation conditions that produce neuromodulator activity within an optimal range for plasticity. This is based on the idea that VNS may follow an inverted-U relationship, where too little stimulation may be insufficient, while too much stimulation may reduce plasticity.

## What the model does

The model simulates the neuromodulatory response to VNS trains with different parameter combinations. It estimates how stimulation parameters affect the magnitude and duration of the neuromodulator response over time.

The model is used to compare tested VNS conditions and predict additional parameter combinations that may be effective for driving cortical plasticity.

## Main inputs

- Stimulation current amplitude
- Stimulation frequency
- Number of pulses
- Train timing / inter-stimulation interval

## Main outputs

- Simulated neuromodulator response over time
- Comparison of effective and ineffective VNS parameter sets

## How to use

Run the main MATLAB script to simulate VNS-induced neuromodulator dynamics across stimulation conditions.

