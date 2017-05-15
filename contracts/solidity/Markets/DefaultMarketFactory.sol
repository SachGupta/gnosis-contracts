pragma solidity 0.4.11;
import "Markets/AbstractMarketFactory.sol";
import "Markets/DefaultMarket.sol";


/// @title Market factory contract - Allows to create market contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract DefaultMarketFactory is MarketFactory {

    /*
     *  Public functions
     */
    /// @dev Creates a new market contract.
    /// @param eventContract Event contract.
    /// @param marketMaker Market maker contract.
    /// @param fee Market fee.
    /// @param funding Initial funding for market.
    /// @return Returns market contract.
    function createMarket(Event eventContract, MarketMaker marketMaker, uint fee, uint funding)
        public
        returns (Market market)
    {
        market = new DefaultMarket(eventContract, marketMaker, fee, funding);
        MarketCreation(msg.sender, market, eventContract, marketMaker, fee, funding);
    }
}
