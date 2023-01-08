# @version ^0.3.7

"""
@title Bare-bones Token implementation of the Fortune cards
@author: @0xcassini.eth
@notice This is a bare-bones implementation of the Fortune cards
        It is not meant to be used in production, but rather as a
        starting point for the final implementation
@notice Owners of the Legends NFT can mint an unrevealed Fortune
        card as an ERC20 to any address.
@notice Based on the ERC-20 token standard as defined at
        https://eips.ethereum.org/EIPS/eip-20
"""

from vyper.interfaces import ERC20

implements: ERC20

interface LegendsContract:
    def balanceOf(_owner: address) -> uint256: view

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event MintFortune:
    receiver: indexed(address)
    value: uint256

event BurnFortune:
    legend: indexed(address)
    value: String[4]

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)
legendsContract: LegendsContract

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]
lastMinted: HashMap[address, uint256]
fortuneContract: public(address)

owner: public(address)

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _total_supply: uint256, legendsAddress: address):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balances[msg.sender] = _total_supply
    self.totalSupply = _total_supply
    self.legendsContract = LegendsContract(legendsAddress)
    self.owner = msg.sender
    log Transfer(empty(address), msg.sender, _total_supply)
    

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Getter to check the current balance of an address
    @param _owner Address to query the balance of
    @return Token balance
    """
    return self.balances[_owner]


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param _owner The address which owns the funds
    @param _spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[_owner][_spender]

@nonpayable
@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    @return Success boolean
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    """
    @dev Internal shared logic for transfer and transferFrom
    """
    assert self.balances[_from] >= _value, "Insufficient balance"
    self.balances[_from] -= _value
    self.balances[_to] += _value
    log Transfer(_from, _to, _value)

@nonpayable
@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _to The address to transfer to
    @param _value The amount to be transferred
    @return Success boolean
    """
    self._transfer(msg.sender, _to, _value)
    return True

@nonpayable
@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value The amount of tokens to be transferred
    @return Success boolean
    """
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient allowance"
    self.allowances[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True

@external
def mintFortune(to: address) -> bool:
    """
    @notice Mint a fortune to an specified address which holds the nft
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can mint
    @param to: who receives the fortune
    @return True if the caller addres is a legend
    """
    if self.legendsContract.balanceOf(msg.sender) > 0: # if the caller is a legend
        if self.lastMinted[msg.sender] + 3600*24 > block.timestamp: # if 24 hours passed since last mint
            raise "You can only mint once a day"
        self.totalSupply += 1
        self.balances[msg.sender] += 1
        self.lastMinted[msg.sender] = block.timestamp
        log MintFortune(msg.sender, 1)
        return True
    else:
        raise "Not a Legend"

@external
def burnFortune() -> bool:
    """
    @notice Burn a fortune from an specified address
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can burn
    @param _legend The address to burn from
    @return Success boolean
    """
    assert self.balances[msg.sender] >= 1, "You dont have a fortune to burn"
    if self.legendsContract.balanceOf(msg.sender) > 0: # if the caller is a legend
        self.totalSupply -= 1
        self.balances[msg.sender] -= 1
        if (block.prevrandao + block.timestamp) % 2 == 0:
            log BurnFortune(msg.sender, 'GOOD')
            return True
        else:
            log BurnFortune(msg.sender, 'BAD')
            return False

    else:
        raise "Not a Legend"

@view
@external
def getLegendBalance() -> uint256:
    """
    @notice Getter to check the current balance of an address
    @dev this is not yet tested and should be used with caution
    """
    legends: LegendsContract = self.legendsContract
    return legends.balanceOf(msg.sender)

@view
@external
def getFortuneChestBalance() -> uint256:
    """
    @notice Getter to check the current ETH balance of the fortune chest
    @dev this is not yet tested and should be used with caution
    @return ETH balance
    """
    return self.balance

@external
def currentOwner() -> address:
    """
    @notice Getter to check the current owner of the fortune chest
    @dev this is not yet tested and should be used with caution    
    """
    return self.owner 

@external
def setOwner(new_owner:address) -> bool:
    """
    @notice Setter to set the owner of the fortune chest
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can burn
    @param _legend The address to burn from
    @return Success boolean
    """
    if self.owner == msg.sender:
        self.owner = new_owner
        return True
    else:
        raise "Not a Legend"