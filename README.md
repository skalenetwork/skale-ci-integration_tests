[![Skaled Nightly Tests](https://github.com/skalenetwork/skale-ci-integration_tests/workflows/Skaled%20Nightly%20Tests/badge.svg)](https://github.com/skalenetwork/skale-ci-integration_tests/actions?query=workflow%3A%22Skaled+Nightly+Tests%22)

This repostory is a collection of tests written by different developers whith keep in mind to test a main functionality of theirs code.

## How to use
1. Update environment for test suites. Run command: "bash ./update_environment.sh ["*test suite name*"]". List of possible test suites is located at header of the script. If not a single test suite is provided then all tests suites' environments will be updated.
2. Run tests. Run command: "bash ./run_tests.sh ["*test name*"]". List of possible test is located at header of the script. If not a single test is provided then all tests will be run.
3. See [skaled_manual.yml](https://github.com/skalenetwork/skale-ci-integration_tests/blob/master/.github/workflows/skaled_manual.yml#L92) workflow as an example.


## List of tests
### skale-manager **NOT MAINTAINED**
 - ~~skale-manager+ts_1+schains_smoke_create_destroy~~
 - ~~skale-manager+ts_1+schains_create_destroy~~
 - ~~skale-manager+ts_1+node_rotation~~
 - ~~skale-manager+ts_1+schains_delete_all~~
 - ~~skale-manager+ts_1+get_schains_quantity~~

### skaled
 - **skaled+internals+pytest**
   - test_chainid - Use chainId with length up to maximum 52 bits, transaction with correct chainId should succeed, transaction with incorrect or without chainId at all should fail.
   - test_stop - Skaled should not immediately exit by SIGTERM when consensus is in progress.
   - test_rotation - Old blocks and events emitted in that blocks should disappear because of block rotation.
   - test_race - On 2-node schain check possible races in transaction processing pipeline: receive->broadcast->propose->drop from queue->execute->write to DB
 - **skaled+internals+test_snapshot_api**
 - **skaled+internals+test_node_rotation**
 
 - **skaled+load_python+all**
 - **skaled+load_js+run_angry_cats**
 
 - **skaled+contractsRunningTest**
 - **skaled+api+all**
 
 - **skaled+filestorage+all**
