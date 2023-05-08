// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract ERC1155ReceiverRevert {

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    ) external returns (bytes4) {
        revert("Revert something");
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata 
    ) external returns (bytes4) {
        revert("Revert something");
    }


}