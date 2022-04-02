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
			console.log(tx);
		});
	});
});
