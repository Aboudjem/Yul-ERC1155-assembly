// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "../src/ERC1155.sol";

interface IERC1155 {
    function uri(uint256) external view returns(string memory);
    function mint(address, uint,uint) external;
    function balanceOfBatch(address[] calldata, uint[] calldata) external view returns(uint[] memory);
    function safeTransferFrom(address,address,uint,uint,bytes memory) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;

}

contract ERC1155Test is Test {
    YulDeployer public yulDeployer = new YulDeployer();

    ERC1155 public solContract;
    ERC1155 public yulContract;

    address public owner = 0x0000000000000000000000000000000000fffFfF;
    address public a = 0x0000000000000000000000000000000000AbC123;
    address public b = 0x0000000000000000000000000000000000123123;
    address public c = 0x0000000000000000000000000000000000aBCabc;

    function setUp() public {
        solContract = new ERC1155("ABC");
        abi.encodeWithSignature("deployContract(string)", "ERC1155");
        yulContract = ERC1155(yulDeployer.deployContract("ERC1155"));
    }

    function testUri() public {
        assertEq(solContract.uri(1), yulContract.uri(1), "Failed: mismatch");
    }

    // function testBalanceOf(uint id) public {
    //     // vm.assume(acc == address(0));
    //     // solContract.balanceOf(acc, id);
    //     vm.expectRevert();
  
    //     yulContract.balanceOf(address(0), id);
    //     // assertEq(solContract.balanceOf(acc, id), yulContract.balanceOf(acc, id), "Failed: mismatch");
    // }

    // function testMint(address receiver, uint id, uint amount) public {
    //     vm.assume(receiver != address(0) && amount > 1000);
    //     assertEq(yulContract.balanceOf(address(receiver), id), 0);

    //     yulContract.mint(receiver, id, amount);
    //     assertEq(yulContract.balanceOf(address(receiver), id), amount);
    //     console.log(yulContract.balanceOf(address(receiver), id));
    // }

    // function testBatchBalance() public {
    //     // uint addrLen = addresses.length;
    //     // vm.assume(addrLen == 4);
        
    //     address[] memory addArr = new address[](5);
    //     addArr[0] = 0xB4bbCc562A3D49A384aFf6481377f2a5c19cf1bF;
    //     addArr[1] = 0x2D1A0Ead2a42E8b2731E8F6169f0041EC38F7c9a;
    //     addArr[2] = 0xCA16B6d3D34F781c3E504EC16433EC44b4ac49e6;
    //     addArr[3] = 0x5fd1a905c827Fd2AdDBCa5D5C4d2170Adcc4c969;
    //     addArr[4] = 0xFbdc16F71155B583698cfE8658925E6ac94cEB6f;
        
    //     uint[] memory arr = new uint[](5);
    //     arr[0] = 32;
    //     arr[1] = 64;
    //     arr[2] = 128;
    //     arr[3] = 256;
    //     arr[4] = 512;
        
    //     yulContract.mint(addArr[0], arr[0], 64);
    //     yulContract.mint(addArr[1], arr[1], 64);
    //     yulContract.mint(addArr[2], arr[2], 64);
    //     yulContract.mint(addArr[3], arr[3], 64);
    //     yulContract.mint(addArr[4], arr[4], 64);

    //     solContract.mint(addArr[0], arr[0], 64);
    //     solContract.mint(addArr[1], arr[1], 64);
    //     solContract.mint(addArr[2], arr[2], 64);
    //     solContract.mint(addArr[3], arr[3], 64);
    //     solContract.mint(addArr[4], arr[4], 64);

    //     assertEq(yulContract.balanceOfBatch(addArr, arr), solContract.balanceOfBatch(addArr, arr));
    // }


    // function testSafeTransferFrom(address to, uint8 id, uint8 amount) public {
    //     address msgSender;
    //     vm.prank(msgSender, msg.sender);
    //     yulContract.safeTransferFrom(msgSender, to, id, amount, "");
    // }

    // function testIsApprovalForAllToTrue(address operator) public {
    //     address msgSender;
    //     vm.startPrank(msgSender, msg.sender);
    //     vm.assume(operator != msgSender);
    //     yulContract.setApprovalForAll(operator, true);
        
    //     solContract.setApprovalForAll(operator, true);
    //     assertEq(yulContract.isApprovalForAll(msgSender, operator), solContract.isApprovalForAll(msgSender, operator));
    //     vm.stopPrank();
    // }


    //     function testIsApprovalForAllToFalse(address operator) public {
    //     address msgSender;
    //     vm.startPrank(msgSender, msg.sender);
    //     vm.assume(operator != msgSender);
    //     yulContract.setApprovalForAll(operator, false);
        
    //     solContract.setApprovalForAll(operator, false);
    //     assertEq(yulContract.isApprovalForAll(msgSender, operator), solContract.isApprovalForAll(msgSender, operator));
    //     vm.stopPrank();
    // }

    // function testIsApprovalForAllToRandom(address operator, bool approval) public {
    //     address msgSender;
    //     vm.startPrank(msgSender, msg.sender);
    //     vm.assume(operator != msgSender);
    //     yulContract.setApprovalForAll(operator, approval);
        
    //     solContract.setApprovalForAll(operator, approval);
    //     assertEq(yulContract.isApprovalForAll(msgSender, operator), solContract.isApprovalForAll(msgSender, operator));
    //     vm.stopPrank();
    // }
//    function testSafeTransferFromWithApproval(address to, uint8 id, uint8 amount) public {
//         address msgSender = 0x0000000000000000000000000000000000000001;
//         vm.startPrank(msgSender, msg.sender);
//         vm.assume(to != msgSender && to != address(0));
//         yulContract.mint(msgSender, id, 1000000000000);
//         vm.stopPrank();
//         vm.prank(to, msg.sender);
//         yulContract.setApprovalForAll(msgSender, true);
//         yulContract.safeTransferFrom(msgSender, to, id, amount, "");
//     }

    function testTransferFromCaller() public {
        vm.prank(owner, msg.sender);
        yulContract.safeTransferFrom(owner, a, 0, 0, "");
        

        // yulContract.safeTransferFrom(a, b, 0, 0, "");

    }

    function testTransferFromApproved() public {
        // yulContract.safeTransferFrom(owner, a, 0, 0, "");
        vm.prank(a, msg.sender);
        yulContract.setApprovalForAll(b, true);
        vm.prank(b, msg.sender);
        yulContract.safeTransferFrom(a, b, 0, 0, "");

    }

    function testTransferFromNonCaller() public {
        vm.prank(owner, msg.sender);
        vm.expectRevert();
        yulContract.safeTransferFrom(c, b, 0, 0, "");
        

        // yulContract.safeTransferFrom(a, b, 0, 0, "");

    }

    function testTransferFromNonApproved() public {
        // yulContract.safeTransferFrom(owner, a, 0, 0, "");
        vm.prank(a, msg.sender);
        yulContract.setApprovalForAll(b, false);
        vm.prank(b, msg.sender);
        vm.expectRevert();
        yulContract.safeTransferFrom(a, b, 0, 0, "");

    }

    function testTransferFromNotEnoughBalance() public {
        // yulContract.safeTransferFrom(owner, a, 0, 0, "");
        vm.prank(a, msg.sender);
        yulContract.setApprovalForAll(b, true);
        vm.prank(b, msg.sender);
        vm.expectRevert();
        yulContract.safeTransferFrom(a, b, 0, 10, "");

    }

    function testTransferFromWithEnoughBalance() public {
        yulContract.mint(a, 0, 100);
        vm.prank(a, msg.sender);
        yulContract.setApprovalForAll(b, true);
        vm.prank(b, msg.sender);
        yulContract.safeTransferFrom(a, b, 0, 10, "");
        assertEq(yulContract.balanceOf(b, 0), 10);
        assertEq(yulContract.balanceOf(a, 0), 90);

        address[] memory addresses = new address[](2);
        addresses[0] = a;
        addresses[1] = b;

        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 0;
        uint[] memory balances = new uint[](2);
        balances[0] = 90;
        balances[1] = 10;
        assertEq(yulContract.balanceOfBatch(addresses, ids), balances);
    }


    // function testBatchBalanceMemory(address[] memory addresses, uint[] memory ids, uint amount) public {
    //     vm.assume(addresses.length == ids.length);
    //     for(uint i; i < addresses.length; i++) {
    //         if(addresses[i] != address(0)) {
    //             yulContract.mint(addresses[i], ids[i], amount);
    //             solContract.mint(addresses[i], ids[i], amount);
    //         }
    //     }

    //     assertEq(yulContract.balanceOfBatch(addresses, ids), sollContract.balanceOfBatch(addresses, ids));
    // }
}






