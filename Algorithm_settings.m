classdef Algorithm_settings < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        
        % Population

        number_of_generations   = 200;
        number_of_individuals   = 30;

        boltzmann_scale_parameter = 0.2;

        % Individual

        torque_series_duration  = 0.5;
        base_torque             = -105;

        split_probability       = 0.2;

        inc_sigma_bias          = 1;
        inc_sigma_scale         = 10;

    end
    
    methods
        
        %% Constructor

        function obj = Algorithm_settings()
           
        end
    end
end