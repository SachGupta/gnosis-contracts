pragma solidity 0.4.4;
import "DO/AbstractDutchAuction.sol";


contract ClaimProxy {

    /*
     *  External contracts
     */
    DutchAuction public dutchAuction;

    /*
     *  Public functions
     */
    /// @dev Contract constructor function dutch auction contract address.
    function ClaimProxy(address _dutchAuction)
        public
    {
        dutchAuction = DutchAuction(_dutchAuction);
    }

    function claimTokensFor(address[] receivers)
        public
    {
        for (uint i=0; i<receivers.length; i++) {
            dutchAuction.claimTokens(receivers[i]);
        }
    }
}
