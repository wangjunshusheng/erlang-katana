-module(katana).

-export([
         wait_for/2,
         wait_for/4,
         wait_for_success/1,
         wait_for_success/3,
         now_human_readable/0,
         beam_to_erl/2
        ]).

wait_for(Task, ExpectedAnswer) ->
    wait_for(Task, ExpectedAnswer, 200, 10).

wait_for(Task, ExpectedAnswer, SleepTime, Retries) ->
    wait_for_success(fun() ->
                             ExpectedAnswer = Task()
                     end, SleepTime, Retries).

wait_for_success(Task) ->
    wait_for_success(Task, 200, 10).

wait_for_success(Task, SleepTime, Retries) ->
    wait_for_success(Task, undefined, SleepTime, Retries).

wait_for_success(_Task, Exception, _SleepTime, 0) ->
    {error, {timeout, Exception}};
wait_for_success(Task, _Exception, SleepTime, Retries) ->
    try
        Task()
    catch
        _:NewException ->
            timer:sleep(SleepTime),
            wait_for_success(Task, NewException, SleepTime, Retries - 1)
    end.

now_human_readable() ->
    TimeStamp = os:timestamp(),
    {{Year, Month, Day},
     {Hour, Minute, Second}} = calendar:now_to_universal_time(TimeStamp),
    DateList = io_lib:format("~p-~p-~pT~p:~p:~pZ",
                             [Year, Month, Day, Hour, Minute, Second]),
    list_to_binary(DateList).

beam_to_erl(BeamPath, ErlPath) ->
    case beam_lib:chunks(BeamPath, [abstract_code]) of
        {ok, {_, [{abstract_code, {raw_abstract_v1,Forms}}]}} ->
            Src =
                erl_prettypr:format(erl_syntax:form_list(tl(Forms))),
            {ok, Fd} = file:open(ErlPath, [write]),
            io:fwrite(Fd, "~s~n", [Src]),
            file:close(Fd);
        Error ->
            Error
    end.
