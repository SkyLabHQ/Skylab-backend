pragma circom 2.0.3;

include "/Users/neal.sun/.nvm/versions/node/v16.19.1/lib/node_modules/circomlib/circuits/comparators.circom";

template TimePerGrid() {
    signal input level_scaler;
    signal input c1;
    signal input used_fuel;
    signal input fuel_scaler;
    signal input used_battery;
    signal input battery_scaler;
    signal input distance;

    component isResourceZero;
    component isDistanceZero;

    signal output final_time;

    signal fuel_after_scaling <== used_fuel*fuel_scaler;
    signal battery_after_scaling <== used_battery*battery_scaler;
    signal input_after_scale <== fuel_after_scaling + battery_after_scaling;

    signal speed_inverse_pre_c1 <== (input_after_scale - 465 * level_scaler) ** 2;
    signal speed_inverse_pre_div <== c1 * speed_inverse_pre_c1;
    signal divider <== level_scaler ** 2;

    signal speed_inverse_after_div <-- speed_inverse_pre_div \ divider;
    signal mod <-- speed_inverse_pre_div % divider;
    speed_inverse_pre_div === speed_inverse_after_div * divider + mod;
    component modLessThanScaler = LessThan(32);
    modLessThanScaler.in[0] <== mod;
    modLessThanScaler.in[1] <== divider;
    modLessThanScaler.out === 1;

    // isResourceZero = IsZero();
    // isResourceZero.in <== speed_inverse_after_div;
    // isDistanceZero = IsZero();
    // isDistanceZero.in <== distance;
    // // if distance is zero, doesn't matter what resource is used; otherwise, resource is not zero
    // 0 === isResourceZero.out * (1 - isDistanceZero.out);

    signal speed_inverse <== speed_inverse_after_div + 400000;

    final_time <== distance * speed_inverse;
}
