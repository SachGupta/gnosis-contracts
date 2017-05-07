from ..abstract_test import AbstractTestContract, accounts, keys, TransactionFailed


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.events.test_create_events
    """

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)

    def test(self):
        # self.event_factory = self.create_contract('Events/EventFactory.sol')
        # self.difficulty_oracle = self.create_contract('Oracles/DifficultyOracle.sol')
        # self.difficulty_oracle = self.create_contract('Oracles/OffChainOracle.sol')
        # self.difficulty_oracle = self.create_contract('Oracles/MajorityOracle.sol')
        self.difficulty_oracle = self.create_contract('Oracles/UltimateOracleFactory.sol')
        # self.difficulty_oracle = self.create_contract('Tokens/EtherToken.sol')
