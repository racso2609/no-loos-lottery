const CONTRACT_NAME = "GenerateRandom";
const vrf = "0xf0d54349aDdcf704F77AE15b96510dEA15cb7952";
const link = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const keyHash =
	"0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445";
const fee = ethers.utils.parseEther("10");

// modify when needed
module.exports = async ({ getNamedAccounts, deployments }) => {
	const { deploy } = deployments;
	const { deployer } = await getNamedAccounts();

	// Upgradeable Proxy
	await deploy(CONTRACT_NAME, {
		from: deployer,
		log: true,
		args: [vrf, link, keyHash, fee],
	});
};

module.exports.tags = [CONTRACT_NAME, "lottery"];
