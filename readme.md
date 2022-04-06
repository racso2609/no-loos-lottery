# no loss lottery

buy tickets with any erc20 token, the contract will swap this to dai and will calculate the amount of tickets with the dai amount, each ticket have a value of 1 DAI.

to claim winner we use chainlink ConsumerBaseV1, and use compound to invest the money of each lottery and get profit to pay the winner prize.

tickets are erc1155, it use the lottery identifier to mint the corresponding collection of tokens


## commands
```
yarn  // to initialize repo
yarn test // run test suite on mainnet fork
yarn deploy // deploy contract to mainnet
yarn compile //compile all contracts
yarn coverage // check coverage report
```

