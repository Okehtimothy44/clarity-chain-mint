import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test asset class creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create asset class as owner
    let block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'create-asset-class',
        [types.ascii("Real Estate"), types.ascii("REAL")],
        deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Try create asset class as non-owner
    block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'create-asset-class',
        [types.ascii("Real Estate"), types.ascii("REAL")],
        wallet1.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test asset minting and transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Create asset class
    let block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'create-asset-class',
        [types.ascii("Real Estate"), types.ascii("REAL")],
        deployer.address)
    ]);
    
    // Mint asset
    const metadata = types.some(types.utf8("location: Miami"));
    block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'mint-asset',
        [types.principal(wallet1.address),
         types.ascii("123 Main St"),
         metadata,
         types.uint(1)],
        deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectUint(2);
    
    // Transfer asset
    block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'transfer-asset',
        [types.uint(2),
         types.principal(wallet1.address),
         types.principal(wallet2.address)],
        wallet1.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify asset details
    const response = chain.callReadOnlyFn('chain-mint', 'get-asset-details',
      [types.uint(2)],
      deployer.address
    );
    const result = response.result.expectOk().expectSome();
    assertEquals(result['owner'], wallet2.address);
  }
});

Clarinet.test({
  name: "Test asset verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create asset class and mint asset
    let block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'create-asset-class',
        [types.ascii("Real Estate"), types.ascii("REAL")],
        deployer.address),
      Tx.contractCall('chain-mint', 'mint-asset',
        [types.principal(wallet1.address),
         types.ascii("123 Main St"),
         types.none(),
         types.uint(1)],
        deployer.address)
    ]);
    
    // Verify asset as owner
    block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'verify-asset',
        [types.uint(2)],
        deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try verify as non-owner
    block = chain.mineBlock([
      Tx.contractCall('chain-mint', 'verify-asset',
        [types.uint(2)],
        wallet1.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});
