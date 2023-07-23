-include .env

deploy_on_Moonbase_Alpha:
	forge script src/script/DeployMotivate.s.sol:DeployMotivate --rpc-url $(MOONBASE_ALPHA_BLAST_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

verify_contract:
	forge verify-contract $(DEPLOYED_CONTRACT_ADDRESS) src/script/DeployMotivate.s.sol:DeployMotivate --verifier etherscan --verifier-url https://api-moonbase.moonscan.io/api --chain 1287 --etherscan-api-key $(MOONSCAN_API_KEY)
