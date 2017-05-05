from ethjsonrpc import EthJsonRpc
from ethereum.abi import ContractTranslator
from ethereum.transactions import Transaction
from ethereum.utils import privtoaddr
from ethereum import _solidity
import click
import time
import json
import rlp
import logging
import os


# create logger
logger = logging.getLogger('ABI')
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


class EthABI:

    def __init__(self, f, contract_dir, abi_dir):
        self.solidity = _solidity.solc_wrapper()
        self.f = f
        self.contract_dir = contract_dir
        self.abi_dir = abi_dir

    @staticmethod
    def log(string):
        logger.info(string)

    def compile_code(self, code=None, path=None):
        # create list of valid paths
        absolute_path = self.contract_dir if self.contract_dir.startswith('/') else '{}/{}'.format(os.getcwd(),
                                                                                                   self.contract_dir)
        sub_dirs = [x[0] for x in os.walk(absolute_path)]
        extra_args = ' '.join(['{}={}'.format(d.split('/')[-1], d) for d in sub_dirs])
        # compile code
        combined = self.solidity.combined(code, path=path, extra_args=extra_args)
        abi = combined[-1][1]['abi']
        return abi

    def save_abi(self, file_path, abi):
        file_name = file_path.split("/")[-1].split(".")[0]
        with open('{}/{}.json'.format(self.abi_dir, file_name), 'w+') as abi_file:
            abi_file.write(json.dumps(abi))
            abi_file.close()
        logger.info('{} ABI generated.'.format(file_name))

    def process(self):
        if self.f:
            abi = self.compile_code(None, path=self.f)
            if abi:
                self.save_abi(self.f, abi)
        else:
            for root, directories, files in os.walk(self.contract_dir):
                for filename in files:
                    if filename.endswith('.sol'):
                        file_path = os.path.join(root, filename)
                        abi = self.compile_code(None, path=file_path)
                        if abi:
                            self.save_abi(file_path, abi)


@click.command()
@click.option('--f', help='Path to contract')
@click.option('--contract-dir', default="solidity", help='Path to contract directory')
@click.option('--abi-dir', default="abi", help='Path to contract directory')
def setup(f, contract_dir, abi_dir):
    eth_abi = EthABI(f, contract_dir, abi_dir)
    eth_abi.process()

if __name__ == '__main__':
    setup()
