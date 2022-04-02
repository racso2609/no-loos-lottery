//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";

contract Lottery {
	Ticket lotteryTickets;
	uint256 actualLottery;

	constructor(Ticket _lotteryTickets) {
		lotteryTickets = _lotteryTickets;
	}
}
