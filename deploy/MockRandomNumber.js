const CONTRACT_NAME = "Mock";
const link = "0x514910771AF9Ca656af840dff83E8264EcF986CA";

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy } = deployments;
	const { deployer } = await getNamedAccounts();

	// Upgradeable Proxy
	await deploy(CONTRACT_NAME, {
		from: deployer,
		log: true,
		args: [link],
	});
};

module.exports.tags = [CONTRACT_NAME, "lottery"];
