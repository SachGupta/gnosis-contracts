from ethereum import _solidity
import json
import os
import logging


logger = logging.getLogger('ABI GENERATION')
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)


solidity = _solidity.solc_wrapper()
contracts = ['DutchAuction/DutchAuction.sol',
             'Tokens/GnosisToken.sol',
             'DutchAuction/ClaimProxy.sol',
             'DutchAuction/Disbursement.sol',
             'DutchAuction/BiddingRing.sol']
contract_dir = 'solidity'


def compile_code(path):
    # create list of valid paths
    deploy_path = '{}/{}'.format(os.path.dirname(os.path.realpath(__file__)), contract_dir)
    sub_dirs = [x[0] for x in os.walk(deploy_path)]
    extra_args = ' '.join(['{}={}'.format(d.split('/')[-1], d) for d in sub_dirs])
    # compile code
    path = '{}/{}'.format(contract_dir, path)
    combined = solidity.combined(None, path=path, extra_args=extra_args)
    _bytecode = combined[-1][1]['bin_hex']
    _abi = combined[-1][1]['abi']
    return _bytecode, _abi


for contract_path in contracts:
    bytecode, abi = compile_code(contract_path)
    # save abi
    file_name = contract_path.split("/")[-1].split(".")[0]
    with open('abi/{}.json'.format(file_name), 'w+') as abi_file:
        abi_file.write(json.dumps(abi))
        abi_file.close()
    logger.info('{} ABI generated.'.format(file_name))
