classdef Simulator < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        % Setup

        simulation_filename;

        q_0;
        dq_0;

        duration;
        sample_time;

        torque_series;
    end
    
    methods
        
        %% Constructor

        function obj = Simulator(model)
           
            obj.simulation_filename = 'simulation';

            % Little different generalized coordinates than figure.
            % To reuse models from book I followed their convention of
            % using q_2 to be from q_1, and not from ground. Thus a little
            % modification has to be done with the initial values.

            q_1_0           = (5 / 6) * pi;
            q_2_0           = pi + asin(model.l_1 / (2 * model.l_2)) - q_1_0;

            dq_1_0          = 0;
            dq_2_0          = 0;

            obj.q_0           = [  q_1_0   q_2_0]';
            obj.dq_0          = [  dq_1_0  dq_2_0]';

            obj.duration      = 5;
            obj.sample_time   = 0.01;
        end

        %% Simulations

        % Boundedness constraints on input, first link speed and pwoer.
        % Also want monotonicity of link 1
        % Constraints are measured using an L1-metric

        function constraint_violations = get_constraint_violations(obj, simulation_result)

            global settings;

            constraint_violations = struct();

            u_abs       = abs(simulation_result.throwing.u);
            q_1         = simulation_result.throwing.q(:, 1);
            dq_1_abs    = abs(simulation_result.throwing.dq(:, 1));
            P           = u_abs .* dq_1_abs;

            constraint_violations.u    = sum(max(u_abs      - settings.u_bound,     0));
            constraint_violations.q_1  = 0;

            for i = 2:length(q_1)
                constraint_violations.q_1 = constraint_violations.q_1 + max(q_1(i) - q_1(i - 1), 0);
            end

            constraint_violations.dq_1 = sum(max(dq_1_abs   - settings.dq_1_bound,  0));
            constraint_violations.P    = sum(max(P          - settings.P_bound,     0));

            % Normalize with respect to simulation time

            constraint_violations.u     = constraint_violations.u       / simulation_result.throwing.duration;
            constraint_violations.q_1   = constraint_violations.q_1     / simulation_result.throwing.duration;
            constraint_violations.dq_1  = constraint_violations.dq_1    / simulation_result.throwing.duration;
            constraint_violations.P     = constraint_violations.P       / simulation_result.throwing.duration;
        end

        % Simulation results are passed to user via a simulation result class
        % Can then be used to generate plots, update fitness measures etc.
        % Split in two, a throwing phase and a flight phase

        function simulation_result = simulate(obj, model, torque_series)
            
            obj.torque_series = torque_series;

            simulation_result = Simulation_result();

            % Throwing phase
            % Run through simulink

            sim(obj.simulation_filename);
            
            simulation_result.throwing.time     = sim_q_sampled.time;
            simulation_result.throwing.duration = sim_q_sampled.time(end);
            
            simulation_result.throwing.q        = sim_q_sampled.signals.values;
            simulation_result.throwing.dq       = sim_dq_sampled.signals.values;
            simulation_result.throwing.u        = sim_u_sampled.signals.values;

            simulation_result.throwing.constraint_violations = obj.get_constraint_violations(simulation_result);
            simulation_result.throwing.failed                = sim_stopped.signals.values(end) == 0;

            % Flight phase
            % Done analytically because simulink is a mess at times

            q_1 = sim_q.signals.values(end, 1);
            q_2 = sim_q.signals.values(end, 2);

            dq_1 = sim_dq.signals.values(end, 1);
            dq_2 = sim_dq.signals.values(end, 2);

            simulation_result.flight.q_1  = q_1;
            simulation_result.flight.q_2  = q_2;

            simulation_result.flight.dq = dq_1 + dq_2;
            simulation_result.flight.v = abs(model.l_2 * simulation_result.flight.dq);

            simulation_result.flight.h = model.l_1 * sin(q_1) + model.l_2 * sin(q_1 + q_2);
            simulation_result.flight.theta = q_1 + q_2 - (pi / 2);                              % Normal to q_2, compansate for my change of generalized coordinates

            n = 100;
            h  = simulation_result.flight.h;
            v  = simulation_result.flight.v;

            % Do not care when h < 0 or it did not manage to throw within the given time

            if (simulation_result.flight.h < 0 || simulation_result.throwing.failed)

                simulation_result.flight.distance = 0;
                simulation_result.flight.duration = 0;

                simulation_result.flight.time = [0 0];        % This funny format so I do not have to change plot code
                simulation_result.flight.x    = [0 0];
                simulation_result.flight.y    = [h h];

            % Simple physics, but...
            % https://en.wikipedia.org/wiki/Trajectory_of_a_projectile#Conditions_at_the_final_position_of_the_projectile

            else
                ct = cos(simulation_result.flight.theta);
                st = sin(simulation_result.flight.theta);

                simulation_result.flight.distance = v * ct / model.g * (v * st + sqrt(v * v * st * st + 2 * model.g * h));
                simulation_result.flight.duration = simulation_result.flight.distance / (v * ct);
                
                simulation_result.flight.time = linspace(0, simulation_result.flight.duration, n);
                simulation_result.flight.x    = linspace(0, simulation_result.flight.distance, n);
                simulation_result.flight.y    = h + simulation_result.flight.x * st / ct - (model.g * simulation_result.flight.x .* simulation_result.flight.x) / (2 * v * v * ct * ct);
            end
        end

        %% Plotting

        % Must call simulate before dispaying results

        function display_scene(obj, model, simulation_result)

            figure_handle = figure(1);

            % Throwing phase

            for i = 2:length(simulation_result.throwing.time)
                
                if (~ishandle(figure_handle))
                    break;
                end
                
                q_1 = simulation_result.throwing.q(i, 1);
                q_2 = simulation_result.throwing.q(i, 2);
                
                dt = simulation_result.throwing.time(i) - simulation_result.throwing.time(i - 1);
                
                obj.display_throwing_phase_still_image(figure_handle, model, q_1, q_2, dt, simulation_result.flight);
            end

            % Flight phase

            for i = 2:length(simulation_result.flight.x)
                
                if (~ishandle(figure_handle))
                    break;
                end

                q_1 = simulation_result.flight.q_1;
                q_2 = simulation_result.flight.q_2;

                dt = simulation_result.flight.time(i) - simulation_result.flight.time(i - 1);
                
                obj.display_flight_phase_still_image(figure_handle, model, q_1, q_2, dt, simulation_result.flight, i);
            end
        end

        function display_throwing_phase_still_image(obj, figure_handle, model, q_1, q_2, dt, flight)

            clf(figure_handle);

            % Link 1 and 2

            x_1 = [ 0       model.l_1 * cos(q_1)]';
            y_1 = [ 0       model.l_1 * sin(q_1)]';
            
            x_2 = [ 0       model.l_2 * cos(q_1 + q_2)]' + [x_1(2) x_1(2)]';
            y_2 = [ 0       model.l_2 * sin(q_1 + q_2)]' + [y_1(2) y_1(2)]';
            
            hold on;
            
            plot(x_1, y_1, 'b');
            plot(x_2, y_2, 'r');
            
            % Ball
            
            ball_x = x_2(2);
            ball_y = y_2(2);
            
            scatter(ball_x, ball_y, 'ro', 'filled');
            
            % Misc
            
            axis([-1 ceil(flight.distance) -1 ceil(max(flight.y))]);
            
            pause(dt * 10);
        end

        function display_flight_phase_still_image(obj, figure_handle, model, q_1, q_2, dt, flight, i)

            clf(figure_handle);
            
            % Link 1 and 2
            
            x_1 = [ 0       model.l_1 * cos(q_1)]';
            y_1 = [ 0       model.l_1 * sin(q_1)]';
            
            x_2 = [ 0       model.l_2 * cos(q_1 + q_2)]' + [x_1(2) x_1(2)]';
            y_2 = [ 0       model.l_2 * sin(q_1 + q_2)]' + [y_1(2) y_1(2)]';
            
            hold on;
            
            plot(x_1, y_1, 'b');
            plot(x_2, y_2, 'r');
            
            % Ball
            
            scatter(flight.x(i), flight.y(i), 'ro', 'filled');

            % Misc
            
            axis([-1 ceil(flight.distance) -1 ceil(max(flight.y))]);
            
            pause(dt);
        end
    end
end