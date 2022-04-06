const { expect } = require("chai");
const { fixture } = deployments;
const { printGas } = require("../utils/transactions");
const { getToken, impersonateTokens, transfer } = require("../utils/tokens");

describe("Generate random number", () => {
	beforeEach(async () => {
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

		await transfer({
			tokenAddress: LINK_TOKEN.address,
			contractAddress: randomGenerator.address,
			fundAddress: deployer,
			amount: ethers.utils.parseEther("1000"),
		});
	});

	it("get randomness", async () => {
		const tx = await randomGenerator.getRandomness();
		await printGas(tx);
		console.log("random number", await randomGenerator.randomNumber());
		expect(randomGenerator.requestId).exist;
	});
});
