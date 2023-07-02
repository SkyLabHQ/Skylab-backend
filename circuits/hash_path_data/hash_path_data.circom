pragma circom 2.0.3;

include "/Users/neal.sun/.nvm/versions/node/v16.19.1/lib/node_modules/circomlib/circuits/poseidon.circom";

template HashPathData(path_length) {
    signal input seed;
    signal input input_path[path_length][2];

    var set_size = 5;
    var sets = path_length \ set_size;

    component hash_gen = Poseidon(sets + 1);
    component sub_hash_gen[sets];

    signal output hash_output;
    signal output input_confirm[path_length][2];

    var sub_hash_gen_index = -1;
    for (var i = 0; i < path_length; i++) {
        if (i % set_size == 0) {
            sub_hash_gen_index += 1;
            sub_hash_gen[sub_hash_gen_index] = Poseidon(set_size * 2);
        }
        var adjusted_i = i - sub_hash_gen_index * set_size;
        sub_hash_gen[sub_hash_gen_index].inputs[adjusted_i*2] <== input_path[i][0];
        sub_hash_gen[sub_hash_gen_index].inputs[adjusted_i*2 + 1] <== input_path[i][1];
    }

    for (var i = 0; i < sets; i++) {
        hash_gen.inputs[i] <== sub_hash_gen[i].out;
    }
    hash_gen.inputs[sets] <== seed;

    hash_output <== hash_gen.out;
    input_confirm <== input_path;
}
