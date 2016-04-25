classdef Individual < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        torque_series;
        torque_series_duration;

        fitness;

        simulation_result;
    end
    
    methods
        
        %% Constructor

        function obj = Individual()

        	global settings;

            obj.torque_series      		= {};
            obj.torque_series_duration	= settings.torque_series_duration;
            obj.fitness 				= 0;
            obj.simulation_result       = Simulation_result();

            obj.torque_series           = obj.get_random_torque_series();
        end

        function torque_series = get_random_torque_series(obj)

            global settings;

            % Pick a random numbers of torque entries

            number_of_torque_entries = 1 + floor(10 * rand());

            % Distribute cells through torque series duration
            
            t = rand(number_of_torque_entries, 1);
            t = cumsum(t);
            t = obj.torque_series_duration * t;

            t(end) = obj.torque_series_duration;

            % Pick random torque start for each slice within some interval

            torque_series = cell(number_of_torque_entries, 1);

            for i = 1:number_of_torque_entries

                if (i == 1)
                    t_start = 0;
                else
                    t_start = t(i - 1);
                end

                t_end  = t(i);
                torque = settings.base_torque + 20 * 2 * (rand() - 0.5);

                torque_series{i} = Torque_entry(torque, t_start, t_end);
            end
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

        	individual.torque_series       = {};
        	individual.fitness             = obj.fitness;
            individual.simulation_result   = Simulation_result();

        	for i = 1:length(obj.torque_series)
        		individual.torque_series{i} = obj.torque_series{i}.get_copy();
        	end
        end

        %% Simulation

        function simulate(obj, model, simulator)
            obj.simulation_result = simulator.simulate(model, obj.torque_series);
        end

        %% Constriant violatians

        function flag = has_no_contraint_violations(obj)

            constraint_violations = obj.simulation_result.throwing.constraint_violations;

            flag = constraint_violations.u == 0 && constraint_violations.q_1 == 0 && constraint_violations.dq_1 == 0 && constraint_violations.P == 0;
        end

        function print_constraint_violations(obj)

            constraint_violations = obj.simulation_result.throwing.constraint_violations;

            fprintf('Constraint violations (L1): \n');
            fprintf('u: %f\n',       constraint_violations.u);
            fprintf('q_1: %f\n',     constraint_violations.q_1);
            fprintf('dq_1: %f\n',    constraint_violations.dq_1);
            fprintf('P: %f\n',       constraint_violations.P);
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

        function update_fitness(obj)

            throwing = obj.simulation_result.throwing;
            flight   = obj.simulation_result.flight;

            constraint_violations = throwing.constraint_violations;

            obj.fitness = 0;

        	obj.fitness = 1  * obj.fitness + 1 / (1 + constraint_violations.u);
            obj.fitness = 1  * obj.fitness + 1 / (1 + constraint_violations.q_1);
            obj.fitness = 1  * obj.fitness + 1 / (1 + constraint_violations.dq_1);
            obj.fitness = 1  * obj.fitness + 1 / (1 + constraint_violations.P);

            % Penalize if it is not able to throw the ball at all

            if (~throwing.failed)
                obj.fitness = obj.fitness + 2;
            end

            % Reward long throws, but this is not very important if the constraints are violated
            % There should however some reward if the constraint are only slightly off

            if (obj.has_no_contraint_violations())

                obj.fitness = obj.fitness + 5 * flight.distance;
            else
                obj.fitness = obj.fitness + min(5 * flight.distance, 5);
            end
        end
    end
end