//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract Lottery is AccessControl {
	Ticket public lotteryTickets;
	uint256 public actualLottery;
	uint256 public incompleteLottery;

	IUniswapV2Router02 public uniSwapRouter;

	uint256 constant VOTING_TIME = 2 days;
	uint256 constant INVERSION_TIME = 5 days;
	address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	uint16 constant DEADLINE = 2 minutes;
	uint256 price;

	struct ticketsInterval {
		uint256 minNumber;
		uint256 maxNumber;
		address owner;
	}

	struct Lottery {
		uint256 lotteryId;
		uint256 startTime;
		bool isComplete;
		address winner;
		uint256 ticketWinner;
		mapping(uint32 => ticketsInterval) ticketsOwner;
		uint32 buyId;
		uint256 ticketsNumber;
		uint256 inversionProfit;
		mapping(owner => uint256) balance;
	}

	mapping(uint256 => Lottery) public lotteries;

	constructor(Ticket _lotteryTickets, IUniswapV2Router02 _uniSwapRouter) {
		lotteryTickets = _lotteryTickets;
		uniSwapRouter = _uniSwapRouter;
		price = 1;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
		price = _price;
	}

	function _calculateTokens(uint256 _amountOfDai)
		internal
		view
		returns (uint256)
	{
		return _amountOfDai / price;
	}

	modifier manageLotteryInfo() {
		if (actualLottery == 0 && lotteries[actualLottery].startTime == 0) {
			lotteries[actualLottery].startTime = block.timestamp;
		} else if (
			lotteries[actualLottery].startTime > 0 &&
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

	function _swap(
		uint256 _amount,
		address[] memory path,
		uint256 tokensAmount
	) internal {
		uniSwapRouter.swapExactTokensForTokens(
			_amount,
			tokensAmount,
			path,
			address(this),
			block.timestamp + DEADLINE
		);
	}

	function buyTicketWithToken(IERC20 _token, uint256 _amount)
		external
		manageLotteryInfo
	{
		address[] memory path = new address[](2);
		path[0] = address(_token);
		path[1] = DAI_ADDRESS;

		uint256 amountOfTickets = address(_token) == DAI_ADDRESS
			? _amount
			: _getAmountsOut(path, _amount);

		lotteries[actualLottery].balance[msg.sender] += amountOfTickets;

		amountOfTickets = _calculateTokens(amountOfTickets);

		require(amountOfTickets > 0, "invalid token amount");

		_token.transferFrom(msg.sender, address(this), _amount);

		if (address(_token) != DAI_ADDRESS) {
			_token.approve(address(uniSwapRouter), _amount);
			_swap(_amount, path, amountOfTickets);
		}

		lotteryTickets.mint(actualLottery, amountOfTickets, msg.sender);

		uint32 buyId = lotteries[actualLottery].buyId;

		lotteries[actualLottery].ticketsOwner[buyId].maxNumber = amountOfTickets;
		lotteries[actualLottery].ticketsOwner[buyId].owner = msg.sender;
		// set min number to 1 if its the first person on buy
		lotteries[actualLottery].ticketsOwner[buyId].minNumber =
			lotteries[actualLottery].ticketsNumber +
			1;

		lotteries[actualLottery].ticketsNumber += amountOfTickets;
		lotteries[actualLottery].buyId++;
	}

	function claimWinner() external {
		require(
			lotteries[incompleteLottery].startTime + VOTING_TIME + INVERSION_TIME <
				block.timestamp,
			"Lottery still in progress!"
		);
		if (lotteries[incompleteLottery].buyId == 0) {
			lotteries[incompleteLottery].startTime = block.timestamp;
			revert("No one buy tickets to this lottery restarting lottery!");
		}

		uint256 randomNumber = 1;
		uint32 buyQuantity = lotteries[incompleteLottery].buyId;
		address winner;
		for (uint32 i = 0; i < buyQuantity; i++) {
			if (
				lotteries[incompleteLottery].ticketsOwner[i].minNumber >=
				randomNumber &&
				randomNumber <= lotteries[incompleteLottery].ticketsOwner[i].maxNumber
			) {
				console.log(lotteries[incompleteLottery].ticketsOwner[i].owner);
				winner = lotteries[incompleteLottery].ticketsOwner[i].owner;

				break;
			}
		}
		require(winner != address(0x0), "winner not found!");
		lotteries[incompleteLottery].winner = winner;
		lotteries[incompleteLottery].isComplete = true;
		lotteries[incompleteLottery].ticketWinner = randomNumber;

		// start the next lottery
		incompleteLottery++;
		lotteries[incompleteLottery].startTime = block.timestamp;
	}

	function reclameYouPrime(uint256 _lotteryId) external {}

	function balanceOf(uint256 _lotteryId, uint32 _buyId)
		external
		view
		returns (ticketsInterval memory)
	{
		return lotteries[_lotteryId].ticketsOwner[_buyId];
	}
}
