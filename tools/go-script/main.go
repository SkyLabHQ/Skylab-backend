package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"skylab/config"
	contract "skylab/contracts"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	contractAddress := common.HexToAddress(config.ContractAddress)

	client, err := ethclient.Dial(config.EthNodeURL)
	if err != nil {
		log.Fatal(err)
	}

	con, _ := contract.NewContract(contractAddress, client)
	ch := make(chan *contract.ContractLevelUpdate, 10)
	start := uint64(0)
	sub, _ := con.WatchLevelUpdate(&bind.WatchOpts{
		Start: &start,
	}, ch)

	for {
		select {
		case err := <-sub.Err():
			log.Fatal(err)
		case event := <-ch:
			log.Println(event.TokenId)
			//url := "https://api.opensea.io/v2/chain/Ethereum/contract/0x985721572aa5df666e2b0fc7cbb056a56cb41963/nfts/1737/refresh"
			url := fmt.Sprintf("https://api.opensea.io/v2/chain/Ethereum/contract/%s/nfts/%d/refresh", config.ContractAddress, event.TokenId)
			req, _ := http.NewRequest("POST", url, nil)

			req.Header.Add("accept", "application/json")
			req.Header.Add("X-API-KEY", "0c44945fac1e4c99bf6bad572de8b9bf")

			res, _ := http.DefaultClient.Do(req)

			defer res.Body.Close()
			body, _ := io.ReadAll(res.Body)

			fmt.Println(string(body))
		}

	}
}
