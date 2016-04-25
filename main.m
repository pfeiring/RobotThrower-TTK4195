
clc;
%clear all;

%% Setup

global settings;

settings  = Algorithm_settings();

model     = Model();
simulator = Simulator(model);

%% Optimize

population = Population();

for generation = 2:population.number_of_generations
    
    population.breed_next_generation();
    population.mutate();

    population.simulate(model, simulator);
    population.update_fitness();

    population.print_generation_number();
end

population.store_fittest_individual();
population.store_fittest_individual_with_no_constraint_violations();

population.print_with_detail();
population.plot_fittest_individuals();