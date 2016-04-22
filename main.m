
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
    population.update_fitness(model, simulator);

    population.print_generation_number();
end

population.store_fittest_individual();
population.print_with_detail();

population.plot_fittest_individuals();