//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

contract Lottery {
	Ticket public lotteryTickets;
	uint256 public actualLottery;

	IUniswapV2Router02 public uniSwapRouter;

	uint256 constant VOTING_TIME = 2 days;
	uint256 constant INVERSION_TIME = 5 days;
	address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	uint16 constant DEADLINE = 2 minutes;

	struct ticketsInterval {
		uint256 minNumber;
		uint256 maxNumber;
	}

	struct Lottery {
		uint256 lotteryId;
		uint256 startTime;
		bool isComplete;
		address winner;
		uint256 ticketWinner;
		mapping(address => mapping(uint256 => ticketsInterval)) ticketsOwner;
		mapping(address => uint256) buyTimes;
		uint256 ticketsNumber;
	}

	mapping(uint256 => Lottery) public lotteries;

	constructor(Ticket _lotteryTickets, IUniswapV2Router02 _uniSwapRouter) {
		lotteryTickets = _lotteryTickets;
		uniSwapRouter = _uniSwapRouter;
	}

	modifier manageLotteryInfo() {
		// start lottery if  is not started
		if (
			lotteries[actualLottery].startTime == 0 &&
			(actualLottery == 0 || lotteries[actualLottery - 1].isComplete)
		) {
			lotteries[actualLottery].startTime = block.timestamp;
			//if start time is more than 2 days register on the next lottery
		} else if (
			lotteries[actualLottery].startTime + VOTING_TIME < block.timestamp
		) {
			actualLottery++;
			lotteries[actualLottery].lotteryId = actualLottery;
		}

		_;
	}

	function _getAmountsOut(address[] memory _tokens, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		return uniSwapRouter.getAmountsOut(_amount, _tokens)[1];
	}

	function _swap(address _tokenIn, uint256 _amount) internal returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = _tokenIn;
		path[1] = DAI_ADDRESS;
		uint256 tokensAmount = _getAmountsOut(path, _amount);

		uniSwapRouter.swapExactTokensForTokens(
			_amount,
			tokensAmount,
			path,
			address(this),
			block.timestamp + DEADLINE
		);

		return tokensAmount;
	}

	function buyTicketWithToken(IERC20 _token, uint256 _amount)
		external
		manageLotteryInfo
	{
		//recieve tokens
		_token.transferFrom(msg.sender, address(this), _amount);

		uint256 amountOfTickets = _amount;

		if (address(_token) != DAI_ADDRESS) {
			_token.approve(address(uniSwapRouter), _amount);
			amountOfTickets = _swap(address(_token), _amount);
		}

		lotteryTickets.mint(actualLottery, amountOfTickets, msg.sender);
		lotteries[actualLottery].buyTimes[msg.sender]++;
		uint256 actualTimeBuyOfUser = lotteries[actualLottery].buyTimes[msg.sender];

		lotteries[actualLottery]
		.ticketsOwner[msg.sender][actualTimeBuyOfUser].maxNumber = amountOfTickets;
		// set min number to 1 if its the first person on buy
		lotteries[actualLottery]
		.ticketsOwner[msg.sender][actualTimeBuyOfUser].minNumber =
			lotteries[actualLottery].ticketsNumber +
			1;

		lotteries[actualLottery].ticketsNumber += amountOfTickets;
	}

	function balanceOf(
		address _to,
		uint256 _lotteryId,
		uint256 _timeBuy
	) external view returns (ticketsInterval memory) {
		return lotteries[_lotteryId].ticketsOwner[_to][_timeBuy];
	}

	function sendFunds() external payable {}
}
