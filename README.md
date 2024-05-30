# testutils

Useful Erlang test utilities.

## Waiting for Calls

TBD

```erlang
Call = testutils:trace_call(lists, seq, [1, 10]),
spawn(fun() -> lists:seq(1, 10) end),
testutils:await(Call).
```
