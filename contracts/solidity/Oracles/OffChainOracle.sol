pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";


/// @title Off-chain oracle contract - Allows to set an outcome with a signed message.
/// @author Stefan George - <stefan.george@consensys.net>
contract OffChainOracle is Oracle {

    /*
     *  Storage
     */
    mapping (bytes32 => Result) public results;

    struct Result {
        bool isSet;
        int outcome;
    }

    /*
     *  Public functions
     */
    /// @dev Sets difficulty as winning outcome for a specific block.
    /// @param descriptionHash Hash identifying off chain event description.
    /// @param outcome Signed event outcome.
    /// @param v Signature parameter.
    /// @param r Signature parameter.
    /// @param s Signature parameter.
    function setOutcome(bytes32 descriptionHash, int outcome, uint8 v, bytes32 r, bytes32 s)
        public
    {
        address oracle = ecrecover(keccak256(descriptionHash, outcome), v, r, s);
        bytes32 eventIdentifier = keccak256(oracle, descriptionHash);
        if (results[eventIdentifier].isSet)
            // Result was set already
            throw;
        results[eventIdentifier] = Result({
            isSet: true,
            outcome: outcome
        });
        EventResolution(eventIdentifier, outcome);
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @param eventIdentifier Event identifier.
    function isOutcomeSet(bytes32 eventIdentifier)
        public
        constant
        returns (bool)
    {
        return results[eventIdentifier].isSet;
    }

    /// @dev Returns winning outcome for given event.
    /// @param eventIdentifier Event identifier.
    /// @return Returns outcome.
    function getOutcome(bytes32 eventIdentifier)
        public
        constant
        returns (int)
    {
        return results[eventIdentifier].outcome;
    }
}
