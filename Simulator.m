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
        
        % Results

        sim_time;

        sim_q;
        sim_dq;
        sim_u;
        
        sim_q_sampled;
        sim_dq_sampled;
        sim_u_sampled;

        flight;
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

        function violation = constraints_violated(obj)

            violation = false;

            for i = 1:length(obj.sim_u.signals.values)
               
                u    = abs(obj.sim_u.signals.values(i));
                dq_1 = abs(obj.sim_q.signals.values(i));

                P = u * dq_1;

                if (u > 180 || dq_1 > 3.787 || P > 270)
                    violation = true;
                    break;
                end
            end
        end

        function simulate(obj, model)
            
            % Throwing phase
            % Run through simulink

            sim(obj.simulation_filename);
            
            obj.sim_time = sim_q_sampled.time;
            
            obj.sim_q  = sim_q;
            obj.sim_dq = sim_dq;
            obj.sim_u  = sim_u;

            obj.sim_q_sampled  = sim_q_sampled;
            obj.sim_dq_sampled = sim_dq_sampled;
            obj.sim_u_sampled  = sim_u_sampled;

            % Flight phase
            % Done analytically because simulink is a mess at times

            obj.flight = struct();

            obj.flight.q_1  = sim_q.signals.values(end, 1);
            obj.flight.q_2  = sim_q.signals.values(end, 2);

            dq_1 = sim_dq.signals.values(end, 1);
            dq_2 = sim_dq.signals.values(end, 2);

            obj.flight.dq = dq_1 + dq_2;
            obj.flight.v = abs(model.l_2 * obj.flight.dq);                                                      % Swap signs due to defintion of generalized coordinates

            obj.flight.h = model.l_1 * sin(obj.flight.q_1) + model.l_2 * sin(obj.flight.q_1 + obj.flight.q_2);
            obj.flight.theta = obj.flight.q_1 + obj.flight.q_2 - (pi / 2);                                      % Normal to q_2, compansate for my change of generalized coordinates
            
            n = 100;
            h  = obj.flight.h;
            v  = obj.flight.v;

            % Do not care when h < 0 or any constraints were violated

            if (obj.flight.h < 0 || obj.constraints_violated())

                obj.flight.distance = 0;
                obj.flight.duration = 0;

                obj.flight.time = [0 0];        % This funny format so I do not have to change plot code
                obj.flight.x    = [0 0];
                obj.flight.y    = [h h];

            % Simple physics, but...
            % https://en.wikipedia.org/wiki/Trajectory_of_a_projectile#Conditions_at_the_final_position_of_the_projectile

            else
                ct = cos(obj.flight.theta);
                st = sin(obj.flight.theta);

                obj.flight.distance = v * ct / model.g * (v * st + sqrt(v * v * st * st + 2 * model.g * h));
                obj.flight.duration = obj.flight.distance / (v * ct);
                
                obj.flight.time = linspace(0, obj.flight.duration, n);
                obj.flight.x    = linspace(0, obj.flight.distance, n);
                obj.flight.y    = h + obj.flight.x * st / ct - (model.g * obj.flight.x .* obj.flight.x) / (2 * v * v * ct * ct);
            end
        end

        %% Results

        % Must call simulate before dispaying results

        function display_scene(obj, model)

            figure_handle = figure(1);

            % Throwing phase

            for i = 2:length(obj.sim_time)
                
                if (~ishandle(figure_handle))
                    break;
                end
                
                q_1 = obj.sim_q_sampled.signals.values(i, 1);
                q_2 = obj.sim_q_sampled.signals.values(i, 2);
                
                dt = obj.sim_time(i) - obj.sim_time(i - 1);
                
                obj.display_throwing_phase_still_image(figure_handle, model, q_1, q_2, dt);
            end

            % Flight phase

            for i = 2:length(obj.flight.x)
                
                if (~ishandle(figure_handle))
                    break;
                end
                
                obj.display_flight_phase_still_image(figure_handle, model, i);
            end
        end

        function display_throwing_phase_still_image(obj, figure_handle, model, q_1, q_2, dt)

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
            
            axis([-1 ceil(obj.flight.distance) -1 ceil(max(obj.flight.y))]);
            
            pause(dt * 10);
        end

        function display_flight_phase_still_image(obj, figure_handle, model, i)

            clf(figure_handle);
            
            % Link 1 and 2
            
            q_1 = obj.flight.q_1;
            q_2 = obj.flight.q_2;
            
            x_1 = [ 0       model.l_1 * cos(q_1)]';
            y_1 = [ 0       model.l_1 * sin(q_1)]';
            
            x_2 = [ 0       model.l_2 * cos(q_1 + q_2)]' + [x_1(2) x_1(2)]';
            y_2 = [ 0       model.l_2 * sin(q_1 + q_2)]' + [y_1(2) y_1(2)]';
            
            hold on;
            
            plot(x_1, y_1, 'b');
            plot(x_2, y_2, 'r');
            
            % Ball
            
            scatter(obj.flight.x(i), obj.flight.y(i), 'ro', 'filled');

            % Misc
            
            axis([-1 ceil(obj.flight.distance) -1 ceil(max(obj.flight.y))]);
            
            pause(obj.flight.time(i) - obj.flight.time(i - 1));
        end
    end
end