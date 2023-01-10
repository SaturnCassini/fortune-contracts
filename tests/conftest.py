import pytest


@pytest.fixture
def sudo(accounts):
    return accounts[-1]


@pytest.fixture
def mockedNFT(sudo, project):
    return project.nft_mocked_contract.deploy("Mocked NFT", "MCKD", 0, sender=sudo)


@pytest.fixture
def fortune(sudo, project, mockedNFT):
    return project.fortune.deploy("Saturn Fortunes", "FORTUNE",0, mockedNFT,sender=sudo)