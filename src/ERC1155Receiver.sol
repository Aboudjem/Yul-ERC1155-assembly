// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract ERC1155Receiver {

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata 
    ) external returns (bytes4) {
        return 0xaabbccdd;
    }


}