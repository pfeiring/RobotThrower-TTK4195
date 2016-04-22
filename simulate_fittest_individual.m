
clc;
clear all;

%% Setup

model     = Model();
simulator = Simulator(model);

fittest_individual = load('fittest_individual_31_998766');
fittest_individual = fittest_individual.fittest_individual;

%% Simulate and display results

fittest_individual.simulate_and_update_fitness(model, simulator);

simulator.display_scene(model);
