%% VNS Neuromodulator Level Model
%
% Description:
%   This script simulates and visualizes the time-course of neuromodulator
%   release in response to Vagus Nerve Stimulation (VNS) across a range of
%   stimulation parameter sets (current, frequency, and number of pulses).
%
%   The model accounts for:
%     - Frequency-dependent adaptation (reduced response at high/low frequencies)
%     - Pulse-count-dependent adaptation (fatigue across successive pulses)
%     - First-pulse and second-pulse bonuses (higher initial release)
%     - Neuromodulator level cap (ceiling effect)
%     - Exponential decay between pulses (half-life-based decrement)
%
%   The output is a plot of neuromodulator level (arbitrary units) over time (ms),
%   with a shaded "plasticity zone" representing the target neuromodulator range
%   for neural plasticity induction.
%
% Usage:
%   Run this script directly in MATLAB. No additional toolboxes are required.
%   Adjust 'bigparalist' to test different stimulation parameter combinations.
%
% Parameters in bigparalist (each row = one parameter set):
%   Column 1: Current amplitude (mA)
%   Column 2: Stimulation frequency (Hz)
%   Column 3: Number of pulses per train
%
% Output:
%   A MATLAB figure displaying neuromodulator level vs. time for all
%   parameter sets. Highlighted (colored) lines correspond to conditions
%   of experimental interest.
%
% Authors: Pariya Zare, Micheal Kilgard, The University of Texas at Dallas
% Last updated: 2025

%% -------------------------------------------------------------------------
%  Model Parameters
% -------------------------------------------------------------------------

clf; 

% Plasticity zone boundaries (neuromodulator level, arbitrary units)
% These define the range of neuromodulator levels associated with plasticity.
lowaffinity  = 4.7;   % Lower bound of plasticity zone
highaffinity = 3.28;  % Upper bound of plasticity zone

% Neuromodulator decay parameters
halflife     = 175;   % Half-life of neuromodulator decay (ms)
nmlevelcap   = 30;    % Maximum neuromodulator level (ceiling effect)

% First- and second-pulse bonuses
% The first pulse in a train evokes a stronger response than subsequent pulses.
firststimbonus = 1.3;

% Adaptation baseline parameters
% These set the minimum adaptation level (floor) for frequency and pulse-count adaptation.
adaptbase  = 0.33;   % Frequency-dependent adaptation floor
adaptbase2 = 0.83;   % Pulse-count-dependent adaptation floor

% Smoothing window (ms) — applied to neuromodulator level trace for display
wind = 80;

% Frequency-dependent adaptation shape parameters
freqbase = 22;    % Center frequency for adaptation sigmoid (Hz)
freqroot = 0.15;  % Steepness of frequency-dependent adaptation curve

% Current saturation — amplitudes above this value are clipped
currentsaturation = 4;  % (mA)

% Simulation duration (seconds)
seconds = 3.5;

