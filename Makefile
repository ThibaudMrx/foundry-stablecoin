-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest


all: clean remove install

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; 	rm -rf .gitmodules &&\
			rm -rf .git/modules/* &&\
			rm -rf lib &&\
			touch .gitmodules &&\
			git add . &&\
 			git commit -m "modules"

install :; 	forge install foundry-rs/forge-std@v1.8.2 --no-commit &&\
 			forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit