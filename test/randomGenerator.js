const { expect } = require("chai");
const { fixture } = deployments;
const { printGas, increaseTime } = require("../utils/transactions");
const { getToken, impersonateTokens, transfer } = require("../utils/tokens");

describe("Generate random number", () => {
	beforeEach(async () => {
		({ deployer, user } = await getNamedAccounts());
		await fixture(["GenerateRandom"]);
		randomGenerator = await ethers.getContract("GenerateRandom");

		LINK_TOKEN = getToken("LINK");
		impersonateLINK = "0x0d4f1ff895d12c34994d6b65fabbeefdc1a9fb39";
		await impersonateTokens({
			tokenAddress: LINK_TOKEN.address,
			amount: ethers.utils.parseEther("1000"),
			impersonateAddress: impersonateLINK,
			fundAddress: deployer,
		});
	});

	it("get randomness", async () => {
		await transfer({
			tokenAddress: LINK_TOKEN.address,
			contractAddress: randomGenerator.address,
			fundAddress: deployer,
			amount: ethers.utils.parseEther("1000"),
		});
		const tx = await randomGenerator.getRandomness();
		await printGas(tx);
		expect(randomGenerator.requestId).exist;
	});
	it("fail not link", async () => {
		await expect(randomGenerator.getRandomness()).to.be.reverted;
	});
	it("roll dice", async () => {
		await transfer({
			tokenAddress: LINK_TOKEN.address,
			contractAddress: randomGenerator.address,
			fundAddress: deployer,
			amount: ethers.utils.parseEther("1000"),
		});
		let tx = await randomGenerator.getRandomness();
		await printGas(tx);
		await increaseTime(60 * 60 * 30);

		const randomNumber = await randomGenerator.rollDice(3);
		// console.log(await randomGenerator.randomNumber());

		// console.log(tx);
		// const recipient = await ethers.provider.getTransactionReceipt(tx.hash);

		// console.log(recipient);
		expect(randomNumber).gt(0);
		expect(randomNumber).lt(3);
	});
});