// pragma solidity >=0.8.0;

// import "forge-std/Test.sol";
// import "./lib/YulDeployer.sol";
// import "../src/ERC1155.sol";

// interface IERC1155 {
//     function uri(uint256) external view returns(string memory);
//     function mint(address, uint,uint) external;
//     function balanceOfBatch(address[] calldata, uint[] calldata) external view returns(uint[] memory);
// }

// contract ERC1155Test is Test {
//     YulDeployer public yulDeployer = new YulDeployer();

//     ERC1155 public solContract;
//     ERC1155 public yulContract;

//     function setUp() public {
//         solContract = new ERC1155("ABC");
//         yulContract = ERC1155(yulDeployer.deployContract("ERC1155"));
//     }

//     // function testUri() public {
//     //     assertEq(solContract.uri(1), yulContract.uri(1), "Failed: mismatch");
//     // }

//     // function testBalanceOf(uint id) public {
//     //     // vm.assume(acc == address(0));
//     //     // solContract.balanceOf(acc, id);
//     //     vm.expectRevert();
  
//     //     yulContract.balanceOf(address(0), id);
//     //     // assertEq(solContract.balanceOf(acc, id), yulContract.balanceOf(acc, id), "Failed: mismatch");
//     // }

//     // function testMint(address receiver, uint id, uint amount) public {
//     //     vm.assume(receiver != address(0) && amount > 1000);
//     //     assertEq(yulContract.balanceOf(address(receiver), id), 0);

