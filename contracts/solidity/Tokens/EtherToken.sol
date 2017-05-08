pragma solidity ^0.4.0;
import "Tokens/StandardTokenWithOverflowProtection.sol";


/// @title Token contract - Token exchanging Ether 1:1.
/// @author Stefan George - <stefan@gnosis.pm>
contract EtherToken is StandardTokenWithOverflowProtection {

    /*
     *  Constants
     */
    string public constant name = "Ether Token";
    string public constant symbol = "ETH";
    uint8 public constant decimals = 18;

    /*
     *  Public functions
     */
    /// @dev Buys tokens with Ether, exchanging them 1:1.
    function deposit()
        public
        payable
    {
        if (   !safeToAdd(balances[msg.sender], msg.value)
            || !safeToAdd(totalSupply, msg.value))
            // Overflow operation
            throw;
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    /// @dev Sells tokens in exchange for Ether, exchanging them 1:1.
    /// @param amount Number of tokens to sell.
    function withdraw(uint amount)
        public
    {
        if (   !safeToSubtract(balances[msg.sender], amount)
            || !safeToSubtract(totalSupply, amount))
            // Overflow operation
            throw;
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        msg.sender.transfer(amount);
    }
}
