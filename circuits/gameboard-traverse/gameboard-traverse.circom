pragma circom 2.0.3;

include "/Users/neal.sun/.nvm/versions/node/v16.19.1/lib/node_modules/circomlib/circuits/poseidon.circom";
include "/Users/neal.sun/.nvm/versions/node/v16.19.1/lib/node_modules/circomlib/circuits/comparators.circom";
include "/Users/neal.sun/personal/skylab-backup/circuits/calculate_time_per_grid/time_per_grid.circom";
include "/Users/neal.sun/personal/skylab-backup/circuits/hash_path_data/hash_path_data.circom";

template Main(path_length, map_height, map_width, goal_x, goal_y) {
  // player controllered seed, only hash is on chain
  signal input seed;
  signal input path[path_length][2];
  signal input used_resources[path_length][2];
  signal input map_params[map_height][map_width][3]; 
  signal input start_fuel;
  signal input start_battery;
  signal input level_scaler;
  signal input c1;

  // Check every step is legal
  component abs_diff_x[path_length];
  component abs_diff_y[path_length];
  component lte_1[path_length];

  // Check used resources
  component enough_fuel[path_length];
  component enough_battery[path_length];
  component map_param_selector[path_length];
  component time_per_grid[path_length];

  signal remain_fuel[path_length];
  signal remain_battery[path_length];
  signal final_time[path_length];

  signal output seed_hash;
  signal output map_hash;
  signal output start_fuel_confirm;
  signal output start_battery_confirm;
  signal output final_time_hash;
  signal output path_hash;
  signal output used_resources_hash;
  signal output level_scaler_output;
  signal output c1_output;

  signal output test_final_time;

  // verify starting point
  component x_eq0 = IsEqual();
  x_eq0.in[0] <== path[0][0];
  x_eq0.in[1] <== 0;
  component x_eqN = IsEqual();
  x_eqN.in[0] <== path[0][0];
  x_eqN.in[1] <== map_height - 1;
  component y_eq0 = IsEqual();
  y_eq0.in[0] <== path[0][1];
  y_eq0.in[1] <== 0;
  component y_eqN = IsEqual();
  y_eqN.in[0] <== path[0][1];
  y_eqN.in[1] <== map_width - 1;
  1 === x_eq0.out + x_eqN.out;
  1 === y_eq0.out + y_eqN.out;

  start_fuel_confirm <== start_fuel;
  start_battery_confirm <== start_battery;
  remain_fuel[0] <== start_fuel;
  remain_battery[0] <== start_battery;
  final_time[0] <== 0;

  // for each step of the way, verify the following
  for(var i = 1; i < path_length; i++) {
    // Step 1: verify that each step has at most a distance of 1
    abs_diff_x[i] = AbsoluteDiff();
    abs_diff_y[i] = AbsoluteDiff();
    abs_diff_x[i].in[0] <== path[i][0];
    abs_diff_x[i].in[1] <== path[i-1][0];
    abs_diff_y[i].in[0] <== path[i][1];
    abs_diff_y[i].in[1] <== path[i-1][1];
    lte_1[i] = LessEqThan(32);
    lte_1[i].in[0] <== abs_diff_y[i].diff + abs_diff_x[i].diff;
    lte_1[i].in[1] <== 1;
    lte_1[i].out === 1;

    // Step 2: calculate and verify that the traversal time is correct
    map_param_selector[i] = MapParamsSelector(map_height, map_width);
    map_param_selector[i].map_params <== map_params;
    map_param_selector[i].select_x <== path[i][0];
    map_param_selector[i].select_y <== path[i][1];

    // Step 2-1: verify that the used resource is less than remaing resource
    enough_fuel[i] = GreaterEqThan(32);
    enough_fuel[i].in[0] <== remain_fuel[i - 1];
    enough_fuel[i].in[1] <== used_resources[i][0];
    1 === enough_fuel[i].out;
    enough_battery[i] = GreaterEqThan(32);
    enough_battery[i].in[0] <== remain_battery[i - 1];
    enough_battery[i].in[1] <== used_resources[i][1];
    1 === enough_battery[i].out;
    // Step 2-2: verify that the calculation is correct (also checks resource used is at least 1)
    time_per_grid[i] = TimePerGrid();
    time_per_grid[i].level_scaler <== level_scaler;
    time_per_grid[i].c1 <== c1;
    time_per_grid[i].used_fuel <== used_resources[i][0];
    time_per_grid[i].fuel_scaler <== map_param_selector[i].fuel_scaler;
    time_per_grid[i].used_battery <== used_resources[i][1];
    time_per_grid[i].battery_scaler <== map_param_selector[i].battery_scaler;
    time_per_grid[i].distance <== map_param_selector[i].distance;

    final_time[i] <== final_time[i - 1] + time_per_grid[i].final_time;
    remain_fuel[i] <== remain_fuel[i - 1] - used_resources[i][0];
    remain_battery[i] <== remain_battery[i - 1] - used_resources[i][1];
  }

  // Step 3: check that the final step reached the end
  path[path_length - 1][0] === goal_x;
  path[path_length - 1][1] === goal_y;

  component pos_final_time_hash = Poseidon(2);
  pos_final_time_hash.inputs[0] <== final_time[path_length - 1];
  pos_final_time_hash.inputs[1] <== seed;
  final_time_hash <== pos_final_time_hash.out;

  component pos_seed = Poseidon(2);
  pos_seed.inputs[0] <== seed;
  pos_seed.inputs[1] <== seed;
  seed_hash <== pos_seed.out;

  component hash_per_cell[map_height * map_width];
  component hash_per_roll[map_height];
  component hash_per_map = Poseidon(map_height);
  var index = 0;
  for(var i = 0; i < map_height; i++) {
    // for every row, add all columns into a poseidon hash, and input into hash_per_map
    hash_per_roll[i] = Poseidon(map_width);
    for(var j = 0; j < map_width; j++) {
      // for every cell, add all 3 parameters into a poseidon hash, and input into hash_per_row
      hash_per_cell[index] = Poseidon(3);
      hash_per_cell[index].inputs <== map_params[i][j];
      hash_per_roll[i].inputs[j] <== hash_per_cell[index].out;
      index++;
    }
    hash_per_map.inputs[i] <== hash_per_roll[i].out;
  }
  map_hash <== hash_per_map.out;

  component path_hash_gen = HashPathData(path_length);
  path_hash_gen.seed <== seed;
  path_hash_gen.input_path <== path;
  path_hash <== path_hash_gen.hash_output;

  component resources_hash_gen = HashPathData(path_length);
  resources_hash_gen.seed <== seed;
  resources_hash_gen.input_path <== used_resources;
  used_resources_hash <== resources_hash_gen.hash_output;

  level_scaler_output <== level_scaler;
  c1_output <== c1;

  // test_final_time <== final_time[path_length - 1];
}

