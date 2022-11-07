// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange {
    function transfer(address nftContract, address from, address to, uint256 tokenId) public {
        IERC721(nftContract).transferFrom(from, to, tokenId);
    }
}
