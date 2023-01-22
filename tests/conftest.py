import pytest
import ape


@pytest.fixture
def sudo(accounts):
    return accounts[-1]

@pytest.fixture
def dev(accounts):
    return accounts[1]

@pytest.fixture
def contracts():    
    return ape.contracts.base.ContractEvent

@pytest.fixture
def mockedNFT(sudo, project):
    return project.nft_mocked_contract.deploy("Mocked NFT", "MCKD", 0,sender=sudo)


@pytest.fixture
def fortune(sudo, project, mockedNFT):
    return project.fortune.deploy("OLD Fortunes", "OLD",0, mockedNFT, 5,sender=sudo)

@pytest.fixture
def ERC20(sudo, project):
    return project.ERC20.deploy("Staked Eth", "stETH", 8, sender=sudo)

@pytest.fixture
def curvePool():
    return '0xC3DC5292caF0C3350c1Be8E5f8c36E10A6B12a6b'

@pytest.fixture
def f721(sudo, project, mockedNFT, curvePool):
    return project.fortune721.deploy(5, mockedNFT, curvePool, sender=sudo)


@pytest.fixture
def curveContract(Contract):
    return Contract("0xDC24316b9AE028F1497c275EB9192a3Ea0f67022")