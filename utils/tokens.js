const abi = [
	{
		inputs: [
			{
				internalType: "uint256",
				name: "_totalSupply",
				type: "uint256",
			},
		],
		stateMutability: "nonpayable",
		type: "constructor",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "owner",
				type: "address",
			},
			{
				indexed: true,
				internalType: "address",
				name: "spender",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "value",
				type: "uint256",
			},
		],
		name: "Approval",
		type: "event",
	},
	{
		anonymous: false,
		inputs: [
			{
				indexed: true,
				internalType: "address",
				name: "from",
				type: "address",
			},
			{
				indexed: true,
				internalType: "address",
				name: "to",
				type: "address",
			},
			{
				indexed: false,
				internalType: "uint256",
				name: "value",
				type: "uint256",
			},
		],
		name: "Transfer",
		type: "event",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "owner",
				type: "address",
			},
			{
				internalType: "address",
				name: "spender",
				type: "address",
			},
		],
		name: "allowance",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "spender",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "amount",
				type: "uint256",
			},
		],
		name: "approve",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "account",
				type: "address",
			},
		],
		name: "balanceOf",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "decimals",
		outputs: [
			{
				internalType: "uint8",
				name: "",
				type: "uint8",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "spender",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "subtractedValue",
				type: "uint256",
			},
		],
		name: "decreaseAllowance",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "spender",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "addedValue",
				type: "uint256",
			},
		],
		name: "increaseAllowance",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [],
		name: "name",
		outputs: [
			{
				internalType: "string",
				name: "",
				type: "string",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "symbol",
		outputs: [
			{
				internalType: "string",
				name: "",
				type: "string",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [],
		name: "totalSupply",
		outputs: [
			{
				internalType: "uint256",
				name: "",
				type: "uint256",
			},
		],
		stateMutability: "view",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "to",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "amount",
				type: "uint256",
			},
		],
		name: "transfer",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
	{
		inputs: [
			{
				internalType: "address",
				name: "from",
				type: "address",
			},
			{
				internalType: "address",
				name: "to",
				type: "address",
			},
			{
				internalType: "uint256",
				name: "amount",
				type: "uint256",
			},
		],
		name: "transferFrom",
		outputs: [
			{
				internalType: "bool",
				name: "",
				type: "bool",
			},
		],
		stateMutability: "nonpayable",
		type: "function",
	},
];

const networkId = process.env.NETWORKID;

async function allowance({
	tokenAddress,
	contractAddress,
	fundAddress,
	amount,
}) {
	const signer = await ethers.provider.getSigner(fundAddress);

	const tokenContract = new ethers.Contract(tokenAddress, abi, signer.provider);
	const txApprove = await tokenContract
		.connect(signer)
		.approve(contractAddress, amount);

	await txApprove.wait();
}

async function balanceOf({ tokenAddress, userAddress }) {
	const signer = await ethers.provider.getSigner(userAddress);

	const tokenContract = new ethers.Contract(tokenAddress, abi, signer.provider);
	const balanceOf = await tokenContract.connect(signer).balanceOf(userAddress);

	return balanceOf;
}
async function impersonateTokens({
	fundAddress,
	impersonateAddress,
	tokenAddress,
	amount,
}) {
	await hre.network.provider.request({
		method: "hardhat_impersonateAccount",
		params: [impersonateAddress],
	});
	const signer = await ethers.provider.getSigner(impersonateAddress);

	const tokenContract = new ethers.Contract(tokenAddress, abi, signer.provider);
	const tx = await tokenContract.connect(signer).transfer(fundAddress, amount);
	await tx.wait();
}

function getToken(symbol) {
	const token = tokens[networkId]?.find((t) => t.symbol === symbol);

	if (!token)
		throw new Error(`Token ${symbol} not available on network ${networkId}`);
	return token;
}

const tokens = {
	[1]: [
		{
			decimals: 18,
			symbol: "ETH",
			address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
		},
		{
			decimals: 6,
			symbol: "USDC",
			address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
		},
		{
			decimals: 18,
			symbol: "DAI",
			address: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
		},
		{
			decimals: 18,
			symbol: "ALBT",
			address: "0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0",
		},
	],
	[137]: [
		{
			decimals: 18,
			symbol: "MATIC",
			address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
		},
		{
			decimals: 8,
			symbol: "WBTC",
			address: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6",
		},
		{
			decimals: 18,
			symbol: "WETH",
			address: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
		},
	],
};
const UNISWAP = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; //mainnet

module.exports = {
	allowance,
	balanceOf,
	impersonateTokens,
	tokens,
	getToken,
	UNISWAP,
};
