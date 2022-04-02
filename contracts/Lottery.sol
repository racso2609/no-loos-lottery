//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
	Ticket lotteryTickets;
	uint256 actualLottery;

	constructor(Ticket _lotteryTickets) {
		lotteryTickets = _lotteryTickets;
	}

	function buyTicketWithToken(IERC20 _token, uint256 _amount) external {
		_token.transferFrom(msg.sender, _amount, address(this));
	}
}
