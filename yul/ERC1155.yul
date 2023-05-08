// ╔══════════════════════════════════════════╗
// ║                 ERC1155                  ║
// ╚══════════════════════════════════════════╝

object "ERC1155" {
  code {
    // Store the initial URI
    sstore(0, "https://token.com/")
    
    // Copy the runtime code to memory and return it
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }
  
  // ╔══════════════════════════════════════════╗
  // ║                Runtime                   ║
  // ╚══════════════════════════════════════════╝

  object "Runtime" {
    // Return the calldata
    code {
        // Ensure no Ether was sent with the call
        require(iszero(callvalue()))

        // Load the function selector from calldata
        let s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)

        // Switch statement to handle different function calls
        switch s 
          // Query the URI of a token
          case 0x0e89341c { // uri(uint256)
            uri(decodeAsUint(0))
          } 
          
          // Query the balance of a specific token for an address
          case 0x00fdd58e { // balanceOf(address,uint256)
            returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
          }
          
          // Mint a new token with a specific ID and amount
          case 0x156e29f6 { // mint(address,uint256,uint256) 
            mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
          }
          
          // Query the balance of multiple tokens for an address
          case 0x4e1273f4 { // balanceOfBatch(address[],uint256[])
            balanceOfBatch()
          }
          
          // Set or unset approval for an operator
          case 0xa22cb465 { // setApprovalForAll(address,bool)  
            setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
          }
          
          // Check if an operator is approved for an address
          case 0xebd1d359 { // isApprovalForAll(address,address)
            returnUint(isApprovalForAll(decodeAsAddress(0), decodeAsAddress(1)))
          }

          // Transfer tokens safely from one address to another
          case 0xf242432a { // safeTransferFrom(address,address,uint256,uint256,bytes)
            safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
          }
          
          // Transfer multiple tokens safely from one address to another
          case 0x2eb2c2d6 { // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1))
          }

          case 0xb390c0ab {
            burn(caller(), decodeAsAddress(0), decodeAsUint(1))
          }
          
          // Revert for unknown function calls
          default {
            revert(0,0)
          }

      // ╔══════════════════════════════════════════╗
      // ║         Decoding Helper Functions        ║
      // ╚══════════════════════════════════════════╝

      // Function to decode calldata values as an address
      function decodeAsAddress(offset) -> v {
          v := decodeAsUint(offset)     // Ensure the decoded value is a valid address
          if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
          }
      }

      // Function to decode calldata values as a uint
      function decodeAsUint(offset) -> v {
          let pos := add(4, mul(offset, 0x20))
          if lt(calldatasize(), add(pos, 0x20)) {
              revert(0, 0)
          }
          v := calldataload(pos)
      }
    
      // ╔══════════════════════════════════════════╗
      // ║              Storage Layout              ║
      // ╚══════════════════════════════════════════╝
      
      function uriPos() -> p { p := 0 }
      
      function balanceOfStorageOffset(account) -> offset {
          offset := add(0x1000, account)
      }

      function allowanceStorageOffset(account, spender) -> offset {
          offset := balanceOfStorageOffset(account)
          mstore(0x00, offset)
          mstore(0x20, spender)
          offset := keccak256(0, 0x40)
      }

      // ╔══════════════════════════════════════════╗
      // ║            Contract Functions            ║
      // ╚══════════════════════════════════════════╝

      // Function to get the balance of a token for an address
      function balanceOf(account, id) -> bal {
          if eq(account, 0x0000000000000000000000000000000000000000) { 
            revertWithInvalidOwner()
          }
          mstore(0x00, balanceOfStorageOffset(account))
          mstore(0x20, id)
          bal := sload(keccak256(0x00, 0x40))
      }

      // Function to query the balances of multiple token IDs for multiple accounts
      function balanceOfBatch() {
          // Decode input parameters from calldata
          let addressOffset := decodeAsUint(0)
          let idOffset := decodeAsUint(1)
          
          // Load the lengths of the address and token ID arrays
          let addressArrayLength := calldataload(add(4, addressOffset))
          let idArrayLength := calldataload(add(4, idOffset))

          // Check if the lengths of both arrays match
          if iszero(eq(idArrayLength, addressArrayLength)) { revertWithAccountsAndIdsMismatch() }

          // Set the initial memory offset for storing the result
          let memOffset := 0x40

          // Store the length of the output array
          mstore(memOffset, 0x20)
          memOffset := add(memOffset, 0x20)
          mstore(memOffset, addressArrayLength)
          memOffset := add(memOffset, 0x20)

          // Iterate through each address and token ID pair
          for { let i := 0 } lt(i, idArrayLength) { i := add(i, 1) } {
            // Load the address and token ID from the input arrays
            let account := calldataload(add(add(4, sub(memOffset, 0x60)), addressOffset))
            if eq(account, 0x0000000000000000000000000000000000000000) { 
              revertWithInvalidOwner()
            }
            let id := calldataload(add(add(4, sub(memOffset, 0x60)), idOffset))
            
            // Retrieve the balance for the current address and token ID
            mstore(memOffset, balanceOf(account, id))
            
            // Move the memory offset for the next balance
            memOffset := add(memOffset, 0x20)
          }
          
          // Return the memory containing the balances array
          return (0x40, memOffset)
      }

