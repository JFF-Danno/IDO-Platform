//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.1;

import "./PoolToken.sol";

contract IDO {
   
  constructor() {
    adminAddress = msg.sender;
  }
    
  PoolToken public projectTokenInstance;
  PoolToken public mainTokenInstance;

  uint256 public poolCounter;

  mapping(address => bool) public managerWhiteList;
  mapping(uint256 => address[]) public whiteList;
  mapping(uint256 => mapping(address => uint256)) public amountList;
  mapping(uint256 => address) public accessManager;
  mapping(uint256 => uint256) public tokensSold;
  mapping(uint256 => uint256) public tokenPrice;
  address public adminAddress;

    event NewPool(
        uint256 indexed poolId,
        uint256 hardCap,
        uint256 softCap,
        uint256 startDate,
        uint256 endDate,
        address mainToken,
        address projectToken,
        uint256 minAllocationPerUser
    );

    event PoolFunded(
        uint256 indexed poolId,
        uint256 amount,
        address token
    );

    event NewInvestment(
        uint256 indexed poolId,
        uint256 amount,
        address token
    );

    event FundsRetrieved(
        uint256 indexed poolId,
        uint256 amount,
        address token
    );

    event TokensClaimed(
        uint256 indexed poolId,
        uint256 amount,
        address token
    );
  
    modifier onlyAdmin() {
        require(adminAddress == msg.sender, '!admin');
        _;
    }

    modifier onlyPoolManager()  {
        require( managerWhiteList[msg.sender], '!poolmanager');
        _;
    }
    
    modifier onlyPoolOwner(uint256 idPool)  {
        require( poolExists(idPool), '!poolexists' );
        require( accessManager[idPool] == msg.sender, '!poolowner');
        _;
    }

    modifier onlyInvestors(uint256 idPool)  {
        require( poolExists(idPool), '!poolexists' );
        bool isInvestor = false;
        for( uint i = 0; i < whiteList[idPool].length; i++ ){
            
            if ( whiteList[idPool][i] == msg.sender ){
                isInvestor = true;
                break;
            }
        }
        require( isInvestor, '!investor');
        _;
    }

    modifier onlyExists(uint256 idPool) {
        require(poolExists(idPool), '!poolexists');
        _;
    }

    function poolExists(uint256 idPool) public view returns(bool) {
        return ( poolData[idPool].created ? true : false );
    }
  
  mapping(uint256 => PoolData) public poolData;

  struct PoolData {
        uint256 hardCap;
        uint256 softCap;
        uint256 startDate;
        uint256 endDate;
        address mainToken;
        address projectToken;
        uint256 minAllocationPerUser;
        uint256 exchangeRate;
        string  status;
        uint256 totalInvested;
        uint256 totalProjectTokens;
        bool    created;
  }

    function addManager(address _accessManagerContract) external onlyAdmin() {
        managerWhiteList[_accessManagerContract] = true;
    }

    function delistManager(address _accessManagerContract) external onlyAdmin() {
        managerWhiteList[_accessManagerContract] = false;
    }

  function initiatePool(
        uint256 hardCap,
        uint256 softCap,
        uint256 startDate,
        uint256 endDate,
        address mainToken,
        address projectToken,
        uint256 minAllocationPerUser,
        address _accessManagerContract,
        uint256 exchangeRate,
        uint256 _tokenPrice
       ) external onlyPoolManager() returns (uint) {
        
        require( managerWhiteList[_accessManagerContract] == true, "Manager not whitelisted");
        require( msg.sender == _accessManagerContract, "Only Access Managers can initiate a pool"); 
        
        require(
            endDate > block.timestamp,
            "auction end date must be in the future"
        );
        
        uint poolId = poolCounter++;
   
        poolData[poolCounter] = PoolData(
            hardCap,
            softCap,
            startDate,
            endDate,
            mainToken,
            projectToken,
            minAllocationPerUser,
            exchangeRate,
            "",
            0,
            0,

            true
        );

        emit NewPool(
            poolCounter,
            hardCap,
            softCap,
            startDate,
            endDate,
            mainToken,
            projectToken,
            minAllocationPerUser
        );
        tokenPrice[poolCounter] = _tokenPrice;
        accessManager[poolCounter] = _accessManagerContract;
        return poolId;
    }

    function getPoolId ()
        public view returns(uint256) {
            return poolCounter; 
    }

    function setHardCap(uint256 poolId,uint256 _hardCap) external onlyPoolOwner(poolId) {
        poolData[poolId].hardCap = _hardCap; 
    }

    function getHardCap(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        require(poolExists(poolId), '!poolexists');       

        return poolData[poolId].hardCap; 
    }

    function setSoftCap(uint256 poolId,uint256 _softCap) external onlyPoolOwner(poolId) {
        poolData[poolId].softCap = _softCap; 
    }

    function getSoftCap(uint256 poolId) public view onlyExists(poolId) returns(uint256) {

        return poolData[poolId].softCap; 
    }

    function setStartDate(uint256 poolId,uint256 _startDate) external onlyPoolOwner(poolId) {
        poolData[poolId].startDate = _startDate; 
    }

    function getStartDate(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return poolData[poolId].startDate; 
    }
 
    function setEndDate(uint256 poolId,uint256 _endDate) external onlyPoolOwner(poolId) {
        poolData[poolId].endDate = _endDate; 
    }

    function getEndDate(uint256 poolId) public view returns(uint256) {
        return poolData[poolId].endDate; 
    }

    function setMainToken(uint256 poolId,address  _tokenAddress) external onlyPoolOwner(poolId) {
        poolData[poolId].mainToken = _tokenAddress; 
    }

    function getMainToken(uint256 poolId) public view onlyExists(poolId) returns(address) {
        return poolData[poolId].mainToken; 
    }

    function setProjectToken(uint256 poolId,address _tokenAddress) external onlyPoolOwner(poolId) {
        poolData[poolId].projectToken = _tokenAddress; 
    }

    function getProjectToken(uint256 poolId) public view onlyExists(poolId) returns(address) {
        return poolData[poolId].projectToken; 
    }

    function setMinAllocation(uint256 poolId,uint256 _minAllocationPerUser) external onlyPoolOwner(poolId) {
        poolData[poolId].minAllocationPerUser = _minAllocationPerUser; 
    }

    function getMinAllocation(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return poolData[poolId].minAllocationPerUser; 
    }

    function getAdminAddress(uint256 poolId) public view onlyExists(poolId) returns(address) {
        return accessManager[poolId]; 
    }

    function getExchangeRate(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return poolData[poolId].exchangeRate; 
    }

    function setExchangeRate(uint256 poolId, uint256 newRate) public onlyExists(poolId) {
        poolData[poolId].exchangeRate = newRate; 
    }

    function setStatus(uint256 poolId,string memory _status) external onlyPoolOwner(poolId) {
        poolData[poolId].status = _status; 
    }

    function getStatus(uint256 poolId) public view onlyExists(poolId) returns(string memory) {
        if ( keccak256(bytes(poolData[poolId].status)) == keccak256(bytes('Paused')) || keccak256(bytes(poolData[poolId].status)) == keccak256(bytes('Cancelled')) ){
            return poolData[poolId].status;
        } 
        if ( poolData[poolId].startDate > block.timestamp ){
            return "Upcoming"        ;
        } else  if ( poolData[poolId].startDate < block.timestamp && poolData[poolId].endDate > block.timestamp ) {
            return "Ongoing";
        } else  return "Finished";
    }
   
    function whiteListForPool(uint256 poolId, address investor) external onlyPoolOwner(poolId) {
        whiteList[poolId].push(investor);
    }

    function isWhiteListedForPool(uint256 poolId,address investor) public view onlyExists(poolId) returns (bool) {
        for ( uint i = 0; i < whiteList[poolId].length; i++ ){
             if ( whiteList[poolId][i] == investor ){
               return true;
             }
         }
         return false;
    }

    function approve(uint256 poolId, uint256 _numberOfTokens) payable external  onlyInvestors(poolId) {
        PoolToken(poolData[poolId].mainToken).approve(msg.sender,address(this),_numberOfTokens );
    }

    function invest(uint256 poolId, uint256 _numberOfTokens) payable external  onlyInvestors(poolId) {
        require(keccak256(bytes(getStatus(poolId))) == keccak256(bytes('Ongoing')), '!Poolactive' );
        require( msg.value == ( _numberOfTokens * tokenPrice[poolId] ), 'Insufficent value' );
        require( ( poolData[poolId].totalInvested + _numberOfTokens ) < poolData[poolId].hardCap, 'OverSubscribed' );
        require( canPayout( poolId, _numberOfTokens ) );
        require( PoolToken(poolData[poolId].mainToken).transferFrom(msg.sender, address(this), _numberOfTokens ) );
        amountList[poolId][msg.sender] = _numberOfTokens;
        poolData[poolId].totalInvested += _numberOfTokens;
        emit NewInvestment(poolId,_numberOfTokens,poolData[poolId].projectToken);
    }

    function getAmountInvested(uint256 poolId) public view returns(uint256) {
        return amountList[poolId][msg.sender]; 
    }

    function getAmountInvestedByAddress(uint256 poolId, address investor) public view returns(uint256) {
        return amountList[poolId][investor]; 
    }

    function getExchangeAmount(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return ( amountList[poolId][msg.sender] * poolData[poolId].exchangeRate ) / 100; 
    }

    function getExchangeAmountFor(uint256 poolId, uint256 amount) public view returns(uint256) {
        return ( amount * poolData[poolId].exchangeRate ) / 100; 
    }

    function getTotalInvested(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return poolData[poolId].totalInvested; 
    }

    function getTokenPrice(uint256 poolId) public view onlyExists(poolId) returns(uint256) {
        return tokenPrice[poolId]; 
    }

    function approveClaim(uint256 poolId) external onlyPoolOwner(poolId){
        require(PoolToken(poolData[poolId].projectToken).approve( address(this), msg.sender, getExchangeAmount(poolId) ));
    }

    function claim(uint256 poolId) payable external  onlyInvestors(poolId) {
       require(keccak256(bytes(getStatus(poolId))) == keccak256(bytes('Finished')), '!Finished' );
       uint256 claimAmount =  getExchangeAmount(poolId);
       require( PoolToken(poolData[poolId].projectToken).transferFrom( address(this), msg.sender, claimAmount ), 'Transfer failed' );
       amountList[poolId][msg.sender] -= claimAmount;
       poolData[poolId].totalProjectTokens -= claimAmount;
       tokensSold[poolId] += claimAmount;
       emit TokensClaimed(poolId,claimAmount,poolData[poolId].projectToken);
    }

    function getTokensSold(uint256 poolId) public view onlyExists(poolId) returns (uint256){
        return  tokensSold[poolId]; 
    }

    function getInvestors(uint256 poolId) public view onlyExists(poolId) returns (address[] memory){
        return  whiteList[poolId]; 
    }

    function getProjectTokenTotal(uint256 poolId) public view onlyExists(poolId) returns (uint256){
        return  poolData[poolId].totalProjectTokens; 
    }

    function getBlockTimeStamp() public view returns(uint256) {
        uint256 time = block.timestamp;
        return time; 
    }

    function sendProjectTokens(uint256 poolId, uint256 _numberOfTokens) payable external  onlyPoolOwner(poolId) {
        require( msg.value == ( getExchangeAmountFor(poolId,_numberOfTokens ) * tokenPrice[poolId] ), 'Insufficent value' );
        require( PoolToken(poolData[poolId].projectToken).approve(msg.sender, address(this), _numberOfTokens ), 'Approval failed' );
        require( PoolToken(poolData[poolId].projectToken).transferFrom(msg.sender, address(this), _numberOfTokens ), 'Transfer failed' );
        poolData[poolId].totalProjectTokens += _numberOfTokens;
        emit PoolFunded(poolId,_numberOfTokens,poolData[poolId].projectToken);
    }

    function canPayout(uint256 poolId, uint256 additionalTokens) public view onlyExists(poolId) returns (bool){
        return poolData[poolId].totalProjectTokens >= ( getExchangeAmountFor(poolId,poolData[poolId].totalInvested + additionalTokens) );
    }

    function approveRetrieve(uint256 poolId) external onlyPoolOwner(poolId){
        require(PoolToken(poolData[poolId].mainToken).approve( address(this), msg.sender, poolData[poolId].totalInvested ));
    }

    function retrieveMainTokens(uint256 poolId) payable external  onlyPoolOwner(poolId) {
        require(keccak256(bytes(getStatus(poolId))) == keccak256(bytes('Finished')), '!Finished' );
        require( PoolToken(poolData[poolId].mainToken).transferFrom( address(this), msg.sender, poolData[poolId].totalInvested ), 'Transfer failed' );
        emit FundsRetrieved(poolId,poolData[poolId].totalInvested,poolData[poolId].mainToken);
        poolData[poolId].totalInvested = 0;
    }

}
