
clc;
clear all;

%% Setup

global settings;

settings  = Algorithm_settings();

model     = Model();
simulator = Simulator(model);

fittest_individual = load('storage/fittest_individual_with_no_constraint_violations_3_100941');
fittest_individual = fittest_individual.fittest_individual;

%% Simulate and display results

fittest_individual.simulate(model, simulator);
fittest_individual.print_constraint_violations();

simulator.display_scene(model, fittest_individual.simulation_result);