      // Function to set or unset approval for an operator
      function setApprovalForAll(operator, approved) {
        if eq(operator, caller()) { revertWithSelfApproval() }
        sstore(allowanceStorageOffset(caller(), operator), approved)
        emitApprovalForAll(caller(), operator, approved)
      }

      // Function to check if     // an operator is approved by an account
      function isApprovalForAll(account, operator) -> allowed {
        allowed := sload(allowanceStorageOffset(account, operator))
      }

      // Function to safely transfer tokens between addresses
      function safeTransferFrom(from, to, id, amount, data) {

          if iszero(to) {
            revertWithTransferToZeroAddress()
          }
          // Check if the caller is the sender or has approval to transfer on behalf of the sender
          if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { 
            revertWithNotOwnerOrApproved()
          }


          // Calculate the storage locations for the from's and recipient's balances
          mstore(0x00, balanceOfStorageOffset(from))
          mstore(0x20, id)
          
          let fromBalanceLoc := keccak256(0x00, 0x40)

          mstore(0x00, balanceOfStorageOffset(to))
          let toBalanceLoc := keccak256(0x00, 0x40)

          // Load the from's and to's balances for the specified token ID
          let fromBalance := sload(fromBalanceLoc)
          let toBalance := sload(toBalanceLoc)

          // Check if the from has enough tokens to transfer
          if iszero(gte(fromBalance, amount)) {
            revertWithInsufficientBalance()
          }

          // Update the from's and to's balances
          sstore(fromBalanceLoc, safeSub(fromBalance, amount))
          sstore(toBalanceLoc, safeAdd(toBalance, amount)) 

          emitTransferSingle(caller(), from, to, id, amount)

          doSafeTransferAcceptanceCheck(from, to, id, amount, data)
      }

      // Function to safely transfer multiple tokens between addresses in a batch
      function safeBatchTransferFrom(from, to) {

          // Check if the caller is either the 'from' address or has approval for all tokens
          if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { revertWithNotOwnerOrApproved() } 
          
          // Check if the 'to' address is valid
          if iszero(to) { revertWithTransferToZeroAddress() }
          
          // Decode token IDs and amounts from calldata
          let idsOffset := decodeAsUint(2)
          let amountsOffset := decodeAsUint(3)

          // Calculate lengths of token IDs and amounts arrays
          let lenAmountsOffset := add(4, amountsOffset)
          let lenIdsOffset := add(4, idsOffset)

          let lenAmounts := calldataload(lenAmountsOffset)
          let lenIds := calldataload(lenIdsOffset)

          // Check if the lengths of token IDs and amounts arrays are equal
          if iszero(eq(lenAmounts, lenIds)) { revertWithIdsAndAmountsMismatch() }

          // Initialize the current offset
          let currentOffset := 0x20
 
          // Iterate through the token IDs and amounts arrays
          for { let i := 0 } lt(i, lenIds) { i := add(i, 1) } {

              // Load the current token ID and amount
              let id := calldataload(add(lenIdsOffset, currentOffset))
              let amount := calldataload(add(lenAmountsOffset, currentOffset))

              // Calculate the storage locations for 'from' and 'to' balances
              mstore(0x00, balanceOfStorageOffset(from))
              mstore(0x20, id)
              let fromBalanceLoc := keccak256(0x00, 0x40)

              mstore(0x00, balanceOfStorageOffset(to))
              let toBalanceLoc := keccak256(0x00, 0x40)

              // Load the current balances of 'from' and 'to' addresses
              let fromBalance := sload(fromBalanceLoc)
              let toBalance := sload(toBalanceLoc)

              // Check if the 'from' address has enough balance
              if iszero(gte(fromBalance, amount)) {
                revertWithInsufficientBalance()
              }

              // Update the balances of 'from' and 'to' addresses
              sstore(fromBalanceLoc, safeSub(fromBalance, amount))
              sstore(toBalanceLoc, safeAdd(toBalance, amount))
              
              // Update the current offset
              currentOffset := add(currentOffset, 0x20)
          }
            emitTransferBatch(caller(), from, to, idsOffset, amountsOffset)
      }

