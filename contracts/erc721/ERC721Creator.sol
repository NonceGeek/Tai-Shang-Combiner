// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ERC721Creator is ERC721URIStorage, ERC721Enumerable, Ownable {
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
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintNft(address receiver, string memory tokenURI) external onlyGovernance returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI); 
        return newNftTokenId;
    }
}