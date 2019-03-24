% -*-Prolog-*-

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

uncle(X, Y) :- brother(X, Z), parent(Z, Y).
aunt(X, Y) :- sister(X, Z), parent(Z, Y).

grandfather(X, Z) :- father(X, Y), parent(Y, Z).
grandmother(X, Z) :- mother(X, Y), parent(Y, Z).