      // Function to mint tokens to an account
      function mint(account, id, amount) {
          if iszero(account) {
            revertWithMintToZeroAddress()
          }
          mstore(0x00, balanceOfStorageOffset(account))
          mstore(0x20, id)
          let loc := keccak256(0x00, 0x40)
          let bal := sload(loc)
          sstore(loc, safeAdd(bal, amount))

          emitTransferSingle(caller(), 0, account, id, amount)

          doSafeTransferAcceptanceCheck(0, account, id, amount, "")
      }

      // Function to mint tokens to an account
      function burn(account, id, amount) {
          if iszero(account) {
            revertWithBurnFromZeroAddress()
          }
          mstore(0x00, balanceOfStorageOffset(account))
          mstore(0x20, id)
          let loc := keccak256(0x00, 0x40)
          let bal := sload(loc)
          if iszero(gte(bal, amount)) {
            revertWithBurnAmountExceedsBalance()
          }
          sstore(loc, safeSub(bal, amount))

          emitTransferSingle(caller(), account, 0, id, amount)
      }

      // Function to return the token URI
      function uri(index) {
          mstore(0x00, 0x20)
          mstore(0x20, 0x12)
          mstore(0x40, sload(uriPos()))
          return(0x00, 0x60)
      }

      function doSafeTransferAcceptanceCheck(from, to, id, amount, data) {
          let size := extcodesize(to)

          if gt(size, 0) {

          // onERC1155Received(address,address,uint256,uint256,bytes)
          let selector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
          let errorSig := 0x8c379a000000000000000000000000000000000000000000000000000000000
          // calldata for onERC1155Received(operator, from, id, amount, data)
          mstore(0x100, selector)
          mstore(0x104, caller())
          mstore(0x124, from)
          mstore(0x144, id)
          mstore(0x164, amount)
          mstore(0x184, 0x1a0)
          
          // mstore(0x00, 0x00)
          let endPtr := copyDataToMem(0x1a4, data)
          mstore(0x00,0x00)
          let res := call(gas(), to, 0, 0x100, endPtr, 0x00, 0x04) 
          
          if eq(mload(0x00), errorSig) {
              returndatacopy(0x00, 0x00, returndatasize())
              revert(0x00, returndatasize())
          }

          if iszero(res) { 
            revertWithNonERC1155Receiver()
          }

          if iszero(eq(mload(0x00), selector)) {
            revertWithRejectedTokens()
          }
        }
      }
        



      // ╔══════════════════════════════════════════╗
      // ║        Calldata Encoding Functions       ║
      // ╚══════════════════════════════════════════╝

      // Function to return a uint value in memory
      function returnUint(v) {
          mstore(0, v)
          return(0, 0x20)
      }
      
      // Function to return true (1) as a uint value
      function returnTrue() {
          returnUint(1)
      }

      // ╔══════════════════════════════════════════╗
      // ║            Utility Functions             ║
      // ╚══════════════════════════════════════════╝

      // Function to check if a <= b
      function lte(a, b) -> r {
          r := iszero(gt(a, b))      
      }

      // Function to check if a >= b
      function gte(a, b) -> r {
          r := iszero(lt(a, b))
      }

      // Function to safely add two numbers, reverting if overflow occurs
      function safeAdd(a, b) -> r {
          r := add(a, b)
          if or(lt(r, a), lt(r, b)) { revert(0x00, 0x00) }
      }

      // Function to safely sub two numbers, reverting if overflow occurs
      function safeSub(a, b) -> r {
          r := sub(a, b)
          if gt(r, a) { revert(0x00, 0x00) }
      }

      // Function to require a condition is true, otherwise revert
      function require(condition) {
          if iszero(condition) { revert(0, 0) }
      }

      function copyDataToMem(memPtr, dataOff) -> updatedMemPtr {
          let dataLengthOff := add(dataOff, 4)
          let dataLength := calldataload(dataLengthOff)

          let totalLength := add(0x20, dataLength) // dataLength+data
          let remainder := mod(dataLength, 0x20)
          if remainder {
              totalLength := add(totalLength, sub(0x20, remainder))
          }
          calldatacopy(memPtr, dataLengthOff, totalLength)

          updatedMemPtr := add(memPtr, totalLength)
      }

      // TransferSingle(address,address,address,uint256)
      function emitTransferSingle(operator, from, to, id, amount) {
        let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        mstore(0x00, id)
        mstore(0x20, amount)
        log4(0x00, 0x40, signatureHash, operator, from, to)
      }