template CalculateTotal(n) {
    signal input in[n];
    signal output out;

    signal sums[n];

    sums[0] <== in[0];

    for (var i = 1; i < n; i++) {
        sums[i] <== sums[i-1] + in[i];
    }

    out <== sums[n-1];
}

template AbsoluteDiff() {
  signal input in[2];
  signal gt_sum;
  signal lt_sum;
  signal output diff;

  component gt = GreaterThan(8);
  gt.in[0] <== in[0];
  gt.in[1] <== in[1];
  gt_sum <== gt.out*(in[0] - in[1]);
  lt_sum <== (1 - gt.out)*(in[1] - in[0]);
  diff <== gt_sum + lt_sum;
}

template MapParamsSelector(map_height, map_width) {
    signal input map_params[map_height][map_width][3];
    signal input select_x;
    signal input select_y;
    signal matched[map_height*map_width];
    signal output distance;
    signal output fuel_scaler;
    signal output battery_scaler;

    component x_gte_0 = GreaterEqThan(8);
    x_gte_0.in[0] <== select_x;
    x_gte_0.in[1] <== 0;
    1 === x_gte_0.out;
    component y_gte_0 = GreaterEqThan(8);
    y_gte_0.in[0] <== select_y;
    y_gte_0.in[1] <== 0;
    1 === y_gte_0.out;
    component x_lt_n = LessThan(8);
    x_lt_n.in[0] <== select_x;
    x_lt_n.in[1] <== map_height;
    1 === x_lt_n.out;
    component y_lt_n = LessThan(8);
    y_lt_n.in[0] <== select_y;
    y_lt_n.in[1] <== map_width;
    1 === y_lt_n.out;

    component distance_calc_total = CalculateTotal(map_height * map_width);
    component fuel_scaler_calc_total = CalculateTotal(map_height * map_width);
    component battery_scaler_calc_total = CalculateTotal(map_height * map_width);
    component eq_x[map_height*map_width];
    component eq_y[map_height*map_width];
    var index = 0;
    for(var i = 0; i < map_height; i++) {
      for(var j = 0; j < map_width; j++) {
        eq_x[index] = IsEqual();
        eq_x[index].in[0] <== i;
        eq_x[index].in[1] <== select_x;

        eq_y[index] = IsEqual();
        eq_y[index].in[0] <== j;
        eq_y[index].in[1] <== select_y;

        matched[index] <== eq_x[index].out * eq_y[index].out;

        distance_calc_total.in[index] <== matched[index] * map_params[i][j][0];
        fuel_scaler_calc_total.in[index] <== matched[index] *  map_params[i][j][1];
        battery_scaler_calc_total.in[index] <== matched[index] *  map_params[i][j][2];

        index++;
      }
    }

    distance <== distance_calc_total.out;
    fuel_scaler <== fuel_scaler_calc_total.out;
    battery_scaler <== battery_scaler_calc_total.out;
}

component main = Main(50, 15, 15, 7, 7);