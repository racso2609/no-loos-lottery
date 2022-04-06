pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/Compound.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Compound is Initializable, AccessControlUpgradeable {
	using SafeMath for uint256;
	using SafeMath for uint16;
	IERC20 public token;
	CErc20 public cToken;
	uint16 public decimals;
	uint16 public cDecimals;

	function __initializeCompound__(
		address _token,
		address _cToken,
		uint16 _decimals,
		uint16 _cDecimals
	) public initializer {
		__AccessControl_init();
		token = IERC20(_token);
		cToken = CErc20(_cToken);
		decimals = _decimals;
		cDecimals = _cDecimals;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/* @params _to person to grant admin role  */
	/* @notice admin user can set admin privileges to another users */

	function setAdmin(address _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_grantRole(DEFAULT_ADMIN_ROLE, _to);
	}

	/* @params _amount amount of tokens to supplt compound  */
	/* @notice supply compound with tokens */

	function supply(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
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
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256 exchangeRate, uint256 supplyRate)
	{
		exchangeRate = cToken.exchangeRateCurrent();
		supplyRate = cToken.supplyRatePerBlock();
	}

	/* @notice info related to the pool */
	function estimateBalanceOfUnderlying()
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		uint256 cTokenBal = getCTokenBalance();
		uint256 exchangeRate = cToken.exchangeRateCurrent();

		return cTokenBal.sub(exchangeRate).div(10**(18 + decimals.sub(cDecimals)));
	}

	function balanceOfUnderlying()
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
		returns (uint256)
	{
		return cToken.balanceOfUnderlying(address(this));
	}

	function redeem(uint256 _tokenAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(cToken.redeem(_tokenAmount) == 0, "redeem fail");
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}
}
