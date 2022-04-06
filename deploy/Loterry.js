const CONTRACT_NAME = "Lottery";
const { UNISWAP } = require("../utils/tokens");

const { getToken } = require("../utils/tokens");

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy } = deployments;
	const { deployer } = await getNamedAccounts();
	const Tickets = await deployments.get("Ticket");
	const Random = await deployments.get("GenerateRandom");
	const DAI_TOKEN = getToken("DAI");
	const CDAI_TOKEN = getToken("CDAI");

	// Upgradeable Proxy
	await deploy(CONTRACT_NAME, {
		from: deployer,
		log: true,
		proxy: {
			execute: {
				init: {
					methodName: "initialize",
					args: [
						Tickets.address,
						UNISWAP,
						Random.address,
						DAI_TOKEN.address,
						CDAI_TOKEN.address,
						DAI_TOKEN.decimals,
						CDAI_TOKEN.decimals,
					],
				},
			},
		},
	});
};

module.exports.tags = [CONTRACT_NAME, "lottery"];
module.exports.dependencies = ["Ticket", "GenerateRandom", "Compound"];
