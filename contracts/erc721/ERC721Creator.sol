// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract ERC721Creator is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public governance;
    

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance can call this");
        _;
    }
    constructor(string memory name_, string memory symbol_, address governance_) ERC721(name_, symbol_) public {
         governance = governance_;
    }

    function mintNft(address receiver, string memory tokenURI) external onlyGovernance returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI); 
        return newNftTokenId;
    }
}