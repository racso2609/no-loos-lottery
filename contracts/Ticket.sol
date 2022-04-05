//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Ticket is ERC1155, AccessControl {
	bytes32 public constant MINTER = keccak256("MINTER");

	constructor() ERC1155("ipfs//:") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC1155, AccessControl)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	/* @params _to person to grant minter role  */
	/* @notice admin user can set minter privileges to another users */

	function setMinter(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_grantRole(MINTER, _to);
	}

	/* @params _to person to grant admin role  */
	/* @notice admin user can set admin privileges to another users */

	function setAdmin(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_grantRole(DEFAULT_ADMIN_ROLE, _to);
	}

	/* @params _tokenId  token identifier (use _lotteryId)  */
	/* @params _amount  amount of tickets to mint  */
	/* @params _to  person who recieve tokens  */
	/* @notice minter users can use lotteryId to create a new collection of tickets and send it to  _to user */

	function mint(
		uint256 _tokenId,
		uint256 _amount,
		address _to
	) external onlyRole(MINTER) returns (bool) {
		_mint(_to, _tokenId, _amount, "");
		return true;
	}
}