//     //     yulContract.mint(receiver, id, amount);
//     //     assertEq(yulContract.balanceOf(address(receiver), id), amount);
//     //     console.log(yulContract.balanceOf(address(receiver), id));
//     // }

//     function testBatchBalance(uint amount) public {
//         address[] memory addArr = new address[](5);
//         addArr[0] = 0xB4bbCc562A3D49A384aFf6481377f2a5c19cf1bF;
//         addArr[1] = 0x2D1A0Ead2a42E8b2731E8F6169f0041EC38F7c9a;
//         addArr[2] = 0xCA16B6d3D34F781c3E504EC16433EC44b4ac49e6;
//         addArr[3] = 0x5fd1a905c827Fd2AdDBCa5D5C4d2170Adcc4c969;
//         addArr[4] = 0xFbdc16F71155B583698cfE8658925E6ac94cEB6f;
        
//         uint[] memory arr = new uint[](5);
//         arr[0] = 32;
//         arr[1] = 64;
//         arr[2] = 128;
//         arr[3] = 256;
//         arr[4] = 512;
        
//         yulContract.mint(addArr[0], arr[0], amount);
//         yulContract.mint(addArr[1], arr[1], amount);
//         yulContract.mint(addArr[2], arr[2], amount);
//         yulContract.mint(addArr[3], arr[3], amount);
//         yulContract.mint(addArr[4], arr[4], amount);

//         solContract.mint(addArr[0], arr[0], amount);
//         solContract.mint(addArr[1], arr[1], amount);
//         solContract.mint(addArr[2], arr[2], amount);
//         solContract.mint(addArr[3], arr[3], amount);
//         solContract.mint(addArr[4], arr[4], amount);

//         assertEq(yulContract.balanceOfBatch(addArr, arr), solContract.balanceOfBatch(addArr, arr));
//     }

//     // 0x b7 17 e8 5c
//     // 0000000000000000000000000000000000000000000000000000000000000040
//     // 0000000000000000000000000000000000000000000000000000000000000060
//     // 0000000000000000000000000000000000000000000000000000000000000000
//     // 0000000000000000000000000000000000000000000000000000000000000000

// }


