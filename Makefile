include .env

deploy-sepolia:
	@echo "Deploying to $(SEPOLIA_URL)"
	forge script script/deployPIG.s.sol --private-key $(REAL_PRIVATE_KEY) --rpc-url $(SEPOLIA_URL) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

deploy-mainnet:
	@echo "Deploying to $(MAINNET_URL)"
	forge script script/deployPIG.s.sol --private-key $(REAL_PRIVATE_KEY) --rpc-url $(SEPOLIA_URL) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)