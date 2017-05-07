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
        bytes32 replacement;
    }

    /*
     *  Public functions
     */
    /// @dev Replaces oracle/signing private key for an oracle.
    /// @param descriptionHash Hash identifying off chain event description.
    /// @param oracle New oracle.
    function replaceOracle(bytes32 descriptionHash, address oracle)
        public
    {
        bytes32 _eventIdentifier = keccak256(msg.sender, descriptionHash);
        if (results[_eventIdentifier].isSet)
            // Result was set already
            throw;
        bytes32 newEventIdentifier = keccak256(oracle, descriptionHash);
        results[_eventIdentifier].replacement = newEventIdentifier;
    }

    /// @dev Sets outcome based on signed message.
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
        results[eventIdentifier].isSet = true;
        results[eventIdentifier].outcome = outcome;
    }

    /// @dev Returns final event identifier after all recursive replacements are done.
    /// @param eventIdentifier Event identifier.
    /// @return Returns final event identifier.
    function getEventIdentifier(bytes32 eventIdentifier)
        public
        constant
        returns (bytes32)
    {
        if (results[eventIdentifier].replacement != 0)
            return getEventIdentifier(eventIdentifier);
        return eventIdentifier;
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @param eventIdentifier Event identifier.
    /// @return Returns if outcome is set.
    function isOutcomeSet(bytes32 eventIdentifier)
        public
        constant
        returns (bool)
    {
        eventIdentifier = getEventIdentifier(eventIdentifier);
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
        eventIdentifier = getEventIdentifier(eventIdentifier);
        return results[eventIdentifier].outcome;
    }
}
