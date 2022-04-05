const { expect } = require("chai");
const { fixture } = deployments;
const { printGas, increaseTime } = require("../utils/transactions");
const {
	getToken,
	impersonateTokens,
	allowance,
	balanceOf,
	UNISWAP,
	transfer,
} = require("../utils/tokens");

describe("Lottery", () => {
	beforeEach(async () => {
		({ deployer, user } = await getNamedAccounts());
		userSigner = await ethers.provider.getSigner(user);
		await fixture(["lottery"]);
		lottery = await ethers.getContract("Lottery");
		tickets = await ethers.getContract("Ticket");
		random = await ethers.getContract("GenerateRandom");
		compound = await ethers.getContract("Compound");

		DAI_TOKEN = getToken("DAI");
		CDAI_TOKEN = getToken("CDAI");

		USDC_TOKEN = getToken("USDC");
		LINK_TOKEN = getToken("LINK");

		const setMinterTx = await tickets.setMinter(lottery.address);
		await setMinterTx.wait();

		const setCompoundAdmintx = await compound.setAdmin(lottery.address);
		await printGas(setCompoundAdmintx);

		impersonateDAI = "0x5d38b4e4783e34e2301a2a36c39a03c45798c4dd";
		impersonateUSDC = "0x61f2f664fec20a2fc1d55409cfc85e1baeb943e2";
		impersonateLINK = "0x0d4f1ff895d12c34994d6b65fabbeefdc1a9fb39";
	});
	describe("basic config", () => {
		it("correct ticket address", async () => {
			const ticketAddress = await lottery.lotteryTickets();
			expect(ticketAddress).to.be.eq(tickets.address);
		});
		it("lottery should be a minter of tickets", async () => {
			const minterRole = await tickets.MINTER();
			const isMinter = await tickets.hasRole(minterRole, lottery.address);
			expect(isMinter);
		});
		it("uniswap address", async () => {
			const address = await lottery.uniSwapRouter();
			expect(address).to.be.eq(UNISWAP);
		});
		it("lottery should be compound admin", async () => {
			const adminRole = await compound.DEFAULT_ADMIN_ROLE();
			const isAdmin = await tickets.hasRole(adminRole, lottery.address);
			expect(isAdmin);
		});
	});
	describe("star lottery", async () => {
		beforeEach(async () => {
			await impersonateTokens({
				tokenAddress: DAI_TOKEN.address,
				amount: "1000000",
				impersonateAddress: impersonateDAI,
				fundAddress: deployer,
			});
			await allowance({
				tokenAddress: DAI_TOKEN.address,
				contractAddress: lottery.address,
				fundAddress: deployer,
				amount: "20",
			});
			await impersonateTokens({
				tokenAddress: USDC_TOKEN.address,
				amount: "1000000",
				impersonateAddress: impersonateUSDC,
				fundAddress: deployer,
			});

			await allowance({
				tokenAddress: USDC_TOKEN.address,
				contractAddress: lottery.address,
				fundAddress: deployer,
				amount: "20",
			});
		});
		it("lottery swap", async () => {
			const preDaiBalance = await balanceOf({
				tokenAddress: DAI_TOKEN.address,
				userAddress: lottery.address,
			});

			const tx = await lottery.buyTicketWithToken(USDC_TOKEN.address, 10);

			await printGas(tx);
			const postDaiBalance = await balanceOf({
				tokenAddress: DAI_TOKEN.address,
				userAddress: lottery.address,
			});

			expect(postDaiBalance).to.be.gt(preDaiBalance);
		});

		it("pass 2 days storage on next lottery but doesnt start", async () => {
			const tx1 = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx1);
			await increaseTime(60 * 60 * 24 * 3);

			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);
			const actualLottery = await lottery.actualLottery();
			const lotteryObj = await lottery.lotteries(actualLottery);
			expect(actualLottery).to.be.eq(1);
			expect(lotteryObj.startTime).to.be.eq(0);
		});
		it("store correct user info", async () => {
			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);

			const buyInfo = await lottery.balanceOf(0, 0);
			expect(buyInfo.minNumber).to.be.eq(1);
			expect(buyInfo.maxNumber).to.be.eq(10);
			expect(buyInfo.owner).to.be.eq(deployer);
		});
	});
	describe("claim winner", () => {
		beforeEach(async () => {
			await impersonateTokens({
				tokenAddress: DAI_TOKEN.address,
				amount: "1000000",
				impersonateAddress: impersonateDAI,
				fundAddress: deployer,
			});
			await allowance({
				tokenAddress: DAI_TOKEN.address,
				contractAddress: lottery.address,
				fundAddress: deployer,
				amount: "20",
			});
			await impersonateTokens({
				tokenAddress: USDC_TOKEN.address,
				amount: "1000000",
				impersonateAddress: impersonateUSDC,
				fundAddress: deployer,
			});

			await allowance({
				tokenAddress: USDC_TOKEN.address,
				contractAddress: lottery.address,
				fundAddress: deployer,
				amount: "20",
			});

			await impersonateTokens({
				tokenAddress: LINK_TOKEN.address,
				amount: ethers.utils.parseEther("1000"),
				impersonateAddress: impersonateLINK,
				fundAddress: deployer,
			});

			await transfer({
				tokenAddress: LINK_TOKEN.address,
				contractAddress: random.address,
				fundAddress: deployer,
				amount: ethers.utils.parseEther("1000"),
			});
		});

		it("fail lottery not finished", async () => {
			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);

			await expect(lottery.claimWinner()).to.be.revertedWith(
				"This sell is on voting time!"
			);
		});
		it("fail no one buy token", async () => {
			await expect(lottery.claimWinner()).to.be.revertedWith(
				"No one buy tickets to this lottery restarting lottery!"
			);
		});
		it("set winner", async () => {
			let tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);

			await increaseTime(60 * 60 * 24 * 2.3);
			tx = await lottery.invest();
			await printGas(tx);

			await increaseTime(60 * 60 * 24 * 5);

			tx = await lottery.getRandomNumber();
			await printGas(tx);

			await increaseTime(60 * 60 * 24);

			tx = await lottery.claimWinner();
			await printGas(tx);

			const actualLottery = await lottery.lotteries(0);
			expect(actualLottery.winner).to.be.eq(deployer);
			expect(actualLottery.isComplete);
			expect(actualLottery.ticketWinner).to.be.eq(1);
		});
	});
	describe("invest on compound", () => {
		beforeEach(async () => {
			const amount = "1000000";
			await impersonateTokens({
				tokenAddress: DAI_TOKEN.address,
				amount,
				impersonateAddress: impersonateDAI,
				fundAddress: deployer,
			});
			await allowance({
				tokenAddress: DAI_TOKEN.address,
				contractAddress: lottery.address,
				fundAddress: deployer,
				amount,
			});

			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, amount);
			await printGas(tx);
		});
		it("fail invest, before 2 days", async () => {
			await expect(lottery.invest()).to.be.revertedWith(
				"This sell is on voting time!"
			);
		});

		it("invest", async () => {
			await increaseTime(60 * 60 * 24 * 2.5);
			const tx = await lottery.invest();
			await printGas(tx);

			const balance = await balanceOf({
				tokenAddress: CDAI_TOKEN.address,
				userAddress: compound.address,
			});
			expect(balance).to.be.eq(10);
		});
	});
	describe("claim reward", () => {
		beforeEach(async () => {});
		it("fail already claimed", () => {});
		it("claim", () => {});
	});
});
