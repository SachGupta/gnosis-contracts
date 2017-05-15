pragma solidity 0.4.11;
import "Oracles/FutarchyOracle.sol";


/// @title Futarchy oracle factory contract - Allows to create Futarchy oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract FutarchyOracleFactory {

    /*
     *  Events
     */
    event FutarchyOracleCreation(
        address indexed creator,
        FutarchyOracle futarchyOracle,
        Token collateralToken,
        Oracle oracle,
        uint8 outcomeCount,
        int lowerBound,
        int upperBound,
        MarketFactory marketFactory,
        MarketMaker marketMaker,
        uint fee,
        uint funding,
        uint deadline
    );

    /*
     *  Storage
     */
    EventFactory eventFactory;

    /*
     *  Public functions
     */
    /// @dev Constructor sets event factory contract.
    /// @param _eventFactory Event factory contract.
    function FutarchyOracleFactory(EventFactory _eventFactory)
        public
    {
        if (address(_eventFactory) == 0)
            // Address is null
            revert();
        eventFactory = _eventFactory;
    }

    /// @dev Creates a new Futarchy oracle contract.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param outcomeCount Number of event outcomes.
    /// @param lowerBound Lower bound for event outcome.
    /// @param upperBound Lower bound for event outcome.
    /// @param marketFactory Market factory contract.
    /// @param marketMaker Market maker contract.
    /// @param fee Market fee.
    /// @param funding Initial funding for market.
    /// @param deadline Decision deadline.
    /// @return Returns oracle contract.
    function createFutarchyOracle(
        Token collateralToken,
        Oracle oracle,
        uint8 outcomeCount,
        int lowerBound,
        int upperBound,
        MarketFactory marketFactory,
        MarketMaker marketMaker,
        uint fee,
        uint funding,
        uint deadline
    )
        public
        returns (FutarchyOracle futarchyOracle)
    {
        futarchyOracle = new FutarchyOracle(
            eventFactory,
            collateralToken,
            oracle,
            outcomeCount,
            lowerBound,
            upperBound,
            marketFactory,
            marketMaker,
            fee,
            funding,
            deadline
        );
        FutarchyOracleCreation(
            msg.sender,
            futarchyOracle,
            collateralToken,
            oracle,
            outcomeCount,
            lowerBound,
            upperBound,
            marketFactory,
            marketMaker,
            fee,
            funding,
            deadline
        );
    }
}
