const CONTRACT_NAME = "GenerateRandom";
const vrf = "0x271682DEB8C4E0901D1a1550aD2e64D568E69909";
const link = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const keyHash =
	"0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef";
const fee = ethers.utils.parseEther("0.1");

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
