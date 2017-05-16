pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";


/// @title Centralized oracle contract - Allows the contract owner to set an outcome.
/// @author Stefan George - <stefan@gnosis.pm>
contract CentralizedOracle is Oracle {

    /*
     *  Storage
     */
    address public oracle;
    bytes32 public descriptionHash;
    bool public isSet;
    int public outcome;

    /*
     *  Modifiers
     */
    modifier isOracle () {
        if (msg.sender != oracle)
            // Only oracle contract is allowed to proceed.
            revert();
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor sets oracle address and description hash.
    /// @param _descriptionHash Hash identifying off chain event description.
    function CentralizedOracle(address _oracle, bytes32 _descriptionHash)
        public
    {
        if (_descriptionHash == 0)
            // Description hash is null
            revert();
        oracle = _oracle;
        descriptionHash = _descriptionHash;
    }

    /// @dev Replaces oracle.
    /// @param _oracle New oracle.
    function replaceOracle(address _oracle)
        public
        isOracle
    {
        if (isSet)
            // Result was set already
            revert();
        oracle = _oracle;
    }

    /// @dev Sets event outcome.
    /// @param _outcome Event outcome.
    function setOutcome(int _outcome)
        public
        isOracle
    {
        if (isSet)
            // Result was set already
            revert();
        isSet = true;
        outcome = _outcome;
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
