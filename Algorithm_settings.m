classdef Algorithm_settings < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        % Population

        number_of_generations   = 150;
        number_of_individuals   = 200;

        boltzmann_scale_parameter = 0.2;

        % Individual basics

        torque_series_duration  = 1;
        
        base_torque             = -20;

        % Mutation

        split_probability       = 0.2;

        inc_sigma_bias          = 1;
        inc_sigma_scale         = 10;

        % Constraints

        u_bound                 = 180;
        dq_1_bound              = 3.787;
        P_bound                 = 270;
    end
    
    methods
        
        %% Constructor

        function obj = Algorithm_settings()
           
        end
    end
end