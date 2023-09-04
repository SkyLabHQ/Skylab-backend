
## Documentation

### INSTALL
#### Foundry
```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```
#### Ape framework
```
$ python3 -m venv /path/to/new/environment
$ source /bin/activate
$ deactivate
$ pip install -U pip
$ pip install eth-ape
```

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ ape accounts generate test
$ ape run sceipts/deploy_diamond.py
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
