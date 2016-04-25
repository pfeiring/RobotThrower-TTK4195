classdef Model < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        % Link lengths
            
        l_1       = 0.3;
        l_2       = 0.542;

        l_c1      = 0.2071;
        l_c2      = 0.2717;
        
        % Link masses
        
        m_1       = 2.934;
        m_2       = 1.1022;

        % Link inertia

        I_1       = 0.2067;
        I_2       = 0.1363;

        % Spring
        
        k_2       = 14.1543;

        % Ball
        
        m_b       = 0.064;

        % Gravity
        
        g         = 9.81;
    end
    
    methods
        
        %% Constructor

        function obj = Model()
            
        end

        %% EoM matrices

        function D = get_D(obj, q)

            % Jacobians for all masses
    
            J_1 = [ (-obj.l_c1 * sin(q(1)))                                  0;
                    ( obj.l_c1 * cos(q(1)))                                  0;
                      0                                                      0];

            J_2 = [ (-obj.l_1 * sin(q(1)) - obj.l_c2 * sin(q(1) + q(2)))    -obj.l_c2 * sin(q(1) + q(2));
                    ( obj.l_1 * cos(q(1)) + obj.l_c2 * cos(q(1) + q(2)))     obj.l_c2 * cos(q(1) + q(2));
                      0                                                      0];

            J_b = [ (-obj.l_1 * sin(q(1)) - obj.l_2 * sin(q(1) + q(2)))     -obj.l_2 * sin(q(1) + q(2));
                    ( obj.l_1 * cos(q(1)) + obj.l_2 * cos(q(1) + q(2)))      obj.l_2 * cos(q(1) + q(2));
                      0                                                      0];

            % Link interia
            
            I_1 = [ obj.I_1     0;
                    0           0];
            
            I_2 = obj.I_2 * ones(2);
            
            I = I_1 + I_2;
                 
            % Inertia matrix

            D = zeros(2);
            
            D = D + (obj.m_1 * (J_1' * J_1));
            D = D + (obj.m_2 * (J_2' * J_2));
            D = D + (obj.m_b * (J_b' * J_b));
            D = D + I;
        end

        function C = get_C(obj, q, dq)

            h_1 = 0;
            h_2 = -obj.m_2 * obj.l_1 * obj.l_c2 * sin(q(2));
            h_b = -obj.m_2 * obj.l_1 * obj.l_2  * sin(q(2));
            
            h = h_1 + h_2 + h_b;
            
            C = [   (h * dq(2))     (h * dq(2) + h * dq(1));
                    (-h * dq(1))    0];
        end

        function g = get_g(obj, q)

            % dP / dq1
            
            g_1_1 = obj.m_1 * obj.l_c1 * obj.g * cos(q(1));
            g_1_2 = obj.m_2 * obj.l_1  * obj.g * cos(q(1)) + obj.m_2 * obj.l_c2 * obj.g * cos(q(1) + q(2));
            g_1_b = obj.m_b * obj.l_1  * obj.g * cos(q(1)) + obj.m_b * obj.l_2  * obj.g * cos(q(1) + q(2));
            
            % dP / dq2
            
            g_2_1 = 0;
            g_2_2 = obj.m_2 * obj.l_c2 * obj.g * cos(q(1) + q(2));
            g_2_b = obj.m_b * obj.l_2 * obj.g  * cos(q(1) + q(2)) + obj.k_2 * q(2);

            % g(q)
            
            g_1 = g_1_1 + g_1_2 + g_1_b;
            g_2 = g_2_1 + g_2_2 + g_2_b;
           
            g = [g_1 g_2]';
        end

        %% Second derivative

        function y = get_dd_q(obj, x, torque_series)

            q  = x(1:2);
            t  = x(3);
            dq = x(4:5);

            D = obj.get_D(q);
            C = obj.get_C(q, dq);
            g = obj.get_g(q);
            
            u = 0;

            for i = 1:length(torque_series)

                if (torque_series{i}.t_end >= t)
                    u = torque_series{i}.torque;
                    break;
                end
            end
            
            tau = [u 0]';

            dd_q = inv(D) * (-C * dq - g + tau);

            y = [dd_q; u]';
        end
    end
end