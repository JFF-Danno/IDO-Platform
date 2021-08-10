const { expect } = require("chai");
const web3 = require('web3');


describe("Greeter", function () {
  it("Should setup an auction with a pool manager and allow white listing and editing of the contract.", async function () {
   
    const IDO = await hre.ethers.getContractFactory("IDO");
    const ido = await IDO.deploy();
    await ido.deployed();


    console.log("################################");
    console.log("IDO deployed to:", ido.address);
    console.log("######");
    const accounts = await hre.ethers.getSigners();
    const AdminAddress          = accounts[0].address;
    const PoolManagerAddress    = accounts[1].address;
    const InvestorAddress       = accounts[2].address;
    const NotWhiteListedAddress = accounts[3].address;

    console.log("######");
    
    console.log( 'deploying pool tokens' );
    const pt = await hre.ethers.getContractFactory("PoolToken" );
    const poolToken = await pt.deploy();//projecttoken
    const bidToken = await pt.deploy(); //maintoken

    await poolToken.deployed();
    await bidToken.deployed();
    console.log( '#### deployed '  );  
    console.log( 'pool token ' + poolToken.address );
    console.log( 'bid token ' + bidToken.address );

    console.log( 'Adding a pool manager' );
    await ido.addManager( PoolManagerAddress    );
    await ido.addManager( AdminAddress          );

    const id = await ido.initiatePool( 1000000, 500000, 1628512528, 1629513528, bidToken.address, poolToken.address, 10, AdminAddress, 90, 100000000000 );

    var poolId = await ido.getPoolId();
    console.log('Pool id ' + poolId );
    console.log("\n\n################################ Checking Pool Data");
    const hardcap = await ido.getHardCap( poolId );
    expect(hardcap).to.equal(1000000);
    console.log( 'check hard cap: success ' + hardcap.toString() );

    const softcap = await ido.getSoftCap( poolId );
    expect(softcap).to.equal(500000);
    console.log(  'check soft cap: success ' + softcap.toString() );

    const startDate = await ido.getStartDate( poolId );
    expect(startDate).to.equal(1628512528);
    console.log(  'check start date: success ' + startDate ) ;

    const endDate = await ido.getEndDate( poolId );
    expect(endDate).to.equal(1629513528);
    console.log(  'check end date: success ' + endDate );
    
    const mainToken = await ido.getMainToken( poolId );
    expect(mainToken).to.equal(bidToken.address);
    console.log(  'check main token: success ' + bidToken.address ) ;

    const projectToken = await ido.getProjectToken( poolId );
    expect(projectToken).to.equal(poolToken.address);
    console.log(  'check project token: success ' + poolToken.address ) ;

    const minAllocation = await ido.getMinAllocation( poolId );
    expect(minAllocation).to.equal(10);
    console.log(  'check min allocation: success ' + minAllocation.toString() );

    const _adminAddress = await ido.getAdminAddress( poolId );
    expect(_adminAddress).to.equal(AdminAddress);
    console.log(  'check admin address: success ' + _adminAddress ) ;


    const exchangeRate = await ido.getExchangeRate( poolId );
    expect(exchangeRate).to.equal(90);
    console.log(  'check exchange rate in %: success ' + exchangeRate );

    console.log("\n\n################################ Finished Checking Pool Data");

    console.log("\n\n################################ White Listing");
    await ido.whiteListForPool( poolId, AdminAddress );
    const isWhiteListed =     await ido.isWhiteListedForPool( poolId, AdminAddress );
    expect(isWhiteListed).to.equal(true);
    console.log( 'check white listed ' + isWhiteListed );

    await ido.whiteListForPool( poolId, InvestorAddress );
    const isWhiteListed2 =     await ido.isWhiteListedForPool( poolId, InvestorAddress );
    expect(isWhiteListed2).to.equal(true);
    console.log( 'check white listed2 ' + isWhiteListed2 );

    const investors = await ido.getInvestors( poolId );
    expect(investors.length).to.equal(2);
    console.log('investors white list ' + investors );
    console.log("\n\n################################ Finished White Listing");
  
  console.log("\n\n################################ Status");

    const time = await ido.getBlockTimeStamp( );
    console.log( 'timestamp  ' + time );
    
    await ido.setEndDate( poolId, ( time.toNumber() + 1000 ) );
    await ido.setStartDate( poolId, ( time.toNumber() + 3 ) );

    const startDate2 = await ido.getStartDate( poolId );
    console.log(  'new start date ' + startDate2 + ' \nblock ' + await ido.getBlockTimeStamp( ) ) ;

    expect(await ido.getStatus( poolId )).to.equal("Upcoming");
    console.log( 'status expecting Upcoming : success ' +  await ido.getStatus( poolId ) );

    console.log( 'setting status to Cancelled' );
    await ido.setStatus( poolId, "Cancelled");
    expect(await ido.getStatus( poolId )).to.equal("Cancelled");
    console.log( 'status expecting Cancelled : success ' +  await ido.getStatus( poolId ) );
    
    console.log( 'setting status to Paused' );
    await ido.setStatus( poolId, "Paused");
    expect(await ido.getStatus( poolId )).to.equal("Paused");
    console.log( 'status expecting Paused : success ' +  await ido.getStatus( poolId ) );

    console.log( 'resetting status, has startDate passed yet? current time = ' + await ido.getBlockTimeStamp( ) + ' start time = ' + startDate2 );
    await ido.setStatus( poolId, "");
    expect(await ido.getStatus( poolId )).to.equal("Ongoing");
    console.log( 'status expecting Ongoing : success ' +  await ido.getStatus( poolId ) );

    console.log( 'resetting endDate to end the IDO, current time = ' + await ido.getBlockTimeStamp());
    await ido.setEndDate( poolId, ( await ido.getBlockTimeStamp() ) );
    expect(await ido.getStatus( poolId )).to.equal("Finished");
    console.log( 'status expecting Finished : success ' +  await ido.getStatus( poolId ) );

    console.log("\n\n################################ Finished  Status");

    console.log("\n\n################################ Send tokens");

    const price = await ido.getTokenPrice( poolId );
    const valueSend2 = 0.9 * price * 1000;
    console.log( 'value to send ' + valueSend2);
    await ido.sendProjectTokens( poolId, 1000 , { from: AdminAddress, value:  valueSend2 } );
    const balanceMe = await poolToken.balanceOf(accounts[0].address);
    console.log('my balance   ' + balanceMe ); 
    const balanceido = await poolToken.balanceOf(ido.address);
    console.log('pool balance   ' + balanceido ); 
    const balanceProjectTokens = await ido.getProjectTokenTotal(poolId);
    console.log('project token pool balance : ' + balanceProjectTokens ); 
    expect(balanceProjectTokens).to.equal(balanceido);
    console.log('check project token pool balance success : ' + balanceProjectTokens ); 

    const canPay = await ido.canPayout(poolId, 100);
    console.log('can payout with additional investment? : ' + canPay ); 

    const exchangeAmount = await ido.getExchangeAmountFor(poolId, 100 );
    console.log('tokens to receive for investment of 100 main tokens @ 0.9/90% ? : ' +  exchangeAmount.toString() ); 
    expect('90').to.equal(exchangeAmount);
    console.log('check exchange amount success : ' +  exchangeAmount.toString() ); 


    console.log("\n\n################################ Finished Send tokens");

   console.log("\n\n################################ Invest");

    //value: numberOfTokens * tokenPrice

    console.log( 'price ', web3.utils.fromWei( price.toString() ) );
    await ido.setEndDate( poolId, ( await ido.getBlockTimeStamp() + 1000 ) );
    console.log( 'status ', await ido.getStatus( poolId ) );
    const valueSend = price * 10;
    console.log( 'value to send ' + valueSend);
    await ido.approve( poolId, 10 );
    await ido.invest( poolId,  10, { from: AdminAddress, value:  valueSend } );

    const invested = await ido.getAmountInvested( poolId );
    console.log('invested ' + invested.toString() );

    const investedByAddress = await ido.getAmountInvestedByAddress( poolId, AdminAddress );
    console.log('invested by address' + investedByAddress.toString() );


    console.log("\n\n################################ Finished Invest");


   console.log("\n\n################################ Claim");
   const balance = await poolToken.balanceOf(accounts[0].address);
    console.log('project token my balance   ' + balance.toString() ); 

    const balancePT = await ido.getProjectTokenTotal(poolId);
    console.log('project token pool balance : ' + balancePT.toString() ); 

    const claimAmount = await ido.getExchangeAmount(poolId);
    console.log('project token amount to claim : ' + claimAmount.toString() ); 
    
    const invested2 = await ido.getAmountInvested(poolId);
    console.log('main token amount invested : ' + invested2.toString()  ); 

    await ido.setEndDate( poolId, ( await ido.getBlockTimeStamp() -2 ) );
    console.log( 'set end date to give status finished ', await ido.getStatus( poolId ) );
    await ido.approveClaim(poolId);
    await ido.claim( poolId );
    const balancenew = await poolToken.balanceOf(accounts[0].address);
    console.log('new balance of projct token ' + balancenew.toString() );

    const balancePT2 = await ido.getProjectTokenTotal(poolId);
    console.log('new project token pool balance : ' + balancePT2.toString() ); 

    const sold = await ido.getTokensSold(poolId);
    console.log('tokens sold : ' + sold.toString() ); 


    console.log("\n\n################################ Finished Claim");

  

    console.log("\n\n################################ Retrieve" );

    const balancePreRetrieve = await bidToken.balanceOf(AdminAddress);
    console.log('my balance of project token ' +  balancePreRetrieve.toString() );
    const balanceidopre = await bidToken.balanceOf(ido.address);
    console.log('pool balance pre  ' + balanceidopre.toString() ); 
    await ido.approveRetrieve( poolId );
    await ido.retrieveMainTokens( poolId );
    const balancePostRetrieve = await bidToken.balanceOf(AdminAddress);
    console.log('new my balance of project token ' + balancePostRetrieve.toString() );
    const balanceidopost = await bidToken.balanceOf(ido.address);
    console.log('pool balance post  ' +  balanceidopost.toString() ); 

    console.log("\n\n################################ Finished Retrieve" );


  });

});



