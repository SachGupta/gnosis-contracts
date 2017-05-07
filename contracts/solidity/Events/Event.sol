pragma solidity 0.4.11;
import "Tokens/AbstractToken.sol";
import "Tokens/OutcomeToken.sol";
import "Oracles/AbstractOracle.sol";


/// @title Event contract - Provide basic functionality required by different event types.
/// @author Stefan George - <stefan@gnosis.pm>
contract Event {

    /*
     *  Storage
     */
    Token public collateralToken;
    Oracle public oracle;
    bytes32 public oracleEventIdentifier;
    bool public isWinningOutcomeSet;
    int public winningOutcome;
    OutcomeToken[] public outcomeTokens;

    /*
     *  Public functions
     */
    /// @dev Contract constructor validates and sets basic event properties.
    /// @param _collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param _oracle Oracle contract used to resolve the event.
    /// @param _oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    function Event(address _collateralToken, address _oracle, bytes32 _oracleEventIdentifier, uint outcomeCount)
        public
    {
        if (_collateralToken == 0 || _oracle == 0 || outcomeCount < 2)
            // Values are null or outcome count is too low
            throw;
        collateralToken = Token(_collateralToken);
        oracle = Oracle(_oracle);
        oracleEventIdentifier = _oracleEventIdentifier;
        // Create outcome tokens for each outcome
        for (uint8 i=0; i<outcomeCount; i++)
            outcomeTokens.push(new OutcomeToken());
    }

    /// @dev Buys equal number of tokens of all outcomes, exchanging collateral tokens and all outcome tokens 1:1.
    /// @param collateralTokenCount Number of collateral tokens.
    function buyAllOutcomes(uint collateralTokenCount)
        public
    {
        // Transfer tokens to events contract
        if (!collateralToken.transferFrom(msg.sender, this, collateralTokenCount))
            // Transfer failed
            throw;
        // Issue new event tokens to owner.
        for (uint8 i=0; i<outcomeTokens.length; i++)
            outcomeTokens[i].issueTokens(msg.sender, collateralTokenCount);
    }

    /// @dev Sells equal number of tokens of all outcomes, exchanging collateral tokens and all outcome tokens 1:1.
    /// @param outcomeTokenCount Number of outcome tokens.
    function sellAllOutcomes(uint outcomeTokenCount)
        public
    {
        // Revoke tokens of all outcomes
        for (uint8 i=0; i<outcomeTokens.length; i++)
            outcomeTokens[i].revokeTokens(msg.sender, outcomeTokenCount);
        // Transfer redeemed tokens
        if (!collateralToken.transfer(msg.sender, outcomeTokenCount))
            // Transfer failed
            throw;
    }

    /// @dev Sets winning event outcome if resolved by oracle.
    function setWinningOutcome()
        public
    {
        if (isWinningOutcomeSet)
            // Winning outcome is set already
            throw;
        if (!oracle.isOutcomeSet(oracleEventIdentifier))
            // Winning outcome is not set
            throw;
        // Set winning outcome
        winningOutcome = oracle.getOutcome(oracleEventIdentifier);
        isWinningOutcomeSet = true;
    }
}
