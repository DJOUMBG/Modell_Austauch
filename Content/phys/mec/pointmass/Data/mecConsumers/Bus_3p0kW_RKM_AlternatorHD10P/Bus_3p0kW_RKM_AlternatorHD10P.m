generatorLoss_dim = 22; % Speed vector and torque loss for 3kW aux load
generatorLoss_x_speed_rpm = [0.000,400.000,450.000,500.000,550.000,600.000,650.000,700.000,750.000,800.000,850.000,900.000,950.000,1000.000,1250.000,1500.000,1750.000,2000.000,2250.000,2500.000,2750.000,3000.000
];
generatorLoss_map_lossTorque_Nm = [43.425,43.425,38.792,35.094,31.861,29.115,26.955,25.196,23.690,22.375,21.248,20.268,19.408,18.643,15.871,14.325,13.365,12.542,12.220,12.174,12.096,11.985
];
JGenerator = 0;
lvs_alt_avl = 0.0; %local dummy parameter, will be overwritten by LVS module: alternator torque from LVS module: 1 / generatorLoss_map_lossTorque_Nm: 0

mainFanLoss_dim = 22; % fan
mainFanLoss_x_speed_rpm = [0.000,400.000,450.000,500.000,550.000,600.000,650.000,700.000,750.000,800.000,850.000,900.000,950.000,1000.000,1250.000,1500.000,1750.000,2000.000,2250.000,2500.000,2750.000,3000.000
];
mainFanLoss_map_lossTorque_Nm = [0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000
];
JMainFan = 0;
% HVAC
engConsumerLoss_dim = [2.000,2.000
];
engConsumerLoss_x_speed_rpm = [-10000000000.000,10000000000.000
];
engConsumerLoss_y_torque_Nm = [-10000000000.000,10000000000.000
]';
engConsumerLoss_map_lossTorque_Nm = [0.000,0.000
0.000,0.000
];
JEngConsumer = 0;
engEMotLoss_dim = [2.000,2.000
]; % E-Motor (if applicable)
engEMotLoss_x_speed_rpm = [-10000000000.000,10000000000.000
];
engEMotLoss_y_torque_Nm = [-10000000000.000,10000000000.000
]';
engEMotLoss_map_lossTorque_Nm = [0.000,0.000
0.000,0.000
];
JEngEMot = 0;
mainPumpLoss_dim = 2; % no steering pump
mainPumpLoss_x_speed_rpm = [-10000000000.000,10000000000.000
]; % at main shaft:
mainPumpLoss_map_lossTorque_Nm = [0.000,0.000
]; % at main shaft:
JMainPump = 0;
txInConsumerLoss_dim = [2.000,2.000
];
txInConsumerLoss_x_speed_rpm = [-10000000000.000,10000000000.000
];
txInConsumerLoss_y_torque_Nm = [-10000000000.000,10000000000.000
]';
txInConsumerLoss_map_lossTorque_Nm = [0.000,0.000
0.000,0.000
];
JTxInConsumer = 0;
txOutConsumerLoss_dim = [2.000,2.000
];
txOutConsumerLoss_x_speed_rpm = [-10000000000.000,10000000000.000
];
txOutConsumerLoss_y_torque_Nm = [-10000000000.000,10000000000.000
]';
txOutConsumerLoss_map_lossTorque_Nm = [0.000,0.000
0.000,0.000
];
JTxOutConsumer = 0;
genericWheelLoss_dim = 2;
genericWheelLoss_x_speed_rpm = [-10000000000.000,10000000000.000
];
genericWheelLoss_map_lossTorque_Nm = [0.000,0.000
];
genericVehicleLoss_dim = 2;
genericVehicleLoss_x_velocity_kmh = [-10000000000.000,10000000000.000
];
genericVehicleLoss_map_loss_N = [0.000,0.000
];
