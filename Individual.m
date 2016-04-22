classdef Individual < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        torque_series;
        torque_series_duration;

        fitness;
    end
    
    methods
        
        %% Constructor

        function obj = Individual()

        	global settings;

            obj.torque_series      		= {};
            obj.torque_series_duration	= settings.torque_series_duration;
            obj.fitness 				= 0;

            torque_entry = Torque_entry(settings.base_torque, 0, obj.torque_series_duration);

            obj.torque_series{1} = torque_entry;
        end

        %% Helper methods

        function description = get_description(obj)
        	description = sprintf('Fitness: %f', obj.fitness);
        end

        function description = get_description_with_detail(obj)

        	description = sprintf('Fitness: %f', obj.fitness);

        	for i = 1:length(obj.torque_series)

        		torque_entry = obj.torque_series{i};

        		description = [description sprintf('\n\ttime:%f:%f, torque:%f', torque_entry.t_start, torque_entry.t_end, torque_entry.torque) ];
        	end
        end

        function individual = get_copy(obj)

        	individual = Individual();

        	individual.torque_series    = {};
        	individual.fitness = obj.fitness;

        	for i = 1:length(obj.torque_series)
        		individual.torque_series{i} = obj.torque_series{i}.get_copy();
        	end
        end

        %% Genetic methods

        function mutate(obj)

        	global settings;

        	% Split operator

        	if (rand() > (1 - settings.split_probability))

	        	split_time = obj.torque_series_duration * rand();

	        	for i = 1:length(obj.torque_series)

	        		if (split_time < obj.torque_series{i}.t_end)

	        			new_torque_entry 			 = Torque_entry(obj.torque_series{i}.torque, obj.torque_series{i}.t_start, split_time);
	        			obj.torque_series{i}.t_start = split_time;

	        			obj.torque_series = {obj.torque_series{1:(i - 1)} new_torque_entry obj.torque_series{(i):end}};
	        			
	        			break;
	        		end
	        	end
	        end

        	% Increment / decrement operator

        	for i = 1:length(obj.torque_series)

        		sigma = settings.inc_sigma_bias + settings.inc_sigma_scale * (obj.torque_series{i}.t_end - obj.torque_series{i}.t_start);

        		delta = sigma * randn();
        		
        		obj.torque_series{i}.torque = obj.torque_series{i}.torque + delta;
        	end
        end

        function simulate_and_update_fitness(obj, model, simulator)

        	model.torque_series = obj.torque_series;

        	simulator.simulate(model);

        	obj.fitness = simulator.flight.distance;
        end
    end
end