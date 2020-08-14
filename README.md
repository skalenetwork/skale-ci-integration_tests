This repostory is a collection of tests written by different developers whith keep in mind to test a main functionality of theirs code.

**List of tests**
- skale-manager
    - skale-manager+ts_1+schains_smoke_create_destroy
    - skale-manager+ts_1+schains_create_destroy
    - skale-manager+ts_1+node_rotation
    - skale-manager+ts_1+schains_delete_all
    - skale-manager+ts_1+get_schains_quantity
- skaled
    - skaled+load_js+run_angry_cats
    - skaled+internals+pytest
    - skaled+contractsRunningTest

**Workflow**
1. Update environment for test suites. Run command: "bash ./update_environment.sh ["*test suite name*"]". List of possible test suites is located at header of the script. If not a single test suite is provided then all tests suites' environments will be updated.
2. Run tests. Run command: "bash ./run_tests.sh ["*test name*"]". List of possible test is located at header of the script. If not a single test is provided then all tests will be updated.

