pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/Compound.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "hardhat/console.sol";

contract Compound is AccessControl {
	using SafeMath for uint256;
	using SafeMath for uint16;
	IERC20 public token;
	CErc20 public cToken;
	uint16 public decimals;
	uint16 public cDecimals;

	constructor(
		address _token,
		address _cToken,
		uint16 _decimals,
		uint16 _cDecimals
	) {
		token = IERC20(_token);
		cToken = CErc20(_cToken);
		decimals = _decimals;
		cDecimals = _cDecimals;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/* @params _to person to grant admin role  */
	/* @notice admin user can set admin privileges to another users */

	function setAdmin(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_grantRole(DEFAULT_ADMIN_ROLE, _to);
	}

	/* @params _amount amount of tokens to supplt compound  */
	/* @notice supply compound with tokens */

	function supply(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
		token.transferFrom(msg.sender, address(this), _amount);
		token.approve(address(cToken), _amount);
		require(cToken.mint(_amount) == 0, "mint fail!");
	}

	/* @notice get cToken amount */

	function getCTokenBalance()
		public
		view
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		return cToken.balanceOf(address(this));
	}

	/* @notice info related to the pool */
	function getInfo()
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256 exchangeRate, uint256 supplyRate)
	{
		exchangeRate = cToken.exchangeRateCurrent();
		supplyRate = cToken.supplyRatePerBlock();
	}

	/* @notice info related to the pool */
	function estimateBalanceOfUnderlying()
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		uint256 cTokenBal = getCTokenBalance();
		uint256 exchangeRate = cToken.exchangeRateCurrent();
		console.log(cTokenBal, exchangeRate);

		return cTokenBal.sub(exchangeRate).div(10**(18 + decimals.sub(cDecimals)));
	}

	function balanceOfUnderlying()
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		return cToken.balanceOfUnderlying(address(this));
	}

	function redeem(uint256 _cTokenAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(cToken.redeem(10) == 0, "redeem fail");
	}
}
