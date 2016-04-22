classdef Torque_entry < handle
    
    properties (Access = private)
        
    end
    
    properties (Access = public)
        torque;
        t_start;
       	t_end;
    end
    
    methods
        
        %% Constructor

        function obj = Torque_entry(torque, t_start, t_end)
           
            obj.torque 	= torque;
	        obj.t_start = t_start;
	       	obj.t_end 	= t_end;
        end

        %% Helper methods

        function torque_entry = get_copy(obj)

        	torque_entry = Torque_entry(obj.torque, obj.t_start, obj.t_end);
        end
    end
end