%% -------------------------------------------------------------------------
%  Stimulation Parameter Sets
% -------------------------------------------------------------------------
% Each row: [current (mA), frequency (Hz), # of pulses]

bigparalist = [
    0.2,  30,   16;
    0.4,  30,   16;
    0.5,  30,   61;
    0.6,  30,   16;
    0.6,  30,   61;
    0.8,  7.5,  16;
    0.8,  20,   11;   % Experimental condition
    0.8,  30,    4;
    0.8,  30,   16;   % Standard VNS reference
    0.8,  45,   24;   % Experimental condition
    0.8,  30,   64;
    0.8,  120,  16;
    0.8,  120,  64;
    1.0,  30,   16;
    1.2,  30,   16;
    1.2,  122,   5;
    1.6,  30,   16;
    3.2,  1,     1;
    1.6,  122,   5;
];

%% -------------------------------------------------------------------------
%  Plot Setup
% -------------------------------------------------------------------------

hold on;

% Draw the plasticity zone as a shaded patch
patch([-490, -490, seconds * 1000 - 551, seconds * 1000 - 551], ...
      [lowaffinity, highaffinity, highaffinity, lowaffinity], ...
      [0.99, 0.99, 0.78], 'linestyle', 'none');

% Draw horizontal reference line at alpha threshold
plot([-5000, 2800], [1.5, 1.5], ':', 'color', [1, 1, 0.8], 'linewidth', 3);

%% -------------------------------------------------------------------------
%  Main Simulation Loop
% -------------------------------------------------------------------------

nmall = [];  % Store peak neuromodulator levels for all parameter sets

for b = 1:size(bigparalist, 1)

    % Extract parameters for this condition
    amp     = bigparalist(b, 1);
    freq    = bigparalist(b, 2);
    npulses = bigparalist(b, 3);

    % Apply current saturation
    if amp > currentsaturation
        iamp = ones(1, npulses) * currentsaturation;
    else
        iamp = ones(1, npulses) * amp;
    end

    % Compute pulse timing (in ms), offset by 500 ms from simulation start
    pulsetime = [];
    for i = 1:npulses
        pulsetime = [pulsetime, round(i * 1000 / freq)];
    end
    pulsetime = pulsetime + 500;

    % Initialize neuromodulator level trace
    nmlevel = zeros(1, seconds * 1000);

    % Simulate neuromodulator dynamics over time
    for i = 2:seconds * 1000

        % Check if a pulse occurs at this time step
        n = find(i == pulsetime, 1);

        % Count how many pulses have occurred so far (for pulse-count adaptation)
        recentpulses = length(find(pulsetime < i));

        % Pulse-count-dependent adaptation (sigmoid function)
        % Reduces response as more pulses accumulate in the train
        adapt2 = (1 - (1 ./ (1 + exp(2 - 0.6 * (recentpulses - 10)) * amp))) * ...
                 (1 - adaptbase2) + adaptbase2;

        % Update decay rate based on current adaptation state
        decrement = 1 - (log(2) / (halflife / adapt2));

        if ~isempty(n)
            % --- Pulse event: add neuromodulator release ---

            % Ceiling effect: reduce release if level is above cap
            depress = 2^(-max([0, nmlevel(i - 1) - nmlevelcap]));

            % Frequency-dependent adaptation (sigmoid function)
            % Lower and higher frequencies reduce release relative to optimal
            if n > 1
                adapt = (1.1 - (1 ./ (1 + exp(1 - freqroot * (freq - freqbase))))) * ...
                        (1 - adaptbase) + adaptbase;
            elseif n == 1
                % First pulse: use 1 Hz as reference (no prior pulses to cause adaptation)
                adapt = (1.1 - (1 ./ (1 + exp(1 - freqroot * (1 - freqbase))))) * ...
                        (1 - adaptbase) + adaptbase;
            end

            % Accumulate neuromodulator release for this pulse
            nmlevel(i) = nmlevel(i - 1) + (iamp(n) * depress * adapt);

            % First-pulse bonus: enhanced release for pulse 1
            if n == 1
                nmlevel(i) = nmlevel(i) + iamp(n) * firststimbonus;
            end

            % Second-pulse bonus: partial enhanced release for pulse 2
            if n == 2
                nmlevel(i) = nmlevel(i) + iamp(n) * firststimbonus / 2;
            end

        else
            % --- No pulse: decay neuromodulator level ---
            nmlevel(i) = nmlevel(i - 1) * decrement;
        end
    end

    % Smooth trace for display
    nmlevel = smooth(nmlevel, wind);

    % Store peak level for this condition
    nmall = [nmall, max(nmlevel)];

    %% -----------------------------------------------------------------------
    %  Line Color and Width Assignment
    % -----------------------------------------------------------------------
    % Highlighted conditions correspond to key experimental comparisons.
    % All other conditions are plotted in thin black.

    plotColor     = [0, 0, 0];  % Default: black
    plotLineWidth = 0.3;        % Default: thin

    if isequal(bigparalist(b, :), [0.8, 30, 16])
        plotColor     = [128, 63, 64] / 255;   % Dark red — standard VNS reference
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [0.5, 30, 61])
        plotColor     = [70, 63, 243] / 255;   % Blue
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [1.2, 122, 5])
        plotColor     = [210, 255, 20] / 255;  % Lime green
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [0.6, 30, 61])
        plotColor     = [127, 63, 243] / 255;  % Purple
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [0.8, 120, 8])
        plotColor     = [98, 251, 32] / 255;   % Bright green
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [1.6, 122, 5])
        plotColor     = [255, 255, 20] / 255;  % Yellow
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [3.2, 1, 1])
        plotColor     = [255, 50, 70] / 255;   % Red
        plotLineWidth = 5;
    elseif isequal(bigparalist(b, :), [0.8, 20, 11])
        plotColor     = [0, 0, 0] / 255;       % Black — experimental condition
        plotLineWidth = 3;
    elseif isequal(bigparalist(b, :), [0.8, 45, 24])
        plotColor     = [0, 0, 0] / 255;       % Black — experimental condition
        plotLineWidth = 3;
    end

    %% -----------------------------------------------------------------------
    %  Plot Trace and Label
    %  X-axis is shifted so that the first pulse aligns at time 0.
    % -----------------------------------------------------------------------

    timeAxis = (-500:length(nmlevel)-501) - round(1000 / freq);

    plot(timeAxis, nmlevel, 'Color', plotColor, 'LineWidth', plotLineWidth);
    plot(timeAxis, nmlevel, 'k.', 'MarkerSize', 1);  % Overlay small dots for texture

    % Build label string
    txlab = sprintf('%.1fmA %dHz %dpulses', amp, freq, npulses);

    % Find peak location for label placement
    [p1, p2] = max(nmlevel);
    if p2 > 1500; p2 = p2 - 300; end
    if p2 < 1000; p2 = 50; end
    if npulses > 30; p2 = p2 + 500; end

    % Set axis limits
    set(gca, 'ylim', [0, 13], 'xlim', [-500, 2800]);

    % Axis labels
    xlabel('Time (ms)', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Neuromodulator Level (a.u.)', 'FontSize', 18, 'FontWeight', 'bold');
    set(gca, 'FontSize', 14);

    % Add text label near the peak
    if ~isequal(plotColor, [0, 0, 0])
        % Colored lines: bold label with background
        text(p2 - 500, p1, txlab, ...
             'HorizontalAlignment', 'left', ...
             'VerticalAlignment', 'middle', ...
             'Color', plotColor, ...
             'FontSize', 13, ...
             'FontWeight', 'bold', ...
             'BackgroundColor', [0.57, 0.57, 0.57]);
    else
        % Black lines: plain label, no background
        text(p2 - 500, p1, txlab, ...
             'HorizontalAlignment', 'left', ...
             'VerticalAlignment', 'middle', ...
             'Color', plotColor, ...
             'FontSize', 10, ...
             'FontWeight', 'normal');
    end

end

%% -------------------------------------------------------------------------
%  Figure Title
% -------------------------------------------------------------------------

title(sprintf(['Low=%.1f, Hi=%.1f, Half=%d, Cap=%d, FirstBonus=%.1f, ' ...
               'Adapt=%.2f, Adapt2=%.2f, Smooth=%dms, FreqBase=%dHz'], ...
              lowaffinity, highaffinity, halflife, nmlevelcap, firststimbonus, ...
              adaptbase, adaptbase2, wind, freqbase));

shg;  % Bring figure window to front