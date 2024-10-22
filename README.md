[![Skaled Nightly Tests](https://github.com/skalenetwork/skale-ci-integration_tests/workflows/Skaled%20Nightly%20Tests/badge.svg)](https://github.com/skalenetwork/skale-ci-integration_tests/actions?query=workflow%3A%22Skaled+Nightly+Tests%22)

This repostory is a collection of tests written by different developers whith keep in mind to test a main functionality of theirs code.

## Server preparation
1. Install `jq zip unzip`
2. Install `nodejs` 20, `npm`, `npx`, `hardhat`
3. Run `npx hardhat run scripts/deploy.ts --network custom` in `blockchain-killer` and ensure it works

## How to use
1. Update environment for test suites. Run command: "bash ./update_environment.sh ["*test suite name*"]". List of possible test suites is located at header of the script. If not a single test suite is provided then all tests suites' environments will be updated.
2. Run tests. Run command: "bash ./run_tests.sh ["*test name*"]". List of possible test is located at header of the script. If not a single test is provided then all tests will be run.
3. See [skaled_manual.yml](https://github.com/skalenetwork/skale-ci-integration_tests/blob/master/.github/workflows/skaled_manual.yml#L92) workflow as an example.


## List of tests

### skaled
 - **skaled+load_python+all** Execute 24000 simple transactions on a 4-node schain, check all mined.
 - **skaled+load_js+run_angry_cats** Run cycle of 150 accounts exchanging 100 simple transactions each.
 
 - **skaled+contractsRunningTest** Deploy contracts, test conract storage, test transfer of ERC-20, ERC-721 tokens.
 - **skaled+api+all** Test event API https://github.com/skalenetwork/SkaleExperimental/tree/master/skaled-tests/test-events
 
 - **skaled+internals+pytest**
   - test_chainid - Use chainId with length up to maximum 52 bits, transaction with correct chainId should succeed, transaction with incorrect or without chainId at all should fail.
   - test_stop - Skaled should not immediately exit by SIGTERM when consensus is in progress.
   - test_rotation - Old blocks and events emitted in that blocks should disappear because of block rotation.
   - test_race - On 2-node schain check possible races in transaction processing pipeline: `receive->broadcast->propose->drop from queue->execute->write to DB`
 - **skaled+internals+test_snapshot_api** On 1 node: test `eth_getSnapshotSignature`, `eth_getSnapshot`, `eth_downloadSnapshotFragment`. Try to access unavailable snapshots, check that longs snapshot hash calculation delays next snapshot, try to download snapshot from skaled which has just started from snapshot itself. Check that shared space is blocked and unblocked as expected.
 - **skaled+internals+test_node_rotation** On 4-node schain try restart node from snapshot, try when latest snapshot present or not present on client locally, simulate crash and repair by stateRoot mismatch.
 
 - **skaled+filestorage+all** Run tests in https://github.com/skalenetwork/filestorage.js
