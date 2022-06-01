# solidity-smart-contracts

These contracts enables users to create collections with specified royalties using ERC1155 token standard.

### ERC2981PerTokenRoyalties 
- stores royalty information about the token.
### ERC1155Collection 
- enables users to mint, mintBatch and mintMore semi-fungible tokens with specified royalties.
### CollectionFactory 
- creates beacon proxies for ERC1155Collection, stores addresses of new collection copies in two different ways and enables ADMIN to update initial implementation of the ERC1155Collection contract. 
