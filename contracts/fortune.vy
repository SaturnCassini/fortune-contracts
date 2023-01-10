# @version ^0.3.7

"""
@title Bare-bones Token implementation of the Fortune cards
@notice This is a bare-bones implementation of the Fortune cards
        It is not meant to be used in production, but rather as a
        starting point for the final implementation
        
        Owners of the Legends NFT can mint an unrevealed Fortune
        card as an ERC20 to any address, and pay an upfront tribute.

        The Fortune cards can be burned to generate an event of GOOD or BAD
        fortune. The event is a string of 4 characters, which can be used
        by the frontend to display a message, and for the game to build upon it later.
    
        The Fortune cards can be traded, but only the owner of the NFT can mint
        a new Fortune card.

        When the FORTUNE card is burnt, the burner can get back their initial tribute minus a fee.

        There is a withdraw function that can only be called by the owner of the contract.
        This is to allow the owner to withdraw the ETH tributes.

@author 0xcassini.eth
"""


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

# The Fortune card is an ERC20 token that is tied to the value of the tribute it was minted with
struct FortuneCard:
    cardNumber: uint256
    tributeAmount: uint256
    dateMinted: uint256
    randomness: uint256

name: public(String[64])
symbol: public(String[32])
circulatingSupply: public(uint256)
legendsContract: LegendsContract

# The mapping of the Fortune cards
# The key is the address of the minter of the token
# The value is the Fortune card's msg.value
fortunesLog: HashMap[address, FortuneCard]

# Used to keep track of the number of Fortune cards minted
mintCount: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]
lastMinted: HashMap[address, uint256]

fortuneContract: public(address)
tributeBalance: public(uint256)
tributeLostAndUnclaimed: public(uint256)
tributeFee: public(uint256)

owner: public(address)

@external
def __init__(_name: String[64], _symbol: String[32], _initial_supply: uint256, legendsAddress: address, tributeFee: uint256):
    self.name = _name
    self.symbol = _symbol
    self.balances[msg.sender] = _initial_supply
    self.circulatingSupply = _initial_supply
    self.legendsContract = LegendsContract(legendsAddress)
    self.owner = msg.sender
    self.tributeFee = tributeFee
    log Transfer(empty(address), msg.sender, _initial_supply)
    

@view
@external
def fortuneBalance(_owner: address) -> uint256:
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
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value The amount of tokens to be transferred
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

@payable
@external
def mintFortune(to: address) -> bool:
    """
    @notice Mint a fortune to an specified address which holds the nft
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can mint
    @param to who receives the fortune
    @return True if the caller addres is a legend
    """
    # Make sure the minter doesnt have a fortune already
    assert self.balances[msg.sender] == 0, "You already have a fortune card minted"
    if self.legendsContract.balanceOf(msg.sender) > 0: # if the caller is a legend
        if self.lastMinted[msg.sender] + 3600*24 > block.timestamp: # if 24 hours passed since last mint
            raise "You can only mint once a day"
        self.circulatingSupply += 1
        self.balances[msg.sender] += 1
        self.lastMinted[msg.sender] = block.timestamp
        self.tributeBalance += msg.value
        self.fortunesLog[msg.sender] = FortuneCard({
            cardNumber: self.mintCount,
            tributeAmount: msg.value,
            dateMinted: block.timestamp,
            randomness: block.prevrandao,
            }
        )
        self.mintCount += 1
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
    @return Success boolean
    """
    currentFortune: FortuneCard = self.fortunesLog[msg.sender]
    assert self.balances[msg.sender] >= 1, "You dont have a fortune to burn"
    # Make sure there has passed at least 60 seconds since mint
    assert block.timestamp > currentFortune.dateMinted + 300 , "Wait at least 5 minutes to burn your fortune"
    self.circulatingSupply -= 1
    self.balances[msg.sender] -= 1

    if ((self.balance + block.prevrandao + currentFortune.dateMinted + currentFortune.randomness + currentFortune.cardNumber) % 23) % 2 == 0:
        reward: uint256 = currentFortune.tributeAmount - ( currentFortune.tributeAmount * self.tributeFee / 100)
        self.tributeBalance -= reward
        send(msg.sender, reward)
        log BurnFortune(msg.sender, 'GOOD')
        return True
    else:
        reward: uint256 = currentFortune.tributeAmount - ( currentFortune.tributeAmount * (self.tributeFee) / 100)
        self.tributeBalance -= reward
        send(msg.sender, reward)
        log BurnFortune(msg.sender, 'BAD')
        return False

@view
@external
def currentCardIdFrom(legend:address)-> uint256:
    """
    @notice Getter to check the current cardNumber of an address
    @dev this is not yet tested and should be used with caution
    """
    return self.fortunesLog[legend].cardNumber

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

# Admin functions

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
    @param new_owner The address that will be the new owner of the contract
    @return Success boolean
    """
    assert self.owner == msg.sender
    if self.owner == msg.sender:
        self.owner = new_owner
        return True
    else:
        raise "Not the owner"

@view
@external
def getUnclaimedLostTribute()-> uint256:
    """
    @notice Getter to check the current ETH balance of the fortune chest that has been lost and unclaimed
    @dev this is not yet tested and should be used with caution
    @return ETH balance
    """
    return self.tributeLostAndUnclaimed

@external
def withdrawLostTributes() -> bool:
    """
    @notice Withdraw the ETH from the fortune chest
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can burn
    @return Success boolean
    """
    assert self.owner == msg.sender
    assert self.balance > 0
    if self.owner == msg.sender:
        send(self.owner, self.balance)
        self.tributeBalance = 0
        self.tributeLostAndUnclaimed = 0
        return True
    else:
        raise "Not the contract Owner"


@external
def setTributeFee(percentage: uint256)-> bool:
    """
    @notice Setter to set the tribute fee
    @dev this is not yet tested and should be used with caution
    @dev You could add an assert here to make sure the owner of the nft is the one who can burn
    @param percentage The percentage of the tribute that will be taken
    @return Success boolean
    """
    assert self.owner == msg.sender
    if self.owner == msg.sender:
        self.tributeFee = percentage
        return True
    else:
        raise "Not the contract Owner"

@view
@external
def getTributeFee()-> uint256:
    """
    @notice Getter to check the current tribute fee
    @dev this is not yet tested and should be used with caution
    @return tribute fee
    """
    return self.tributeFee