% -*-Prolog-*-

:- use_module(library(socket)).

male(thomas).
male(rolf).
female(anna).
female(maria).
parent(thomas, anna).
parent(maria, anna).
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

    % transforms codes into a term (which can be used as a query)
    read_term_from_codes(Codes, Query, []),

    writeln(Query),

    % writes reply back to client
    reply(StreamPair, Query).

    %handle_service(StreamPair).


reply(StreamPair, Query) :-
    (Query\=end_of_file,
     (positive_reply(StreamPair, Query);
      negative_reply(StreamPair, Query)));
    eof_error_reply(StreamPair).


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



