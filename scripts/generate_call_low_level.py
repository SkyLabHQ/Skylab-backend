import json
import subprocess
import sys
map_id = sys.argv[1]
token_id = sys.argv[2]
opponent_id = sys.argv[3]
map_data_path = f"/Users/neal.sun/personal/mercury-backup/mapData/low_level game maps/test_strategy_fullmap_{map_id}.json"
input_data_path = f"/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/inputs/low_level{map_id}.json"
public_data_path = f"/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/publics/low_level{map_id}.json"
proof_data_path = f"/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/proofs/low_level{map_id}.json"
generate_proof_command = ["/Users/neal.sun/personal/mercury-backup/tools/generate_proof.sh", "gameboard-traverse"]

# Step 1: create input data, generate call data for gameboard traversal
map_json = None
with open(map_data_path, "r") as f:
	map_json = json.loads(f.read())

input_json = {
	"seed": 1324,
	"opponent_id": int(opponent_id),
	"path": map_json["path"] + [[7,7] for _ in range(50 - len(map_json["path"]))],
	"used_resources": [[0, 0]] + [[1, 1] for _ in range(len(map_json["path"]) - 2)] + [[0,0] for _ in range(51 - len(map_json["path"]))],
	"map_params": map_json["map_params"],
	"start_fuel": 20,
	"start_battery": 29,
	"level_scaler": 1,
	"c1": 2
}

with open(input_data_path, "w") as f:
	json.dump(input_json, f)
input("Ready?")

subprocess.run(generate_proof_command + [f"low_level{map_id}"])
subprocess.run(["cp", public_data_path, "/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/public.json"])
subprocess.run(["cp", proof_data_path, "/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/proof.json"])
call_data_0 = token_id + "," + subprocess.check_output(["snarkjs", "generatecall"]).decode('UTF-8').rstrip()

with open(input_data_path, "r") as f:
	input_json = json.loads(f.read())

# Step 2: calculate time using individual grid and resources
total_time = 0
for i, coordinates in enumerate(input_json["path"]):
	fuel, battery = input_json["used_resources"][i]
	distance, fuel_scaler, battery_scaler = input_json["map_params"][coordinates[0]][coordinates[1]]

	calculate_time_per_grid_input = {
		"level_scaler": 1,
    	"c1": 2,
    	"used_fuel": int(fuel),
    	"fuel_scaler": int(fuel_scaler),
    	"used_battery": int(battery),
    	"battery_scaler": int(battery_scaler),
    	"distance": int(distance)
	}
	with open("/Users/neal.sun/personal/mercury-backup/circuits/calculate_time_per_grid/inputs/temp.json", "w") as f:
		json.dump(calculate_time_per_grid_input, f)

	result = subprocess.run(["/Users/neal.sun/personal/mercury-backup/tools/generate_proof.sh", "calculate_time_per_grid", "temp"], cwd="/Users/neal.sun/personal/mercury-backup/circuits/calculate_time_per_grid/")
	assert result.returncode == 0

	with open("/Users/neal.sun/personal/mercury-backup/circuits/calculate_time_per_grid/publics/temp.json", "r") as f:
		public_json = json.loads(f.read())
	total_time += int(public_json[0])

# Step 3: create path data post hash
call_data_for_path_hash = []
for path_data in [input_json["path"], input_json["used_resources"]]:
	compute_hash_path_data_input = {
		"seed": 1324,
		"input_path": path_data
	}
	with open("/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/inputs/temp.json", "w") as f:
		json.dump(compute_hash_path_data_input, f)
	result = subprocess.run(["/Users/neal.sun/personal/mercury-backup/tools/generate_proof.sh", "compute_hash_path_data", "temp"], cwd="/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/")
	assert result.returncode == 0
	subprocess.run(["cp", "/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/publics/temp.json", "/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/public.json"])
	subprocess.run(["cp", "/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/proofs/temp.json", "/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/proof.json"])
	call_data_for_path_hash.append(token_id + "," + subprocess.check_output(["snarkjs", "generatecall"], cwd="/Users/neal.sun/personal/mercury-backup/circuits/hash_path_data/").decode('UTF-8').rstrip())

print(call_data_0)
print(f"{token_id},1324,{total_time}," + ",".join(call_data_for_path_hash))
