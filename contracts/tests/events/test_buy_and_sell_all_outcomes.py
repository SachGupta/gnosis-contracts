from ..abstract_test import AbstractTestContract, accounts


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.events.test_buy_and_sell_all_outcomes
    """

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)
        self.math = self.create_contract('Utils/Math.sol')
        self.event_factory = self.create_contract('Events/EventFactory.sol', libraries={'Math': self.math})
        self.centralized_oracle_factory = self.create_contract('Oracles/CentralizedOracleFactory.sol')
        self.ether_token = self.create_contract('Tokens/EtherToken.sol', libraries={'Math': self.math})
        self.event_abi = self.create_abi('Events/AbstractEvent.sol')
        self.token_abi = self.create_abi('Tokens/AbstractToken.sol')

    def test(self):
        # Create event
        description_hash = "1"
        oracle = self.centralized_oracle_factory.createCentralizedOracle(description_hash)
        event = self.event_factory.createCategoricalEvent(self.ether_token.address, oracle, 2)
        # Buy all outcomes
        buyer = 0
        collateral_token_count = 10
        self.ether_token.deposit(value=collateral_token_count)
        self.assertEqual(self.ether_token.balanceOf(accounts[buyer]), collateral_token_count)
        self.ether_token.approve(event, collateral_token_count)
        self.send(event, self.event_abi, 'buyAllOutcomes', [collateral_token_count])
        self.assertEqual(self.ether_token.balanceOf(event), collateral_token_count)
        self.assertEqual(self.ether_token.balanceOf(accounts[buyer]), 0)
        outcome_token_1 = self.send(event, self.event_abi, 'outcomeTokens', [0])
        outcome_token_2 = self.send(event, self.event_abi, 'outcomeTokens', [1])
        self.assertEqual(self.send(outcome_token_1, self.token_abi, 'balanceOf', [accounts[buyer]]),
                         collateral_token_count)
        self.assertEqual(self.send(outcome_token_2, self.token_abi, 'balanceOf', [accounts[buyer]]),
                         collateral_token_count)
        # Sell all outcomes
        self.send(event, self.event_abi, 'sellAllOutcomes', [collateral_token_count])
        self.assertEqual(self.ether_token.balanceOf(accounts[buyer]), collateral_token_count)
        self.assertEqual(self.ether_token.balanceOf(event), 0)
        self.assertEqual(self.send(outcome_token_1, self.token_abi, 'balanceOf', [accounts[buyer]]), 0)
        self.assertEqual(self.send(outcome_token_2, self.token_abi, 'balanceOf', [accounts[buyer]]), 0)
