from ..abstract_test import AbstractTestContract, accounts, keys, TransactionFailed


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.events.test_create_events
    """

    BLOCKS_PER_DAY = 5760
    TOTAL_TOKENS = 10000000 * 10**18
    MAX_TOKENS_SOLD = 9000000
    PREASSIGNED_TOKENS = 1000000 * 10**18
    WAITING_PERIOD = 60*60*24*7
    FUNDING_GOAL = 250000 * 10**18
    PRICE_FACTOR = 4000
    MAX_GAS = 150000  # Kraken gas limit

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)

    def test(self):
        self.event_factory = self.create_contract('Events/EventFactory.sol')
