import pytest
from ape import Contract


@pytest.fixture(scope="session")
def curve_factory():
  yield Contract("0xDC24316b9AE028F1497c275EB9192a3Ea0f67022")

@pytest.fixture(scope="session")
def vitalik(accounts):
    yield accounts["0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B"]

def test_curve_factory(sudo, curve_factory):
    fix = curve_factory
    fix.add_liquidity([10, 0],10, sender=sudo)
