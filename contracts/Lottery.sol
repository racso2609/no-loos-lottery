//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Lottery {
	Ticket lotteryTickets;
	uint256 actualLottery;

	uint256 constant VOTING_TIME = 2 days;
	uint256 constant INVERSION_TIME = 5 days;
	address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	uint16 constant DEADLINE = 2 minutes;

	struct Lottery {
		uint256 lotteryId;
		uint256 startTime;
		bool isComplete;
		address winner;
		uint256 ticketWinner;
	}

	mapping(uint256 => Lottery) lotteries;

	constructor(Ticket _lotteryTickets) {
		lotteryTickets = _lotteryTickets;
	}

	function _getAmountsOut(address[] memory _tokens, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		return uniSwapRouter.getAmountsOut(_amount, _tokens)[1];
	}

	function _swap(address _tokenIn, uint256 _amount) internal {
		address[] memory path = new address[](2);
		path[0] = _tokenId;
		path[1] = DAI_ADDRESS;
		uint256 tokensAmount = _getAmountsOut(path, _amount);

		uniSwapRouter.swapExactTokensForTokens(
			_amount,
			tokensAmount,
			path,
			address(this),
			block.timestamp + DEADLINE
		);
	}

	function buyTicketWithToken(IERC20 _token, uint256 _amount) external {
		//recieve tokens
		_token.transferFrom(msg.sender, _amount, address(this));
		// start lottery if  is not started
		if (
			lotteries[actualLottery].startTime == 0 &&
			(actualLottery == 0 || lotteries[actualLottery - 1].isComplete)
		) {
			lotteries[actualLottery].startTime = block.timestamp;
			//if start time is more than 2 days register on the next lottery
		} else if (
			lotteries[actualLottery].startTime + VOTING_TIME > block.timestamp
		) {
			actualLottery++;
		}

		lotteryTickets.mint(actualLottery, _amount, msg.sender);
	}
}
