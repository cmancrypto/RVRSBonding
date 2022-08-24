// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; 

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol'; 

contract RVRSBond is Ownable
{
    using SafeERC20 for IERC20; 

    //variables
    IERC20 public tokenIn; 
    IERC20 public tokenOut;
    //treasury receives tokenIn 
    address public treasury; 
    //exchange Rate = (tokenOut/tokenIn)*10^12 - padded with precision to allow non-integer exchange rates
    uint256 public exchangeRate; 
    uint256 public precision = 10e12; 

    /**
    *Event for logging bonding 
    *@param bonder who bonded assets 
    *@param amtIn how many tokenIn bonded 
    *@param amtOut how many tokenOut back
     */
    event Bonded(address indexed bonder, uint256 amtIn, uint256 amtOut);

    /**
    * @param _tokenInAddr address of token to receive
    * @param _tokenOutAddr address of token to distribute
    * @param _treasury address of beneficiary for tokenIn
    * @param _exchangeRate (tokenOut/tokenIn)*10^12
     */
    constructor(
        address _tokenInAddr, 
        address _tokenOutAddr,
        address _treasury, 
        uint256 _exchangeRate
    ) public {
        tokenIn = IERC20(_tokenInAddr); 
        tokenOut= IERC20(_tokenOutAddr);
        treasury=_treasury;
        exchangeRate= _exchangeRate;
    }    
    /* @dev Bond, takes in tokenIn, calculates amtOwed, ensures contract has balance, sends tokenOut to msg.sender
    * @param _amtIn is number of tokenIn to bond
    */
    function bond(uint256 _amtIn) external 
    {
        require (_amtIn > 0, 'need _amtIn to be >0');
        tokenIn.safeTransferFrom(address(msg.sender),treasury,_amtIn);
        //calculate how much is owed 
        uint256 _amtOwed = _amtIn*exchangeRate/precision;
        //check balance in contract will cover
        require (_amtOwed < tokenOut.balanceOf(address(this)),'insufficient tokenOut in contract');
        //send from contract balance to msg.sender
        tokenOut.safeTransfer(address(msg.sender),_amtOwed);
        emit Bonded(
            msg.sender,
            _amtIn,
            _amtOwed
            );
    }   

    /** 
    *@dev Set new exchange rate 
    * @param _exchangeRate = (tokenOut/tokenIn)*10^12
    */
    function setExchangeRate (uint256 _exchangeRate) public onlyOwner 
    {
        require (_exchangeRate>0,'needs to be nonzero'); 
        exchangeRate = _exchangeRate;
    }
    /** 
    * @dev Set new treasury addr
    * @param _treasury is the new recipient of tokenIn
    */
    function setTreasury (address _treasury) public onlyOwner 
    {
        treasury = _treasury;
    }
    /**
    *@dev Generalised recover token - checks balance of this contract with token and then sends amount requested
    * @param _tokenAddr address of the token to be recovered 
    * @param _recoverAmt amount to be recovered 
    */
    function recoverToken (address _tokenAddr, uint256 _recoverAmt) public onlyOwner 
    {
       uint256 _tokenBalance = IERC20(_tokenAddr).balanceOf(address(this)); 
       require (_recoverAmt < _tokenBalance,'recoveramt>balance');
       IERC20(_tokenAddr).safeTransfer(address(msg.sender),_recoverAmt);
    }
}

