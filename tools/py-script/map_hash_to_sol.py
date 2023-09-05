map_hash_dir = "/Users/neal.sun/personal/skylab-backup/circuits/gameboard-traverse/maphashes/"
map_hash_sol = "/Users/neal.sun/personal/skylab-backup/MapHashes.sol"

with open(map_hash_sol, "w") as s:
	s.write("// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\ncontract MapHashes {\n\n\tuint[300] public hashes_low;\n\tuint[300] public hashes_mid;\n\tuint[100] public hashes_high;\n\n\tconstructor() {")

	with open(map_hash_dir + "lo", "r") as f:
		for i, line in enumerate(f.readlines()):
			s.write("\t\thashes_low[" + str(i) + "] = " + line.strip() + ";\n")
			if i == 299:
				break

	with open(map_hash_dir + "mi", "r") as f:
		for i, line in enumerate(f.readlines()):
			s.write("\t\thashes_mid[" + str(i) + "] = " + line.strip() + ";\n")
			if i == 299:
				break

	with open(map_hash_dir + "hi", "r") as f:
		for i, line in enumerate(f.readlines()):
			s.write("\t\thashes_high[" + str(i) + "] = " + line.strip() + ";\n")

	s.write("\t}\n}")