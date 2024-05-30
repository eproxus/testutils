-module(testutils_tests).

-include_lib("eunit/include/eunit.hrl").

%--- Tests ---------------------------------------------------------------------

wait_for_call_test() ->
    Call = testutils:trace_call({foo, bar, [1, 2]}),
    spawn(fun() ->
        foo:bar(1, 2),
        foo:bar(1, 2),
        foo:bar(1, 2)
    end),
    foo:bar(1, 2),
    testutils:await(Call, 500).

wait_for_call_timeout_test() ->
    Call = testutils:trace_call({foo, bar, [1, 2]}),
    ?assertError(timeout, testutils:await(Call, 0)).

%--- Internal ------------------------------------------------------------------
