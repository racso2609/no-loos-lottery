//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorMock.sol";
import "hardhat/console.sol";

interface IGenerateRandom {
	function getRandomness() external returns (bytes32);

	function rollDice(uint256 _maxNumber) external view returns (uint256);
}

contract Mock is VRFCoordinatorMock {
	constructor(address _link) VRFCoordinatorMock(_link) {}
}

contract GenerateRandom is VRFConsumerBase {
	bytes32 internal keyHash;
	uint256 internal fee;
	uint256 public randomNumber;
	bytes32 public requestId;
	address vrfCoordinator;

	constructor(
		address _vrfCoordinator,
		address _link,
		bytes32 _keyHash,
		uint256 _fee
	) VRFConsumerBase(_vrfCoordinator, _link) {
		keyHash = _keyHash;
		fee = _fee;
		vrfCoordinator = _vrfCoordinator;
	}

	function getRandomness() public returns (bytes32) {
		require(
			LINK.balanceOf(address(this)) >= fee,
			"Inadequate Link to fund this transaction"
		);
		requestId = requestRandomness(keyHash, fee);
		VRFCoordinatorMock(vrfCoordinator).callBackWithRandomness(
			requestId,
			777,
			address(this)
		);
		return requestId;
	}

	function fulfillRandomness(bytes32, uint256 randomness)
		internal
		virtual
		override
	{
		randomNumber = randomness;
	}

	function rollDice(uint256 _maxNumber) public view returns (uint256) {
		return (randomNumber % _maxNumber) + 1;
	}
}
