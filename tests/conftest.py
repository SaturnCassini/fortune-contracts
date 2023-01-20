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
def curvePool(sudo, project, ERC20):
    return project.stethpool.deploy(
        sudo, 
        [0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84],
        ERC20,
        50,
        4,
        2,
        sender=sudo)

@pytest.fixture
def f721(sudo, project, mockedNFT, curvePool):
    return project.fortune721.deploy(5, mockedNFT, curvePool, sender=sudo)