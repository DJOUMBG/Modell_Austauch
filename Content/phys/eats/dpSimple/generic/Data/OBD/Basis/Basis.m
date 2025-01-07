% Parameter for OBD 

%% sensor manipulation
SensorOffset_NOXRAW = 0;	% offset [ppm] of NOx raw sensor
SensorGain_NOXRAW = 1;	% gain [-] of NOx raw sensor (1.0 no change to sensor signal)
% NOx sensor output signal is modified according to Sens_mod = Sens_orig*SensorGain + SensorOffset
GasExhaustIn_pressureGain = 1;	% gain [-] on eats_GasExhaustIn_pressure for engine boundary conditions
								% GasExhaustIn_pressure = (GasExhaustIn_pressure - env pressure)*gain+ env pressure
