const CONTRACT_NAME = "Lottery";
const { UNISWAP } = require("../utils/tokens");

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy } = deployments;
	const { deployer } = await getNamedAccounts();
	const Tickets = await deployments.get("Ticket");
	const Random = await deployments.get("GenerateRandom");
	const Compound = await deployments.get("Compound");

	// Upgradeable Proxy
	await deploy(CONTRACT_NAME, {
		from: deployer,
		log: true,
		args: [Tickets.address, UNISWAP, Random.address, Compound.address],
	});
};

module.exports.tags = [CONTRACT_NAME, "lottery"];
module.exports.dependencies = ["Ticket", "GenerateRandom", "Compound"];
