pragma solidity 0.4.4;
import "Tokens/AbstractToken.sol";


contract Vesting {

    /*
     *  Constants
     */
    uint constant public vestingPeriod = 4 years;

    /*
     *  Storage
     */
    address public owner;
    address public wallet;
    Token public gnosisToken;
    uint public startDate;
    uint public withdrawnTokens;

    /*
     *  Modifiers
     */
    modifier isOwner() {
        if (msg.sender != owner) {
            // Only owner is allowed to proceed
            throw;
        }
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet) {
            // Only wallet is allowed to proceed
            throw;
        }
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor function sets contract owner, Gnosis token and wallet address, which is allowed to withdraw all tokens anytime.
    /// @param _gnosisToken Vesting contract owner.
    /// @param _wallet Gnosis multisig wallet address.
    /// @param _gnosisToken Gnosis token address.
    function Vesting(address _owner, address _wallet, address _gnosisToken)
        public
    {
        owner = _owner;
        wallet = _wallet;
        gnosisToken = Token(_gnosisToken);
        startDate = now;
    }

    /// @dev Transfers tokens to a given address.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function withdraw(address _to, uint256 _value)
        public
        isOwner
    {
        uint maxTokens = calcMaxWithdraw();
        if (_value > maxTokens)
            throw;
        withdrawnTokens += _value;
        gnosisToken.transfer(_to, _value);
    }

    /// @dev Transfers all tokens to multisig wallet.
    function walletWithdraw()
        public
        isWallet
    {
        uint balance = gnosisToken.balanceOf(this);
        withdrawnTokens += balance;
        gnosisToken.transfer(wallet, balance);
    }

    /// @dev Calculates the maximum amount of vested tokens.
    function calcMaxWithdraw()
        public
        returns (uint)
    {
        uint maxTokens = (gnosisToken.balanceOf(this) + withdrawnTokens) * (now - startDate) / vestingPeriod;
        if (withdrawnTokens >= maxTokens) {
            return 0;
        }
        return maxTokens - withdrawnTokens;
    }
}
