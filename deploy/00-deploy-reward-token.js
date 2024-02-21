module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const rewardToken = await ethers.getContract("RewardToken");

    const stakingDeployment = await deploy("Staking", )
}

module.exports.tags = ["all", "rewardToken"];