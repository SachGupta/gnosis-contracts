pragma solidity 0.4.11;
import "Markets/DefaultMarket.sol";


/// @title Market factory contract - Allows to create market contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract MarketFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => Market) public markets;

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
        bytes32 marketHash = keccak256(eventContract, marketMaker, msg.sender);
        if (address(markets[marketHash]) != 0)
            // Market does exist already
            revert();
        market = new DefaultMarket(eventContract, marketMaker, fee, funding);
        markets[marketHash] = market;
        return market;
    }
}
