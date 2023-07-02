import json
import os
import glob
import subprocess

merc_path = "/Users/neal.sun/Downloads/Merc/"
metadata_path = "/Users/neal.sun/Downloads/Merc/metadata/"
trait_data_dict = {
	"Body Color": ["Azure", "Pink", "Lime Yellow", "Chrome Green", "Pastel Aqua", "Lavander Pink", "Cantaloupe", "Coral", "Violet", "Ultramarine", "Light Sand", "Sage Green", "Thulian", "Olive", "Warm Gray", "Cold Gray", "Black", "Tale Blue", "Artichoke Green", "Stone Blue"],
	"Controller": ["Switch", "Lollipop Joystick", "Coral-aqua Joy Pad", "Purple Game Pad", "Magic Wand Joystick", "Hammer Joystick", "Basketball-shape Joystick", "Orange Wii Controller", "Aqua Game Pad", "Orange Game Pad", "Gray Rectangle Wii Controller", "Microphone Joystick", "Oliver Rectangle Wii Controller", "Pink Rectangle Wii Controller", "Purple Game Pad", "Red Game Pad", "Purple Joy Pad"],
	"Eye": ["Green Devious", "Azure Spell-bound", "Azure Rolling", "Red Curious", "Orange Blinky", "Purple Dubious", "Green Spell-bound", "Purple Spell-bound", "Yellow Rolling", "Blue Rolling", "Purple Curious", "Aqua Curious", "Green Angry", "Indigo Angry", "Flesh Angry", "Green Scared", "Orange Scared", "Blue Scared", "Pink Shocked", "Aqua Dubious", "Pink Dubious", "Olive Stunned", "Coral Stunned", "Purple Stunned", "Pink Thoughful", "Blue Thoughtful", "Purple Thoughtful", "Aqua Crying", "Olive Crying", "Lilac Crying", "Beige Shocked", "Aua Blinky", "Red Blinky", "Aqua Devious", "Green Shocked", "Pink Devious", "Sand Sad", "Purple Sad", "Aqua Sad"],
	"Mouth": ["Suprised", "Sick", "Wicked Smile", "Stuffed", "Satisfied", "Silent", "Floating", "Shocked", "Eagerly", "Disdain", "Laughing"],
	"Helmet Color": ["Cyberpunk", "Oragnic", "Aurora", "Holographic", "Spring", "Silent", "Sand", "Thulian", "Grass Green", "Berry", "Violet", "Sage Green", "Cool Gradient", "Club Gradient"],
	"Goggle": ["Purple-yellow Rectangular", "Holographic Winter Sport", "Purple VR", "Brown-azure Rectangular", "Green-Coral Round", "Green Round", "Indigo Round", "Pink-aqua Rectangular", "Pink VR", "Green VR", "Violet Winter Sport", "Pink Winter Sport", "Pastel Winter Sport", "Green Diving", "Pink Diving", "Blue Round", "Marron-green Rectangular"],
	"Effect": ["Ignis Fatuus", "Laser", "Spell", "Cyclops", "Wave", "Music", "Starry", "Empty"]
}


def translate(id, file):
	image = f"baseURI/{id}.png"
	traits = {}

	with open(file, "r") as f:
		for line in f.readlines():
			trait_type, value = line.split(",")
			if trait_type == "Background":
				traits[trait_type] = value
			else:
				traits[trait_type] = trait_data_dict[trait_type][int(value) - 1]

	return image, traits

def store_metadata(id, image, traits):
	metadata = {}
	metadata["name"] = "#" + str(id)
	metadata["image"] = image
	metadata["attributes"] = []
	for trait_type, value in traits.items():
		metadata["attributes"].append({
			"trait_type": trait_type,
			"value": value
			})

	with open(metadata_path + str(id) + ".json", "w") as f:
		f.write(json.dumps(metadata))


def parse_merc(dir_path):
	files = sorted(glob.glob(os.path.join(merc_path, "*.txt")))

	# loop through each file and open it
	for i, file in enumerate(files):
		try:
			image, traits = translate(i, file)
			store_metadata(i, image, traits)
			print(f"Done {file}")
		except:
			print(f"FAILED {file}")

parse_merc(merc_path)