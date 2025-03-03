// [Previous test content remains, adding new tests for new features]

Clarinet.test({
  name: "Test invalid string handling",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'create-asset-class',
        [types.ascii(""), types.ascii("REAL")],
        deployer.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(104);
  }
});

// [Additional tests for new features...]
