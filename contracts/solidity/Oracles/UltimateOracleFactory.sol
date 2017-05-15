pragma solidity 0.4.11;
import "Oracles/UltimateOracle.sol";


/// @title Ultimate oracle factory contract - Allows to create ultimate oracle contracts.
/// @author Stefan George - <stefan@gnosis.pm>
contract UltimateOracleFactory {

    /*
     *  Events
     */
    event UltimateOracleCreation(address indexed creator, UltimateOracle ultimateOracle, Oracle oracle, Token collateralToken, uint challengePeriod, uint challengeAmount, uint frontRunnerPeriod);

    /*
     *  Public functions
     */
    /// @dev Creates a new Ultimate Oracle contract.
    /// @param oracle Oracle address.
    /// @param collateralToken Collateral token address.
    /// @param challengePeriod Time to challenge oracle outcome.
    /// @param challengeAmount Amount to challenge the outcome.
    /// @param frontRunnerPeriod Time to overbid the front-runner.
    /// @return Returns oracle contract.
    function createUltimateOracle(
        Oracle oracle,
        Token collateralToken,
        uint challengePeriod,
        uint challengeAmount,
        uint frontRunnerPeriod
    )
        public
        returns (UltimateOracle ultimateOracle)
    {
        ultimateOracle = new UltimateOracle(
            oracle,
            collateralToken,
            challengePeriod,
            challengeAmount,
            frontRunnerPeriod
        );
        UltimateOracleCreation(msg.sender, ultimateOracle, oracle, collateralToken, challengePeriod, challengeAmount, frontRunnerPeriod);
    }
}
