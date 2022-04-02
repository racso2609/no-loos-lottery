const { expect } = require("chai");
const { fixture } = deployments;
// const { printGas, toWei } = require("../utils/transactions");

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
	});
	describe("mint", () => {
		it("mint fail not minter", async () => {
			await expect(ticket.mint(1, 10, user)).to.be.reverted;
		});
	});
});