const { expect } = require("chai");
const { fixture } = deployments;
const { printGas } = require("../utils/transactions");

describe("Lottery Tickets", () => {
	beforeEach(async () => {
		({ deployer, user } = await getNamedAccounts());
		userSigner = await ethers.provider.getSigner(user);
		await fixture(["Ticket"]);
		ticket = await ethers.getContract("Ticket");
	});

	describe("basic info", () => {
		it("deployer is admin", async () => {
			const adminRole = await ticket.DEFAULT_ADMIN_ROLE();
			const isAdmin = await ticket.hasRole(adminRole, deployer);

			expect(isAdmin);
		});
		it("setminter fail not admin", async () => {
			await expect(ticket.connect(user).setMinter(user)).to.be.reverted;
		});

		it("setminter", async () => {
			const tx = await ticket.setMinter(user);
			await printGas(await tx);
			const minterRole = await ticket.MINTER();
			const isMinter = await ticket.hasRole(minterRole, user);
			expect(isMinter);
		});
	});
	describe("mint", () => {
		it("mint fail not minter", async () => {
			await expect(ticket.mint(1, 10, user)).to.be.reverted;
		});
		it("mint", async () => {
			const mintTx = await ticket.setMinter(deployer);
			await mintTx.wait();
			const tx = await ticket.mint(1, 1, user);
			await printGas(tx);
			const balance = await ticket.balanceOf(user, 1);
			expect(balance).to.be.eq(1);
		});
	});
});
