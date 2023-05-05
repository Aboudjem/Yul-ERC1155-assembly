// ╔══════════════════════════════════════════╗
// ║                 ERC1155                  ║
// ╚══════════════════════════════════════════╝

object "ERC1155" {
  code {
    // Store the initial URI
    sstore(0, "ABC")
    
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
            safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), 0x00)
          }
          
          // Transfer multiple tokens safely from one address to another
          case 0x2eb2c2d6 { // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1))
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
            revertWithMessage("Not a valid owner", 0x12)
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
          if iszero(eq(idArrayLength, addressArrayLength)) { revert(0x00, 0x00) }

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
          sstore(allowanceStorageOffset(caller(), operator), approved)
      }

      // Function to check if     // an operator is approved by an account
      function isApprovalForAll(account, operator) -> allowed {
          allowed := sload(allowanceStorageOffset(account, operator))
      }

      // Function to safely transfer tokens between addresses
      function safeTransferFrom(from, to, id, amount, data) {
          // Check if the caller is the sender or has approval to transfer on behalf of the sender
          if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { 
            revert (0x80, 0x140)
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
          require(gte(fromBalance, amount))

          // Update the from's and to's balances
          sstore(fromBalanceLoc, sub(fromBalance, amount))
          sstore(toBalanceLoc, add(toBalance, amount)) 
      }

      // Function to safely transfer multiple tokens between addresses in a batch
      function safeBatchTransferFrom(from, to) {
          
          // Check if the 'from' address is valid
          if iszero(from) { revert(0x00, 0x00) }
          
          // Decode token IDs and amounts from calldata
          let idsOffset := decodeAsUint(2)
          let amountsOffset := decodeAsUint(3)

          // Calculate lengths of token IDs and amounts arrays
          let lenAmountsOffset := add(4, amountsOffset)
          let lenIdsOffset := add(4, idsOffset)

          let lenAmounts := calldataload(lenAmountsOffset)
          let lenIds := calldataload(lenIdsOffset)

          // Check if the lengths of token IDs and amounts arrays are equal
          if iszero(eq(lenAmounts, lenIds)) { revert (0x00, 0x00) }

          // Initialize the current offset
          let currentOffset := 0x00
          currentOffset := add(currentOffset, 0x20)

          // Check if the caller is either the 'from' address or has approval for all tokens
          if iszero(or(eq(caller(), from), isApprovalForAll(from, caller()))) { revert (0x00, 0x00) } 

          // Iterate through the token IDs and amounts arrays
          for { let i := 0 } lt(i, lenIds) { i := add(i, 1) } {

              // Load the current token ID and amount
              let id := calldataload(add(lenIdsOffset, currentOffset))
              let amount := calldataload(add(lenAmountsOffset, sub(currentOffset, 0x00)))

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
              require(gte(fromBalance, amount))

              // Update the balances of 'from' and 'to' addresses
              sstore(fromBalanceLoc, sub(fromBalance, amount))
              sstore(toBalanceLoc, add(toBalance, amount))
              
              // Update the current offset
              currentOffset := add(currentOffset, 0x20)
          }
      }


      // Function to mint tokens to an account
      function mint(account, id, amount) {
          mstore(0x00, balanceOfStorageOffset(account))
          mstore(0x20, id)
          let loc := keccak256(0x00, 0x40)
          let bal := sload(loc)
          sstore(loc, add(bal, amount))
          returnTrue()
      }

      // Function to return the token URI
      function uri(index) {
          mstore(0x00, 0x20)
          mstore(0x20, 0x03)
          mstore(0x40, sload(uriPos()))
          return(0x00, 0x60)
      }

      // ╔══════════════════════════════════════════╗
      // ║        Calldata Encoding Functions       ║
      // ╚══════════════════════════════════════════╝

      /* ---------- calldata encoding functions ---------- */

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
          if or(lt(r, a), lt(r, b)) { revert(0, 0) }
      }

      // Function to revert if the address is zero
      function revertIfZeroAddress(addr) {
          require(addr)
      }

      // Function to require a condition is true, otherwise revert
      function require(condition) {
          if iszero(condition) { revert(0, 0) }
      }

      // Function to revert with a custom message and size
      function revertWithMessage(msg, size) {
          mstore(0x00, 0x20)
          mstore(0x20, size)
          mstore(0x40, msg)
          revert(0x00, 0x60)
      }
    }
  }
}

       
