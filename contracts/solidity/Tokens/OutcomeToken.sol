pragma solidity 0.4.11;
import "Tokens/StandardTokenWithOverflowProtection.sol";


/// @title Outcome token contract - Issuing and revoking outcome tokens.
/// @author Stefan George - <stefan@gnosis.pm>
contract OutcomeToken is StandardTokenWithOverflowProtection {

    /*
     *  Storage
     */
    address eventContract;

    /*
     *  Modifiers
     */
    modifier isEventContract () {
        if (msg.sender != eventContract)
            // Only event contract is allowed to proceed.
            revert();
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor sets events contract address.
    function OutcomeToken()
        public
    {
        eventContract = msg.sender;
    }
    
    /// @dev Events contract issues new tokens for address. Returns success.
    /// @param _for Address of receiver.
    /// @param outcomeTokenCount Number of tokens to issue.
    function issueTokens(address _for, uint outcomeTokenCount)
        public
        isEventContract
    {
        balances[_for] += outcomeTokenCount;
        totalSupply += outcomeTokenCount;
        Transfer(0, _for, outcomeTokenCount);
    }

    /// @dev Events contract revokes tokens for address. Returns success.
    /// @param _for Address of token holder.
    /// @param outcomeTokenCount Number of tokens to revoke.
    function revokeTokens(address _for, uint outcomeTokenCount)
        public
        isEventContract
    {
        if (outcomeTokenCount > balances[_for])
            // Balance is too low
            revert();
        balances[_for] -= outcomeTokenCount;
        totalSupply -= outcomeTokenCount;
        Transfer(_for, 0, outcomeTokenCount);
    }
}
