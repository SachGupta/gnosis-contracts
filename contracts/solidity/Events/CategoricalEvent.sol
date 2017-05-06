pragma solidity 0.4.11;
import "Events/Event.sol";


contract CategoricalEvent is Event {

    /*
     *  Public functions
     */
    /// @dev Contract constructor validates and sets basic event properties.
    /// @param _collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param _oracle Oracle contract used to resolve the event.
    /// @param _oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    function CategoricalEvent(
        address _collateralToken,
        address _oracle,
        bytes32 _oracleEventIdentifier,
        uint outcomeCount
    )
        public
        Event(_collateralToken, _oracle, _oracleEventIdentifier, outcomeCount)
    {

    }

    /// @dev Exchanges user's winning outcome tokens for collateral tokens.
    function redeemWinnings()
        public
        returns (uint winnings)
    {
        if (!isWinningOutcomeSet)
            // Winning outcome is not set yet
            throw;
        // Calculate winnings
        winnings = outcomeTokens[uint(winningOutcome)].balanceOf(msg.sender);
        // Revoke tokens from winning outcome
        outcomeTokens[uint(winningOutcome)].revokeTokens(msg.sender, winnings);
        // Payout winnings
        if (!collateralToken.transfer(msg.sender, winnings))
            // Transfer failed
            throw;
    }
}
