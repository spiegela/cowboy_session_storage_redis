-module(cowboy_session_storage_redis).
-author('spiegela <spiegela@gmail.com>').

%% Cowboy_session_storage behaviour
-behaviour(cowboy_session_storage).
-export([
  start_link/0,
  new/1,
  set/3,
  get/3,
  delete/1,
  stop/1
]).

%% Gen_server behaviour
-behaviour(gen_server).
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).

-record(state, {client, url, prefix}).

-define(CONFIG, cowboy_session_config).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

new(SID) ->
  gen_server:cast(?MODULE, {new, SID}).

set(SID, Key, Value) ->
  gen_server:cast(?MODULE, {set, SID, Key, Value}).

get(SID, Key, Default) ->
  gen_server:call(?MODULE, {get, SID, Key, Default}).

delete(SID) ->
  gen_server:cast(?MODULE, {delete, SID}).

stop(New_storage) ->
  gen_server:cast(?MODULE, {stop, New_storage}).


%%%===================================================================
%%% Gen_server callbacks
%%%===================================================================

init([]) ->
  Url = redis_url(),
  {ok, Client} = apply(eredis, start_link, redis_config(Url)),
  State = #state{ client = Client, url = Url, prefix = prefix() },
  {ok, State}.

handle_call({get, SID, Key, Default}, _From, #state{client = Client} = State) ->
  Reply = case eredis:q(Client, ["HMGET", prefixed(SID), Key]) of
    [] -> Default;
    Other -> Other
  end,
  {reply, Reply, State};

handle_call(_, _, State) -> {reply, ignored, State}.


handle_cast({new, SID}, #state{client = Client}=State) ->
  eredis:qp(Client, [ ["HSET", prefixed(SID), "SID", SID],
      ["EXPIRE", SID, ?CONFIG:get(expire)] ]),
  {noreply, State};

handle_cast({set, SID, Key, Value}, #state{client = Client}=State) ->
  eredis:q(Client, ["HSET", prefixed(SID), Key, Value]),
  {noreply, State};

handle_cast({delete, SID}, #state{client = Client }=State) ->
  eredis:q(Client, ["DEL", prefixed(SID)]),
  {noreply, State};

handle_cast({stop, _New_storage}, #state{client=Client} = State) ->
  eredis:stop(Client),
  {stop, normal, State#state{ client = undefiend }};

handle_cast(_, State) -> {noreply, State}.


handle_info(_, State) -> {noreply, State}.


terminate(_Reason, _) ->
  ok.


code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

redis_config(Url) ->
  {ok, {_, Pass, Host, Port, Path, _}} = http_uri:parse(Url),
  redis_password(Pass, redis_database(Path, [Host, Port])).

redis_database([$/], Config) ->
  Config;
redis_database([$/|DB], Config) ->
  Config ++ [list_to_integer(DB)].

redis_password([], Config) ->
  Config;
redis_password(Pass, Config) ->
  Config ++ [Pass].

prefixed(SID) ->
  prefix() ++ ":" ++ SID.

redis_url() ->
  case os:getenv("REDIS_URL") of
    false -> "redis://127.0.0.1:6379/0";
    Url   -> Url
  end.

prefix() ->
  case os:getenv("REDIS_PREFIX") of
    false -> "cowboy_session";
    P -> P
  end.
