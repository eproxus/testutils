-module(testutils).

-behaviour(gen_statem).

% API
-ignore_xref(trace_call/1).
-export([trace_call/1]).
-ignore_xref(await/1).
-export([await/1]).
-ignore_xref(await/2).
-export([await/2]).

% gen_statem Callbacks
-export([init/1]).
-export([callback_mode/0]).
-export([handle_event/4]).

%--- API -----------------------------------------------------------------------

trace_call({M, F, Args}) ->
    case code:load_file(M) of
        {module, M} -> ok;
        _ -> error({undefined_mfa, {M, F, Args}})
    end,

    {_Pid, Session} = State = trace_session(),
    trace:process(Session, all, true, [call]),

    MatchSpec = [{'_', [], [{exception_trace}]}],
    case trace:function(Session, {M, F, length(Args)}, MatchSpec, [local]) of
        0 -> error({undefined_mfa, {M, F, Args}});
        _ -> State
    end.

await(State) -> await(State, 5000).

await({Pid, _Session}, Timeout) ->
    try
        gen_statem:call(Pid, wait, Timeout)
    catch
        exit:{timeout, {gen_statem, call, [Pid, wait, Timeout]}} ->
            error(timeout)
    end.

%--- gen_statem Callbacks ------------------------------------------------------

init(args) -> {ok, startup, #{called => false}}.

callback_mode() -> handle_event_function.

handle_event({call, From}, {session, Session}, startup, Data) ->
    {next_state, listen, Data#{session => Session}, [{reply, From, ok}]};
handle_event(info, {trace, _Pid, return_from, _MFArgs, _Result}, _State, #{wait := From} = Data) ->
    {keep_state, Data#{called => true}, [{reply, From, ok}]};
handle_event(info, {trace, _Pid, return_from, _MFArgs}, _State, Data) ->
    {keep_state, Data#{called := true}};
handle_event({call, From}, wait, listen, #{called := false} = Data) ->
    {keep_state, Data#{wait => From}};
handle_event({call, From}, wait, listen, #{called := true}) ->
    {keep_state_and_data, [{reply, From, ok}]};
handle_event({call, From}, Call, State, Data) ->
    exit({unknown_call, Call, From, State, Data});
handle_event(_Event, _EventData, _State, _Data) ->
    keep_state_and_data.

%--- Internal ------------------------------------------------------------------

trace_session() ->
    Name = binary_to_atom(integer_to_binary(erlang:unique_integer())),
    {ok, Pid} = gen_statem:start_link(?MODULE, args, []),
    Session = trace:session_create(Name, Pid, []),
    gen_statem:call(Pid, {session, Session}),
    {Pid, Session}.
