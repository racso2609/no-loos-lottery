//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./compound.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GenerateRandom.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery is AccessControl {
	using SafeMath for uint256;
	Ticket public lotteryTickets;
	uint256 public actualLottery;
	uint256 public incompleteLottery;

	IUniswapV2Router02 public uniSwapRouter;
	IGenerateRandom randomGenerator;
	Compound compound;

	event ClaimPrize(address owner, uint256 prize, bool isWinner);
	event ClaimWinner(address winner);
	event BuyTicket(address owner, uint256 ticketAmount);

	uint256 constant VOTING_TIME = 2 days;
	uint256 constant INVERSION_TIME = 5 days;
	address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	uint16 constant DEADLINE = 2 minutes;

	uint256 constant PRICE = 1;

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
		uint256 claimedTickets;
		mapping(address => uint256) balance;
		mapping(address => bool) isClaimed;
	}

	mapping(uint256 => Lottery) public lotteries;
	modifier endBuyTime(uint256 _lotteryId) {
		require(
			lotteries[_lotteryId].startTime + VOTING_TIME < block.timestamp,
			"This sell is on voting time!"
		);
		_;
	}
	modifier endInvestementTime(uint256 _lotteryId) {
		require(
			lotteries[_lotteryId].startTime + VOTING_TIME + INVERSION_TIME <
				block.timestamp,
			"This sell is on voting time!"
		);
		_;
	}
	modifier isFinishedLottery(uint256 _lotteryId) {
		require(lotteries[_lotteryId].isComplete);

		_;
	}

	constructor(
		Ticket _lotteryTickets,
		IUniswapV2Router02 _uniSwapRouter,
		IGenerateRandom _randomNumber,
		Compound _compound
	) {
		lotteryTickets = _lotteryTickets;
		uniSwapRouter = _uniSwapRouter;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		randomGenerator = _randomNumber;
		compound = _compound;
	}

	function _calculateTokens(uint256 _amountOfDai)
		internal
		view
		returns (uint256)
	{
		return _amountOfDai / PRICE;
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
		emit BuyTicket(msg.sender, amountOfTickets);
	}

	function claimWinner()
		external
		endBuyTime(incompleteLottery)
		endInvestementTime(incompleteLottery)
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		if (lotteries[incompleteLottery].buyId == 0) {
			lotteries[incompleteLottery].startTime = block.timestamp;
			revert("No one buy tickets to this lottery restarting lottery!");
		}

		uint256 randomNumber = 1;
		/* console.log("generating"); */
		/* randomGenerator.getRandomness(); */

		/* console.log("generated"); */
		/* uint256 randomNumber = randomGenerator.rollDice( */
		/* lotteries[incompleteLottery].ticketsNumber */
		/* ); */
		/* console.log(randomNumber); */

		uint32 buyQuantity = lotteries[incompleteLottery].buyId;
		address winner;
		for (uint32 i = 0; i < buyQuantity; i++) {
			if (
				lotteries[incompleteLottery].ticketsOwner[i].minNumber >=
				randomNumber &&
				randomNumber <= lotteries[incompleteLottery].ticketsOwner[i].maxNumber
			) {
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
		emit ClaimWinner(winner);
	}

	function calculatePrice(uint256 _ticketAmount) public view returns (uint256) {
		return _ticketAmount * PRICE;
	}

	function invest()
		external
		endBuyTime(incompleteLottery)
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		require(
			!lotteries[incompleteLottery].isComplete,
			"this lottery is already completed!"
		);

		uint256 investedBalance = calculatePrice(
			lotteries[incompleteLottery].ticketsNumber
		);

		IERC20(DAI_ADDRESS).approve(address(compound), investedBalance);
		compound.supply(investedBalance);

		return investedBalance;
	}

	function reclameYouPrime(uint256 _lotteryId)
		external
		endBuyTime(incompleteLottery)
		endInvestementTime(incompleteLottery)
		isFinishedLottery(incompleteLottery)
	{
		require(
			!lotteries[_lotteryId].isClaimed[msg.sender],
			"you already reclaim your prize!"
		);

		uint256 userTickets = lotteries[_lotteryId].balance[msg.sender];
		bool isWinner = msg.sender == lotteries[_lotteryId].winner;
		uint256 prize;
		if (isWinner) {
			prize = calculatePrice( //no refundable amount
				lotteries[_lotteryId].ticketsNumber.sub(
					lotteries[_lotteryId].claimedTickets.add(userTickets)
				)
			);
			uint256 DaiContractBalance = IERC20(DAI_ADDRESS).balanceOf(address(this));
			prize = DaiContractBalance.sub(prize);
		} else {
			prize = calculatePrice(userTickets);
		}

		IERC20(DAI_ADDRESS).transfer(msg.sender, prize);
		lotteries[_lotteryId].isClaimed[msg.sender] = true;
		lotteries[_lotteryId].claimedTickets += userTickets;
		emit ClaimPrize(msg.sender, prize, isWinner);
	}

	function balanceOf(uint256 _lotteryId, uint32 _buyId)
		external
		view
		returns (ticketsInterval memory)
	{
		return lotteries[_lotteryId].ticketsOwner[_buyId];
	}
}
