//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Ticket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./compound.sol";

import "./GenerateRandom.sol";

/* import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; */

contract Lottery is Compound {
	using SafeMath for uint256;
	Ticket public lotteryTickets;
	uint256 public actualLottery;
	uint256 public incompleteLottery;

	IUniswapV2Router02 public uniSwapRouter;
	IGenerateRandom randomGenerator;

	event ClaimReward(address owner, bool isWinner);
	event ClaimWinner(address winner);
	event BuyTicket(address owner, uint256 ticketAmount);

	uint256 constant BUY_TIME = 2 days;
	uint256 constant INVERSION_TIME = 5 days;
	address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	uint16 constant DEADLINE = 2 minutes;

	uint256 constant PRICE = 1 * 10**18;

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
		uint32 buyId;
		uint256 ticketsNumber;
		uint256 claimedTickets;
		// to allow iterate and buy tickets more than one tiket by people
		// i use a uint to track each ticket interval
		mapping(uint32 => ticketsInterval) ticketsOwner;
		// amount od tickets buy by the user
		mapping(address => uint256) balance;
		// check if user claim their reward
		mapping(address => bool) isClaimed;
	}

	mapping(uint256 => Lottery) public lotteries;
	/* @params _lotteryId lottery identifier  */
	/* @notice check if buy time is already completed  */

	modifier endBuyTime(uint256 _lotteryId) {
		require(
			block.timestamp >= lotteries[_lotteryId].startTime + BUY_TIME,
			"This sell is on buy time!"
		);
		_;
	}
	/* @params _lotteryId lottery identifier  */
	/* @notice check if investment time is already completed  */

	modifier endInvestementTime(uint256 _lotteryId) {
		require(
			block.timestamp >=
				lotteries[_lotteryId].startTime + BUY_TIME + INVERSION_TIME,
			"This sell is on investment time!"
		);
		_;
	}
	/* @params _lotteryId lottery identifier  */
	/* @notice check if lottery is already completed  */

	modifier isFinishedLottery(uint256 _lotteryId) {
		require(lotteries[_lotteryId].isComplete, "lottery is not completed!");
		_;
	}

	/* @notice middleware to check if the buyTime of one lottery is finished and register de buyer on the next lottery  */
	modifier manageLotteryInfo() {
		if (actualLottery == 0 && lotteries[actualLottery].startTime == 0) {
			lotteries[actualLottery].startTime = block.timestamp;
		} else if (
			lotteries[actualLottery].startTime > 0 &&
			lotteries[actualLottery].startTime + BUY_TIME < block.timestamp
		) {
			actualLottery++;
			lotteries[actualLottery].lotteryId = actualLottery;
		}

		_;
	}

	function initialize(
		Ticket _lotteryTickets,
		IUniswapV2Router02 _uniSwapRouter,
		IGenerateRandom _randomNumber,
		address _token,
		address _cToken,
		uint16 _decimals,
		uint16 _cDecimals
	) external initializer {
		__initializeCompound__(_token, _cToken, _decimals, _cDecimals);
		lotteryTickets = _lotteryTickets;
		uniSwapRouter = _uniSwapRouter;
		randomGenerator = _randomNumber;
	}

	/* @params _daiAmount dai received from the user  */
	/* @notice return the amount of tokens related to _amountDai  */

	function _calculateTokens(uint256 _daiAmount)
		internal
		view
		returns (uint256)
	{
		return _daiAmount / PRICE;
	}

	/* @params _tokens uniswap path  */
	/* @params _amount amount of tokens in  */
	/* @notice return the tokensOutamount obtained by swap  */
	function _getAmountsOut(address[] memory _tokens, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		return uniSwapRouter.getAmountsOut(_amount, _tokens)[1];
	}

	/* @params _amount min tokens out amount  */
	/* @params _path uniswap path  */
	/* @params _tokensamount quinity of tokens in  */
	/* @notice make swap of tokens   */

	function _swap(
		uint256 _amount,
		address[] memory _path,
		uint256 _tokensAmount
	) internal {
		uniSwapRouter.swapExactTokensForTokens(
			_amount,
			_tokensAmount,
			_path,
			address(this),
			block.timestamp + DEADLINE
		);
	}

	function getRandomNumber() external {
		randomGenerator.getRandomness();
	}

	/* @params _token tokenIn  */
	/* @params _amount quantity of tokens sent  */
	/* @notice buy tickets, and swap the tokenIn for dai   */

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

		amountOfTickets = _calculateTokens(amountOfTickets);
		require(amountOfTickets > 0, "invalid token amount");

		lotteries[actualLottery].balance[msg.sender] += amountOfTickets;
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

	/* @notice claim winner from a complete loterry  */

	function claimWinner()
		external
		endBuyTime(incompleteLottery)
		endInvestementTime(incompleteLottery)
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		uint256 randomNumber = randomGenerator.rollDice(
			lotteries[incompleteLottery].ticketsNumber
		);

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

		uint256 amountToWithdraw = getCTokenBalance();
		redeem(amountToWithdraw);

		lotteries[incompleteLottery].isComplete = true;
		lotteries[incompleteLottery].ticketWinner = randomNumber;

		// start the next lottery
		incompleteLottery++;
		lotteries[incompleteLottery].startTime = block.timestamp;
		emit ClaimWinner(winner);
	}

	/* @params _ticketAmount quantity of ticket  */
	/* @notice calculate the price of an amount of tickets (price is on DAI)   */
	function calculatePrice(uint256 _ticketAmount) public pure returns (uint256) {
		return _ticketAmount * PRICE;
	}

	/* @notice supply compound with dai to get incommings */
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
		if (lotteries[incompleteLottery].buyId == 0) {
			lotteries[incompleteLottery].startTime = block.timestamp;
			revert("No one buy tickets to this lottery restarting lottery!");
		}

		uint256 investedBalance = calculatePrice(
			lotteries[incompleteLottery].ticketsNumber
		);

		IERC20(DAI_ADDRESS).approve(address(this), investedBalance);
		supply(investedBalance);

		return investedBalance;
	}

	/* @params _lotteryId lottery identifier */
	/* @notice reclame your reward */
	function reclameReward(uint256 _lotteryId)
		external
		endBuyTime(_lotteryId)
		endInvestementTime(_lotteryId)
		isFinishedLottery(_lotteryId)
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
		lotteries[_lotteryId].claimedTickets += calculatePrice(userTickets);
		emit ClaimReward(msg.sender, isWinner);
	}

	/* @params _lotteryId lottery identifier */
	/* @params _buyId buy reference */
	/* @notice return the interval of tickets on exact lottery and time */
	function ticketsOf(uint256 _lotteryId, uint32 _buyId)
		external
		view
		returns (ticketsInterval memory)
	{
		return lotteries[_lotteryId].ticketsOwner[_buyId];
	}

	/* @params _lotteryId lottery identifier */
	/* @params _buyId buy reference */
	/* @notice return the interval of tickets on exact lottery and time */
	function balanceOf(uint256 _lotteryId) external view returns (uint256) {
		return lotteries[_lotteryId].balance[msg.sender];
	}
}
