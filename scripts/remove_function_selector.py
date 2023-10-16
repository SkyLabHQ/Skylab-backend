from ape import accounts, project
from scripts import constant

FacetCutAction = {"Add": 0, "Replace": 1, "Remove": 2}

cut = []

account = accounts.load('deployer')
account.set_autosign(True, passphrase="y")
protocol_address = constant.PROTOCOL_ADDRESS
game_address = constant.MERCURY_BIDTACTOE_ADDRESS
aviation_address = constant.AVIATION_ADDRESS
zero_address = '0x'+'0'*40

def main():
    # Remove Game functions
    facet = project.Diamond.at(game_address).facets()
    print(facet)
    hexbytes_array = ['0x' + bytes.hex(hexbyte) for hexbyte in facet[1]]
    print(hexbytes_array)
    cut.append((
        zero_address,
        FacetCutAction['Remove'],
        hexbytes_array
    ))
    project.Diamond.at(game_address).diamondCut(cut,zero_address, '0x', sender=account)

    # Remove aviation functions
    facet = project.Diamond.at(aviation_address).facets()
    print(facet)
    hexbytes_array = ['0x' + bytes.hex(hexbyte) for hexbyte in facet[1]]
    print(hexbytes_array)
    cut.append((
        zero_address,
        FacetCutAction['Remove'],
        hexbytes_array
    ))
    project.Diamond.at(aviation_address).diamondCut(cut,zero_address, '0x', sender=account)
    
    # Romove protocol functions
    facet = project.Diamond.at(protocol_address).facets()
    print(facet)
    hexbytes_array = ['0x' + bytes.hex(hexbyte) for facet in facet for hexbyte in facet.functionSelectors]
    print(hexbytes_array)
    cut.append((
        zero_address,
        FacetCutAction['Remove'],
        hexbytes_array
    ))
    project.Diamond.at(protocol_address).diamondCut(cut,zero_address, '0x', sender=account)