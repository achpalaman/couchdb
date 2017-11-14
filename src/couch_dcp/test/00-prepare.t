#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable

% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

main(_) ->
    etap:plan(2),
    case {run_test(false), run_test(true)} of
    {ok, ok} ->
        etap:end_tests();
    Other ->
        etap:diag(io_lib:format("test died abnormally: ~p", [Other])),
        etap:bail(Other)
    end,
    ok.

run_test(IsIPv6) ->
    test_util:init_code_path(),
    case (catch test(IsIPv6)) of
        ok -> ok;
        Other -> Other
    end.

test(IsIPv6) ->
    % Purpose of this test is to create all system databases (_users, _replicator)
    % before we start running all other tests in parallel. When the other tests start
    % in parallel, if the system databases don't exist, they will all attempt to create
    % them, and 1 succeeds while others will fail.
    couch_set_view_test_util:start_server(IsIPv6),
    {ok, RepDb} = couch_db:open_int(<<"_replicator">>, []),
    {ok, _} = couch_db:ensure_full_commit(RepDb),
    ok = couch_db:close(RepDb),
    etap:is(true, true, "Preparation for parallel testing done"),
    couch_set_view_test_util:stop_server(),
    ok.
