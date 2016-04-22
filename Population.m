classdef Population < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        number_of_generations;
        number_of_individuals;

        fittest_individuals;
        generation;

        individuals;
    end
    
    methods
        
        %% Constructor

        function obj = Population()
           
            global settings;

            obj.number_of_generations = settings.number_of_generations;
            obj.number_of_individuals = settings.number_of_individuals;

            obj.fittest_individuals   = zeros(obj.number_of_generations, 1);
            obj.generation            = 1;

            obj.individuals = {};

            for i = 1:obj.number_of_individuals
                obj.individuals{i} = Individual();
            end
            
            fittest_individual = obj.get_fittest_individual();
            obj.fittest_individuals(obj.generation) = fittest_individual.fitness;
        end

        %% Helper methods

        function print(obj)

            for i = 1:obj.number_of_individuals

                fprintf('%i. %s\n', i, obj.individuals{i}.get_description());
            end
        end

        function print_with_detail(obj)

            for i = 1:obj.number_of_individuals

                fprintf('%i. %s\n', i, obj.individuals{i}.get_description_with_detail());
            end
            
            fittest_individual = obj.get_fittest_individual();
            fprintf('\nFittest individual: %f\n', fittest_individual.fitness);
        end

        function print_generation_number(obj)
            fprintf('Generation: %i\n', obj.generation);
        end

        function plot_fittest_individuals(obj)

            figure();
            
            plot(1:obj.number_of_generations, obj.fittest_individuals);

            xlabel('Generation');
            ylabel('Fitness');
        end
        
        % Fittest individual
        
        function fittest_individual = get_fittest_individual(obj)
            
            fittest_individual = obj.individuals{1};

            for i = 2:obj.number_of_individuals

                if (obj.individuals{i}.fitness > fittest_individual.fitness)
                    fittest_individual = obj.individuals{i};
                end
            end
        end

        function store_fittest_individual(obj)

            fittest_individual = obj.get_fittest_individual();

            filename = sprintf('fittest_individual_%f', fittest_individual.fitness);
            filename = strrep(filename, '.', '_');

            save(filename, 'fittest_individual');
        end

        %% Selection methods

        function selected_individuals = stochastic_universal_sampling(obj, n)

            % Build a (unnormalized) cumulative distribution over all fitness values

            cumulative_fitness_distribution    = zeros(obj.number_of_individuals, 1);
            cumulative_fitness_distribution(1) = obj.individuals{1}.fitness;

            for i = 2:obj.number_of_individuals
                cumulative_fitness_distribution(i) = cumulative_fitness_distribution(i - 1) + obj.individuals{i}.fitness;
            end

            % Deterministic sampling from the cumulative distribution

            selected_individuals = obj.deterministic_sampling(n, cumulative_fitness_distribution);
        end

        function selected_individuals = boltzmann_sampling(obj, n)

            global settings;

            % Build a (unnormalized) cumulative distribution over all fitness values

            scale_parameter = settings.boltzmann_scale_parameter;

            cumulative_fitness_distribution    = zeros(obj.number_of_individuals, 1);
            cumulative_fitness_distribution(1) = exp(obj.individuals{1}.fitness / scale_parameter);

            for i = 2:obj.number_of_individuals
                cumulative_fitness_distribution(i) = cumulative_fitness_distribution(i - 1) + exp(obj.individuals{i}.fitness / scale_parameter);
            end

            % Deterministic sampling from the cumulative distribution

            selected_individuals = obj.deterministic_sampling(n, cumulative_fitness_distribution);
        end

        function selected_individuals = deterministic_sampling(obj, n, cumulative_fitness_distribution)

            selected_individuals = {};

            % If there are no individuals with positive fitness, just return all

            fitness_sum = cumulative_fitness_distribution(end);

            if (fitness_sum <= 0)
                selected_individuals = obj.individuals;
                return;
            end
            
            % Divide distribution into n cells, and choose a starting point in
            % first cell. Then individuals in step_sizes ahead

            step_size           = fitness_sum / n;
            starting_pointer    = rand() * step_size;

            i = 1;
            j = 1;
            distribution_pointer = starting_pointer;

            while (i <= n)

                if (cumulative_fitness_distribution(j) >= distribution_pointer)

                    selected_individuals{i} = obj.individuals{j}.get_copy();
                    
                    i = i + 1;
                    distribution_pointer = distribution_pointer + step_size;
                else
                    j = j + 1;
                end
            end
        end

        %% Genetic methods

        function breed_next_generation(obj)

            obj.generation = obj.generation + 1;
            obj.individuals = obj.boltzmann_sampling(obj.number_of_individuals);
        end

        function mutate(obj)

            for i = 1:obj.number_of_individuals
                
                obj.individuals{i}.mutate();
            end
        end

        function update_fitness(obj, model, simulator)

            for i = 1:obj.number_of_individuals

                obj.individuals{i}.simulate_and_update_fitness(model, simulator);
            end

            fittest_individual = obj.get_fittest_individual();
            obj.fittest_individuals(obj.generation) = fittest_individual.fitness;
        end
    end
end