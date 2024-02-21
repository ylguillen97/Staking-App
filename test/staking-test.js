// Execute with: npx hardhat test

const { ethers, deployments } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")
const { moveTime } = require("../utils/move-time")

const SECONDS_IN_A_DAY = 86400
const SECONDS_IN_A_YEAR = 31149600

describe("Staking Test", async function(){
    let staking, rewardToken, deployer, stakeAmount

    beforeEach(async function(){ // before each test we run
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        await deployments.fixture(["all"])

        staking = await ethers.getContract("Staking")
        rewardToken = await ethers.getContract("RewardToken")
        stakeAmount = ethers.utils.parseEther("10000")
    })  

    
    it("Allows users to stake and claim rewards", async function() {
        await rewardToken.approve(staking.address, stakeAmount) // we need to aprove before staking (because staking function call transferFrom())
        await staking.stake(stakeAmount)
        const startingEarned = await staking.earned(deployer.address)
        console.log(`Starting Earned ${startingEarned}`)

        //we move time 1 day and 1 block
        await moveTime(SECONDS_IN_A_DAY) //end of the day
        await moveBlocks(1)
        const endingEarned = await staking.earned(deployer.address)
        console.log(`Starting Earned ${endingEarned}`)

        //we move 1 year and 1 block
        await moveTime(SECONDS_IN_A_YEAR) //end of the day
        await moveBlocks(1)
        const endingEarned_year = await staking.earned(deployer.address)
        console.log(`Starting Earned ${endingEarned_year}`)
    })
})