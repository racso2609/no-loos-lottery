const CONTRACT_NAME = "Lottery";

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy } = deployments;
	const { deployer } = await getNamedAccounts();
	const Tickets = await deployments.get("Ticket");

	// Upgradeable Proxy
	await deploy(CONTRACT_NAME, {
		from: deployer,
		log: true,
		args: [Tickets.address],
	});
};

module.exports.tags = [CONTRACT_NAME, "lottery"];
module.exports.dependencies = ["Ticket"];
