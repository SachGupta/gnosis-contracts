# contracts package
from contracts import ROOT_DIR
# ethereum pacakge
from ethereum import tester as t
from ethereum.tester import keys, accounts, TransactionFailed
# standard libraries
from unittest import TestCase
from os import walk


class AbstractTestContract(TestCase):
    """
    run all tests with python -m unittest discover contracts.tests
    """

    HOMESTEAD_BLOCK = 1150000
    CONTRACT_DIR = 'solidity'

    def __init__(self, *args, **kwargs):
        super(AbstractTestContract, self).__init__(*args, **kwargs)
        self.s = t.state()
        self.s.block.number = self.HOMESTEAD_BLOCK
        t.gas_limit = 4712388

    def create_contract(self, path, params=()):
        abs_contract_path = '{}/{}'.format(ROOT_DIR, self.CONTRACT_DIR)
        sub_dirs = [x[0] for x in walk(abs_contract_path)]
        extra_args = ' '.join(['{}={}'.format(d.split('/')[-1], d) for d in sub_dirs])
        path = '{}/{}'.format(abs_contract_path, path)
        return self.s.abi_contract(None,
                                   path=path,
                                   constructor_parameters=params,
                                   language='solidity',
                                   extra_args=extra_args)
