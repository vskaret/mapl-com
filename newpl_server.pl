% -*-Prolog-*-

:- use_module(library(socket)).

male(thomas).
male(rolf).
male(arne).
female(anna).
female(maria).
parent(thomas, anna).
parent(maria, anna).
parent(thomas, arne).
parent(rolf, maria).

father(X, Y) :- parent(X, Y), male(X).
mother(X, Y) :- parent(X, Y), female(X).

brother(X, Y) :- parent(Z, X), parent(Z, Y), male(X), X\=Y.
sister(X, Y) :- parent(Z, X), parent(Z, Y), female(X), X\=Y.
sibling(X, Y) :- brother(X, Y); sister(X, Y) .

uncle(X, Y) :- brother(X, Z), parent(Z, Y).
aunt(X, Y) :- sister(X, Z), parent(Z, Y).

grandfather(X, Z) :- father(X, Y), parent(Y, Z).
grandmother(X, Z) :- mother(X, Y), parent(Y, Z).

create_server(Port) :-
    tcp_socket(Socket),
    tcp_bind(Socket, localhost:Port),
    tcp_listen(Socket, 5),
    tcp_open_socket(Socket, AcceptFd, _), % master socket
    dispatch(AcceptFd).
    %print("TEST"),
    %tcp_close_socket(Socket). % closes the master socket

dispatch(AcceptFd) :-
    % Socket: identifier for client
    % Peer: IP-address of client

    % programmet stopper, men siden porten er åpna får man fortsatt tilgang til den
    % via neg(father(maria,anna))telnet
    tcp_accept(AcceptFd, Socket, Peer), % accepted socket
    thread_create(process_client(Socket), _, [ detached(true)]),
    dispatch(AcceptFd). % loops dispatch

process_client(Socket) :-
    % setup_call_cleanup(Setup, Goal, Cleanup)
    % If Setup succeeds, Cleanup will be called exactly once after Goal is finished.
    setup_call_cleanup(
        tcp_open_socket(Socket, StreamPair),
        handle_service(StreamPair),
        close(StreamPair)).

    %tcp_open_socket(Socket, StreamPair),
    %handle_service(StreamPair).

% this will accept one message from the client and then process_client() will close the socket
handle_service(StreamPair) :-
    read_line_to_codes(StreamPair, Codes), % reads message into an array of character codes or something
    %format(StreamPair, '~n~s~n', [Codes]), % send message back with newline before and after

    %print(Codes),


    %parse_message(String),
    %handle_message(String),

    % transforms codes into a term (which can be used as a query)
    % Queries should be in the form of a list like [parent(A, B), sibling(A, B)]
    read_term_from_codes(Codes, Queries, []),
    writeln(Queries),
    %maplist(handle_query, [StreamPair, Queries]),
    maplist_const(handle_query, StreamPair, Queries),
    %format(StreamPair, "***end_of_message***~w", [end_of_file]). % need to tell maude to stop receiving messages somehow
    format(StreamPair, " .", []). % need to tell maude to stop receiving messages somehow

    % writes reply back to client
    % reply(StreamPair, Query).
    %handle_service(StreamPair).



% shows all results for queries
handle_query(StreamPair, Query) :-
    %writeln(Query).
    %format("nooo~n"),
    Query =.. [F|Args],
    format("F = ~w~n", [F]),
    format("Args = ~w~n", [Args]),

    % if all args are terms, run query deterministically
    % else run it non-deterministically
    (maplist(atom, Args), handle_deterministic_query(StreamPair, Query);
     flatten([F, Args], L), handle_non_deterministic_query(StreamPair, Query, L)).
    %(maplist(atom, Args), handle_deterministic_query(StreamPair, Query);
     %flatten([F, Args], L), handle_non_deterministic_query(StreamPair, Query, L)).




% FunctionList should be [process, var1, var2]
handle_non_deterministic_query(StreamPair, Query, FunctionList) :-
    forall(Query, write_variable_sized_term(StreamPair, FunctionList)).
    %forall(Query, format('~w(~w,~w)~n', [Functor|Arguments])),

    % TODO: is something like this possible?
    %forall(\+ Query, format('~w(~w,~w)~n', [Functor|Arguments])).
%forall(Query, format('~w(~w,~w)~n', List)).


% writes out a term with a functor where the amount of arguments can vary
write_variable_sized_term(StreamPair, [Functor|Arguments]) :-
    format(StreamPair, '~w(', Functor),
    write_arguments(StreamPair, Arguments),
    format(StreamPair, ') # ', []).
/*
    format('~w(', Functor),
    write_arguments(Arguments),
    format(')~n').
*/

% writes out a list of variable size: e1,e2,e3
write_arguments(StreamPair, [FirstArg|Rest]) :-
    (length(Rest, 0), format(StreamPair, '~w', FirstArg));          % base case (last argument)
    (format(StreamPair, '~w,', FirstArg), write_arguments(StreamPair, Rest)).

/*
write_arguments(StreamPair, [LastArg]) :-
    format(StreamPair, '~w', LastArg).
*/

/*
    (length(Rest, 0), format('~w', FirstArg));          % base case (last argument)
    (format('~w,', FirstArg), write_arguments(Rest)).
*/


% writes the query if it's true and neg(query) if false.
handle_deterministic_query(StreamPair, Query) :-
    (Query,
     format(StreamPair, '~w~n', Query));
    (\+ Query,
     format(StreamPair, 'neg(~w)~n', Query)).
/*
    (Query,
     format('~w~n', Query));
    (\+ Query,
    format('neg(~w)~n', Query)).
*/




reply(StreamPair, Query) :-
    (Query\=end_of_file,
     (positive_reply(StreamPair, Query);
      negative_reply(StreamPair, Query)));
    eof_error_reply(StreamPair).


% TODO: hvorfor er end_of_file med?
% har noe med hvordan maude leser meldinger? eller bare tull å ha det der?

% reply with query if true
positive_reply(StreamPair, Query) :-
    Query,
    format(StreamPair, '~w~w', [Query, end_of_file]).

% reply with neg(query) if false
negative_reply(StreamPair, Query) :-
    \+ Query,
    format(StreamPair, 'neg(~w)~w', [Query, end_of_file]).

eof_error_reply(StreamPair) :-
    format(StreamPair, 'eof_error~w', [end_of_file]).


maplist_const(_, _, []).
maplist_const(Pred, Const, [H|T]) :-
    call(Pred, Const, H),
    maplist_const(Pred, Const, T).
