const { expect } = require("chai");
const { fixture } = deployments;
const {
	printGas,
	increaseBlocks,
	increaseTime,
} = require("../utils/transactions");
const {
	getToken,
	impersonateTokens,
	allowance,
	balanceOf,
} = require("../utils/tokens");

describe("Compound test", () => {
	beforeEach(async () => {
		({ deployer, user } = await getNamedAccounts());

		userSigner = await ethers.provider.getSigner(user);
		await fixture(["Compound"]);
		compound = await ethers.getContract("Compound");

		DAI_TOKEN = getToken("DAI");
		CDAI_TOKEN = getToken("CDAI");
		impersonateDAI = "0x5d38b4e4783e34e2301a2a36c39a03c45798c4dd";
	});
	describe("basic", () => {
		it("deployer is admin", async () => {
			const adminRole = await compound.DEFAULT_ADMIN_ROLE();
			const isAdmin = await compound.hasRole(adminRole, deployer);
			expect(isAdmin);
		});
		it("setAdmin", async () => {
			const adminRole = await compound.DEFAULT_ADMIN_ROLE();
			const tx = await compound.setAdmin(user);
			printGas(tx);
			const isAdmin = await compound.hasRole(adminRole, user);
			expect(isAdmin);
		});
		it("setAdmin no admin user", async () => {
			await expect(compound.connect(userSigner).setAdmin(user)).to.be.reverted;
		});
	});
	describe("defi investement", () => {
		beforeEach(async () => {
			supplyAmount = ethers.utils.parseEther("3000");

			await impersonateTokens({
				tokenAddress: DAI_TOKEN.address,
				amount: supplyAmount,
				impersonateAddress: impersonateDAI,
				fundAddress: deployer,
			});

			await allowance({
				tokenAddress: DAI_TOKEN.address,
				contractAddress: compound.address,
				fundAddress: deployer,
				amount: supplyAmount,
			});
		});
		it("correct start info", async () => {
			expect(await compound.token()).to.be.eq(DAI_TOKEN.address);
			expect(await compound.cToken()).to.be.eq(CDAI_TOKEN.address);
			expect(await compound.decimals()).to.be.eq(DAI_TOKEN.decimals);
			expect(await compound.cDecimals()).to.be.eq(CDAI_TOKEN.decimals);
		});

		it("supply and redeem", async () => {
			let tx = await compound.supply(supplyAmount);
			await printGas(tx);

			const preCTokenBalance = await compound.getCTokenBalance();

			await increaseBlocks(1000);
			await increaseTime(60 * 60 * 24 * 5);

			tx = await compound.redeem(preCTokenBalance);
			await printGas(tx);

			const balancePostRedeem = await balanceOf({
				tokenAddress: DAI_TOKEN.address,
				userAddress: deployer,
			});

			expect(preCTokenBalance).to.be.gt(0);
			expect(balancePostRedeem).to.be.gt(supplyAmount);
		});
	});
});
