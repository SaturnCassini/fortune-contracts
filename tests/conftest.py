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
def f721(sudo, project, mockedNFT):
    return project.fortune721.deploy(5, mockedNFT, sender=sudo)