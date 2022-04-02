const { expect } = require("chai");
const { fixture } = deployments;
const { printGas, increaseTime } = require("../utils/transactions");
const { getToken, impersonateTokens, allowance } = require("../utils/tokens");

describe("Lottery", () => {
	beforeEach(async () => {
		({ deployer, user } = await getNamedAccounts());
		userSigner = await ethers.provider.getSigner(user);
		await fixture(["lottery"]);
		lottery = await ethers.getContract("Lottery");
		tickets = await ethers.getContract("Ticket");
		DAI_TOKEN = getToken("DAI");
		const setMinterTx = await tickets.setMinter(lottery.address);
		await setMinterTx.wait();
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
	});
	describe("star lottery", async () => {
		beforeEach(async () => {
			impersonateDAI = "0x5d38b4e4783e34e2301a2a36c39a03c45798c4dd";
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
		});
		it("start lottery", async () => {
			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);
			const actualLottery = await lottery.lotteries(0);
			expect(actualLottery.startTime).to.be.gt(0);
		});
		it("pass 2 days storage on next lottery", async () => {
			const tx1 = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx1);
			await increaseTime(60 * 60 * 24 * 3);

			const tx = await lottery.buyTicketWithToken(DAI_TOKEN.address, 10);
			await printGas(tx);
			const actualLottery = await lottery.actualLottery();
			expect(actualLottery).to.be.eq(1);
		});
	});
});
