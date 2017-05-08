pragma solidity 0.4.11;
import "Oracles/UltimateOracle.sol";


/// @title Ultimate oracle factory contract - Allows to create ultimate oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract UltimateOracleFactory {

    /*
     *  Storage
     */
    mapping (bytes32 => UltimateOracle) public ultimateOracles;

    /*
     *  Public functions
     */
    /// @dev Creates a new Ultimate Oracle contract.
    /// @param oracle Oracle address.
    /// @param eventIdentifier Event identifier.
    /// @param collateralToken Collateral token address.
    /// @param challengePeriod Time to challenge oracle outcome.
    /// @param challengeAmount Amount to challenge the outcome.
    /// @param frontRunnerPeriod Time to overbid the front-runner.
    /// @return Returns oracle contract.
    function createUltimateOracle(
        address oracle,
        bytes32 eventIdentifier,
        address collateralToken,
        uint challengePeriod,
        uint challengeAmount,
        uint frontRunnerPeriod
    )
        public
        returns (UltimateOracle ultimateOracle)
    {
        bytes32 ultimateOracleHash = keccak256(oracle, eventIdentifier, collateralToken, challengePeriod, challengeAmount, frontRunnerPeriod);
        if (address(ultimateOracles[ultimateOracleHash]) != 0)
            // Ultimate oracle exists already
            throw;
        ultimateOracle = new UltimateOracle(
            oracle,
            eventIdentifier,
            collateralToken,
            challengePeriod,
            challengeAmount,
            frontRunnerPeriod
        );
        ultimateOracles[ultimateOracleHash] = ultimateOracle;
        return ultimateOracle;
    }
}
