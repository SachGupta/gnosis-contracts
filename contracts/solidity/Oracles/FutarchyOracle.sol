pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";
import "Events/EventFactory.sol";
import "Markets/AbstractMarketFactory.sol";


/// @title Futarchy oracle contract - Allows to create an oracle based on market behaviour.
/// @author Stefan George - <stefan@gnosis.pm>
contract FutarchyOracle is Oracle {

    /*
     *  Storage
     */
    Market[] public markets;
    uint public deadline;
    int public outcome;
    bool public isSet;

    /*
     *  Public functions
     */
    /// @dev Constructor creates events and markets for futarchy oracle.
    /// @param eventFactory Event factory contract.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param outcomeCount Number of event outcomes.
    /// @param lowerBound Lower bound for event outcome.
    /// @param upperBound Lower bound for event outcome.
    /// @param marketFactory Market factory contract.
    /// @param marketMaker Market maker contract.
    /// @param fee Market fee.
    /// @param funding Initial funding for market.
    /// @param _deadline Decision deadline.
    function FutarchyOracle(
        EventFactory eventFactory,
        Token collateralToken,
        Oracle oracle,
        uint8 outcomeCount,
        int lowerBound,
        int upperBound,
        MarketFactory marketFactory,
        MarketMaker marketMaker,
        uint fee,
        uint funding,
        uint _deadline
    )
        public
    {
        if (_deadline > now)
            // Deadline has passed already
            revert();
        // Create decision event
        CategoricalEvent categoricalEvent = eventFactory.createCategoricalEvent(collateralToken, this, outcomeCount);
        // Create outcome events
        for (uint8 i=0; i<categoricalEvent.getOutcomeCount(); i++) {
            ScalarEvent scalarEvent = eventFactory.createScalarEvent(
                categoricalEvent.outcomeTokens(i),
                oracle,
                lowerBound,
                upperBound
            );
            markets.push(marketFactory.createMarket(scalarEvent, marketMaker, fee, funding));
        }
        deadline = _deadline;
    }

    /// @dev Returns the amount of outcome tokens held by market.
    /// @return Outcome token distribution.
    function getOutcomeTokenDistribution(Market market)
        public
        returns (uint[] outcomeTokenDistribution)
    {
        outcomeTokenDistribution = new uint[](2);
        for (uint i=0; i<outcomeTokenDistribution.length; i++)
            outcomeTokenDistribution[i] = market.eventContract().outcomeTokens(i).balanceOf(market);
    }

    /// @dev Allows to set the oracle outcome based on the market with largest long position.
    function setOutcome()
        public
    {
        if (isSet || deadline > now)
            // Outcome was set already or deadline is not over yet
            revert();
        uint[] memory outcomeTokenDistribution = getOutcomeTokenDistribution(markets[0]);
        uint highest = outcomeTokenDistribution[0] - outcomeTokenDistribution[1];
        int highestIndex = 0;
        for (uint8 i=1; i<markets.length; i++) {
            outcomeTokenDistribution = getOutcomeTokenDistribution(markets[i]);
            if ((outcomeTokenDistribution[0] - outcomeTokenDistribution[1]) > highest)
                highestIndex = i;
        }
        outcome = highestIndex;
        isSet = true;
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @return Returns if outcome is set.
    function isOutcomeSet()
        public
        constant
        returns (bool)
    {
        return isSet;
    }

    /// @dev Returns winning outcome for given event.
    /// @return Returns outcome.
    function getOutcome()
        public
        constant
        returns (int)
    {
        return outcome;
    }
}
