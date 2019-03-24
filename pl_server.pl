:- use_module(library(socket)).

%test_socket( :-
    %tcp_socket(Socket),
    %tcp_bind(Socket, 8532).

create_server(Port) :-
    tcp_socket(Socket),
    tcp_bind(Socket, localhost:Port),
    tcp_listen(Socket, 5),
    tcp_open_socket(Socket, AcceptFd, _), % this opens the sockets and starts to listen for clients?
    dispatch(AcceptFd),
    tcp_close_socket(Socket).

dispatch(AcceptFd) :-
    % Socket: identifier for client
    % Peer: IP-address of client
    print("c"),
    writeln("hlll"),

    % programmet stopper, men siden porten er åpna får man fortsatt tilgang til den
    % via telnet
    tcp_accept(AcceptFd, Socket, Peer), % this accepts a client

    print("e"),
    thread_create(process_client(Socket), _, [ detached(true)]),
    print("f"),
    % dispatch(AcceptFd),
    print("ss").

process_client(Socket) :-
    % setup_call_cleanup(Setup, Goal, Cleanup)
    % If Setup succeeds, Cleanup will be called exactly once after Goal is finished.
    setup_call_cleanup(
        tcp_open_socket(Socket, StreamPair),
        handle_service(StreamPair),
        close(StreamPair)).

handle_service(StreamPair) :-
    print("ABS"),
    print(StreamPair),
    read(StreamPair, T),
    writeln(T).
    %print(T).