      // TransferBatch(address,address,address,uint256[],uint256[])
      function emitTransferBatch(operator, from, to, ids, amounts) {
        let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb

        let oldMptr := 0x00
        let mptr := oldMptr

        let idsOffsetPtr := mptr
        let valuesOffsetPtr := add(mptr, 0x20)

        mstore(idsOffsetPtr, 0x40) // ids offset

        let valuesPtr := copyDataToMem(add(mptr, 0x40), ids) // copy ids arary to memory

        mstore(valuesOffsetPtr, sub(valuesPtr, oldMptr)) // store values Offset
        let endPtr := copyDataToMem(valuesPtr, amounts) // copy values array to memory

        log4(oldMptr, sub(endPtr, oldMptr), signatureHash, operator, from, to)

        mstore(0x40, endPtr) // update Free Memory Pointer
    }



      // ApprovalForAll(address,address,bool)
      function emitApprovalForAll(account, operator, approved) {
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        mstore(0x00, approved)
        log3(0x00, 0x20, signatureHash, account, operator)
      }

      function emitURI(value, id) {
        let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
        mstore(0x00, value)
        log2(0x00, 0x20, signatureHash, id)
      }


      // Function to revert with a custom message and size
      function revertWithInvalidOwner() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 42)
        mstore(0x44, 0x455243313135353a2061646472657373207a65726f206973206e6f7420612076)
        mstore(0x64, 0x616c6964206f776e657200000000000000000000000000000000000000000000)

        revert(0x00, 0x84)
      }

      // Function to revert with a custom message and size
      function revertWithSelfApproval() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 41)
        mstore(0x44, 0x455243313135353a2073657474696e6720617070726f76616c20737461747573)
        mstore(0x64, 0x20666f722073656c660000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }

      // "ERC1155: accounts and ids length mismatch"
      function revertWithAccountsAndIdsMismatch() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 41)
        mstore(0x44, 0x455243313135353a206163636f756e747320616e6420696473206c656e677468)
        mstore(0x64, 0x206d69736d617463680000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: caller is not token owner or approved"
      function revertWithNotOwnerOrApproved() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 46)
        mstore(0x44, 0x455243313135353a2063616c6c6572206973206e6f7420746f6b656e206f776e)
        mstore(0x64, 0x6572206f7220617070726f766564000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
    
      // "ERC1155: transfer to the zero address"
      function revertWithTransferToZeroAddress() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 37)
        mstore(0x44, 0x455243313135353a207472616e7366657220746f20746865207a65726f206164)
        mstore(0x64, 0x6472657373000000000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: insufficient balance for transfer"
      function revertWithInsufficientBalance() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 42)
        mstore(0x44, 0x455243313135353a20696e73756666696369656e742062616c616e636520666f)
        mstore(0x64, 0x72207472616e7366657200000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: ids and amounts length mismatch"
      function revertWithIdsAndAmountsMismatch() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 41)
        mstore(0x44, 0x455243313135353a2069647320616e6420616d6f756e7473206c656e67746820)
        mstore(0x64, 0x6d69736d61746368000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x80)
      }   
      
      // "ERC1155: mint to the zero address"
      function revertWithMintToZeroAddress() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 33)
        mstore(0x44, 0x455243313135353a206d696e7420746f20746865207a65726f20616464726573)
        mstore(0x64, 0x7300000000000000000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: burn from the zero address"
      function revertWithBurnFromZeroAddress() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 35)
        mstore(0x44, 0x455243313135353a206275726e2066726f6d20746865207a65726f2061646472)
        mstore(0x64, 0x6573730000000000000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: burn amount exceeds balance"
      function revertWithBurnAmountExceedsBalance() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        mstore(0x24, 36)
        mstore(0x44, 0x455243313135353a206275726e20616d6f756e7420657863656564732062616c)
        mstore(0x64, 0x616e636500000000000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: ERC1155Receiver rejected tokens"
      function revertWithRejectedTokens() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 40)
        mstore(0x44, 0x455243313135353a204552433131353552656365697665722072656a65637465)
        mstore(0x64, 0x6420746f6b656e73000000000000000000000000000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
      
      // "ERC1155: transfer to non-ERC1155Receiver implementer"
      function revertWithNonERC1155Receiver() {
        mstore(0x00, 0x8c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0x04, 0x20)
        mstore(0x24, 52)
        mstore(0x44, 0x455243313135353a207472616e7366657220746f206e6f6e2d45524331313535)
        mstore(0x64, 0x526563656976657220696d706c656d656e746572000000000000000000000000)
                       
        revert(0x00, 0x84)
      }
    }
  }
}

       
