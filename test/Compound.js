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
			supplyAmount = "1000000";
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
			console.log(
				"before",
				await balanceOf({
					tokenAddress: DAI_TOKEN.address,
					userAddress: deployer,
				})
			);
			console.log(
				"before cDai",
				await balanceOf({
					tokenAddress: CDAI_TOKEN.address,
					userAddress: deployer,
				})
			);
			let tx = await compound.supply(supplyAmount);
			await printGas(tx);
			console.log(
				"after",
				await balanceOf({
					tokenAddress: DAI_TOKEN.address,
					userAddress: deployer,
				})
			);
			console.log(
				"after cdai",
				await balanceOf({
					tokenAddress: CDAI_TOKEN.address,
					userAddress: compound.address,
				})
			);

			const preCTokenBalance = await compound.getCTokenBalance();
			console.log(preCTokenBalance.toString()); //return 0 -_- whyyyy

			await increaseBlocks(100);
			const postCTokenBalance = await compound.getCTokenBalance();
			console.log(postCTokenBalance.toString());

			tx = await compound.redeem(supplyAmount);
			printGas(tx);
			const balancePostRedeem = await compound.getCTokenBalance();

			expect(preCTokenBalance).to.be.eq(supplyAmount);
			expect(postCTokenBalance).to.be.gt(preCTokenBalance);
			expect(postCTokenBalance.sub(supplyAmount)).to.be.eq(balancePostRedeem);
		});
	});
});
