-include .env

deploy-sepolia:; forge script script/DeployFundMe.s.sol:DeployFundMe --broadcast --verify --fork-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --etherscan-api-key $(ETHERSCAN_API_KEY)