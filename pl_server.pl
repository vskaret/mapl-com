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

%test_socket( :-
    %tcp_socket(Socket),
    %tcp_bind(Socket, 8532).

create_server(Port) :-
    tcp_socket(Socket),
    tcp_bind(Socket, localhost:Port),
    tcp_listen(Socket, 5),
    tcp_open_socket(Socket, AcceptFd, _), % master socket
    dispatch(AcceptFd),
    tcp_close_socket(Socket). % closes the master socket

dispatch(AcceptFd) :-
    % Socket: identifier for client
    % Peer: IP-address of client

    % programmet stopper, men siden porten er åpna får man fortsatt tilgang til den
    % via telnet
    tcp_accept(AcceptFd, Socket, Peer), % accepted socket
    thread_create(process_client(Socket), _, [ detached(true)]).
    %dispatch(AcceptFd). % loops dispatch

process_client(Socket) :-
    % setup_call_cleanup(Setup, Goal, Cleanup)
    % If Setup succeeds, Cleanup will be called exactly once after Goal is finished.
    setup_call_cleanup(
        tcp_open_socket(Socket, StreamPair),
        handle_service(StreamPair),
        close(StreamPair)).

% this will accept one message from the client and then process_client() will close the socket
handle_service(StreamPair) :-
    %read(StreamPair, T),
    read_line_to_codes(StreamPair, Codes), % reads message into an array of character codes or something
    format(StreamPair, '~n~s~n', [Codes]). % send message back with newline before and after
    %readln(StreamPair, T), does not work

    % TODO: need to figure out how to write result of a query to socket
    %format(StreamPair, '~s~n', mother(maria, anna)),
    %with_output_to(StreamPair, mother(maria, anna)).
    %write(StreamPair, mother(maria, anna)) :-
        %mother(maria, anna).



write
