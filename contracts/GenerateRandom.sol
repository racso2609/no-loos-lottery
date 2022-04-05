pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorMock.sol";

interface IGenerateRandom {
	function getRandomness() external returns (bytes32);

	function rollDice(uint256 _maxNumber) external view returns (uint256);
}

contract Mock is VRFCoordinatorMock {
	constructor(address _link) VRFCoordinatorMock(_link) {}
}

contract GenerateRandom is VRFConsumerBase, Initializable {
	bytes32 internal keyHash;
	uint256 internal fee;
	uint256 public randomNumber;
	bytes32 public requestId;
	Mock coordinatorMock;

	constructor(
		address _vrfCoordinator,
		address _link,
		bytes32 _keyHash,
		uint256 _fee
	) VRFConsumerBase(_vrfCoordinator, _link) {
		keyHash = _keyHash;
		fee = _fee;
		coordinatorMock = new Mock(_link);
	}

	function getRandomness() public returns (bytes32) {
		require(
			LINK.balanceOf(address(this)) >= fee,
			"Inadequate Link to fund this transaction"
		);
		requestId = requestRandomness(keyHash, fee);
		return requestId;
	}

	function fulfillRandomness(bytes32, uint256 randomness) internal override {
		randomNumber = randomness;
	}

	function rollDice(uint256 _maxNumber) public returns (uint256) {
		require(randomNumber >= 0, "Random number has not yet been obtained");
		coordinatorMock.callBackWithRandomness(requestId, 777, address(this));

		return (randomNumber % _maxNumber) + 1;
	}
}
