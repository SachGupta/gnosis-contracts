pragma solidity 0.4.4;
import "Tokens/AbstractToken.sol";


contract Vesting {

    /*
     *  Storage
     */
    address public owner;
    address public wallet;
    uint public vestingPeriod;
    uint public startDate;
    uint public withdrawnTokens;

    /*
     *  Modifiers
     */
    modifier isOwner() {
        if (msg.sender != owner)
            // Only owner is allowed to proceed
            throw;
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet)
            // Only wallet is allowed to proceed
            throw;
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor function sets contract owner and wallet address, which is allowed to withdraw all tokens anytime.
    /// @param _owner Vesting contract owner.
    /// @param _wallet Gnosis multisig wallet address.
    /// @param _vestingPeriod Vesting period in seconds.
    /// @param _startDate Start date of vesting period (cliff).
    function Vesting(address _owner, address _wallet, uint _vestingPeriod, uint _startDate)
        public
    {
        owner = _owner;
        wallet = _wallet;
        vestingPeriod = _vestingPeriod;
        startDate = _startDate;
        if (startDate == 0)
            startDate = now;
    }

    /// @dev Transfers tokens to a given address.
    /// @param token Token address.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function withdraw(address token, address _to, uint256 _value)
        public
        isOwner
    {
        uint maxTokens = calcMaxWithdraw(token);
        if (_value > maxTokens)
            throw;
        withdrawnTokens += _value;
        Token(token).transfer(_to, _value);
    }

    /// @dev Transfers all tokens to multisig wallet.
    /// @param token Token address.
    function walletWithdraw(address token)
        public
        isWallet
    {
        uint balance = Token(token).balanceOf(this);
        withdrawnTokens += balance;
        Token(token).transfer(wallet, balance);
    }

    /// @dev Calculates the maximum amount of vested tokens.
    function calcMaxWithdraw(address token)
        public
        constant
        returns (uint)
    {
        uint maxTokens = (Token(token).balanceOf(this) + withdrawnTokens) * (now - startDate) / vestingPeriod;
        if (withdrawnTokens >= maxTokens || startDate > now)
            return 0;
        return maxTokens - withdrawnTokens;
    }
}
