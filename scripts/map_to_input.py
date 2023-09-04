import json
import os
import glob
import subprocess

map_data_paths = ["/Users/neal.sun/personal/mercury-backup/mapData/low_level game maps", "/Users/neal.sun/personal/mercury-backup/mapData/mid_level game maps", "/Users/neal.sun/personal/mercury-backup/mapData/high_level game maps"]
# map_data_paths = ["/Users/neal.sun/personal/mercury-backup/mapData/low_level game maps"]
input_data_dir = "/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/inputs/"
public_dir = "/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/publics/"
generate_proof_command = ["/Users/neal.sun/personal/mercury-backup/tools/generate_proof.sh", "gameboard-traverse"]

map_hash_dir = "/Users/neal.sun/personal/mercury-backup/circuits/gameboard-traverse/maphashes/"

expected_time = {}

def mapToInput(i, file):
	map_json = None
	with open(file, "r") as f:
		map_json = json.loads(f.read())

	input_json = {
		"seed": 1324,
		"path": map_json["path"] + [[7,7] for _ in range(50 - len(map_json["path"]))],
		"used_resources": [[0, 0]] + [[5, 5] for _ in range(len(map_json["path"]) - 2)] + [[0,0] for _ in range(51 - len(map_json["path"]))],
		"map_params": map_json["map_params"],
		"start_fuel": 100,
		"start_battery": 100,
		"level_scaler": 1,
		"c1": {"low_level": 2, "mid_level": 6, "high_level": 17}[map_json["map_type"]]
	}

	input_id = map_json["map_type"] + str(i)
	expected_time[input_id] = int(map_json["expected_time"])

	with open(input_data_dir + input_id + ".json", "w") as f:
		json.dump(input_json, f)

	return input_id

def generate_proof(input_id):
	result = subprocess.run(generate_proof_command + [input_id])
	assert result.returncode == 0, "generate_proof failed" + input_id

def process_result(input_id, check_time):
	with open(public_dir + input_id + ".json", "r") as f:
		public_json = json.loads(f.read())

	if check_time:
		if int(public_json[-1]) != expected_time[input_id]:
			print(f"expected_time not equal for {input_id}, expected {expected_time[input_id]}, actual {int(public_json[-1])}")
		else:
			print(expected_time[input_id])

	with open(map_hash_dir + input_id[:2], mode='a') as f:
		f.write(public_json[1] + "\n")

def allMapsToInput(dir_path):
	# get a list of all files in the directory using glob
	files = sorted(glob.glob(os.path.join(path, "*")), key=lambda e: int(e.split("_")[-1].split(".")[0]))

	# loop through each file and open it
	for i, file in enumerate(files[:300]):
		input_id = mapToInput(i, file)
		generate_proof(input_id)
		process_result(input_id, False)
		print(f"Done {input_id}")

for path in map_data_paths:
	allMapsToInput(path)
