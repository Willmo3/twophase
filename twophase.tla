---- MODULE twophase ----
EXTENDS TLC

VARIABLES tmState, tmPrepared, rmState, msgs

RMs == {"rm1", "rm2", "rm3"}

Init == 
    /\ tmState = "init"
    /\ msgs = {}
    /\ tmPrepared = {}
    /\ rmState = [rm \in RMs |-> "working"]

\* Typechecking:
\* What state can the resource manager have?
\* -- Prepared to commit
\* -- Committed
\* -- Aborted
\* -- Working

\* What state can the transaction manager have?
\* -- init
\* -- commited
\* -- aborted

\* tmPrepared is the subset of the resource managers that are prepared.

\* What state can the messages have?
\* -- Can contain a prepared message from RM rm
\* -- Can contain a commit message from the TM
\* -- Can contain an abort message from the TM (in this model, RMs silently abort)
Message == 
    [type : {"prepared"}, theRM: RMs] \cup [type : {"commit", "abort"}]

TypeOK == 
    /\ rmState \in [RMs-> {"working", "prepared", "aborted", "committed"}]
    /\ msgs \in SUBSET Message
    /\ tmPrepared \in SUBSET RMs
    /\ tmState \in {"init", "committed", "aborted"}

\* A resource manager can declare itself prepared.
\* When this happens, its rmState will be prepared.
\* And a message will be appended stating that it is prepared.
\* The state of the transaction manager, and the ones that the tm sees as prepared, are unaffected.
RM_sendPrepare(rm) == 
    /\ rmState[rm] = "working"
    /\ rmState' = [rmState EXCEPT![rm] = "prepared"]
    /\ msgs' = msgs \cup {[type |-> "prepared", theRM |-> rm]}
    /\ UNCHANGED <<tmPrepared, tmState>>

\* The transaction manager can recieve a prepared message.
\* When the messages set contains a message from a given resource manager, it should be in tmPrepared.
\* The tmState should not be affected
\* The rmState should not be affected, nor should the messages -- receipt of a message ought not change the msgs set.
TM_rcvPrepare(rm) ==
    /\ [type |-> "prepared", theRM |-> rm] \in msgs
    /\ tmState = "init"
    /\ tmPrepared' = tmPrepared \cup {rm}
    /\ UNCHANGED <<tmState, rmState, msgs>>

\* A transaction manager can declare itself aborted.
\* When this happens, a message will be sent stating that its time to abort.
\* And the tmstate will be equal to abort.
\* The resource manager state will be unaffected.
TM_sendAbort(rm) ==
    /\ tmState \in {"init", "aborted"}
    /\ tmState' = "aborted"
    /\ msgs' = msgs \cup {[type |-> "abort"]}
    /\ UNCHANGED <<rmState, tmPrepared>>

\* A resource manager can recieve an abort message
\* Its state must be set to aborted.
\* The messages field will be unchanged, as will all transaction manager state.
RM_rcvAbort(rm) ==
    /\ [type |-> "abort"] \in msgs
    /\ rmState' = [rmState EXCEPT ![rm] = "aborted"]
    /\ UNCHANGED <<tmState, msgs, tmPrepared>>

\* A resource manager can spontaneously, and silently, abort
\* For simplicity, no message will be sent
\* Remember, the simpler the model, the easier it will be to handle.
RM_silentAbort(rm) ==
    /\ rmState[rm] = "working"
    /\ rmState' = [rmState EXCEPT ![rm] = "aborted"]
    /\ UNCHANGED <<tmState, msgs, tmPrepared>>

\* The transaction manager can decide to commit the transaction
\* This may only happen if the set of known prepared resource managers
\* Is equal to the set of resource managers (i.e. each resource manager is ready)
\* The transaction manager sends a commit message and sets its own state to committed.
\* The resource manager state is unaffected.
\* Additionally, since tmPrepared already equals all resource managers, it is unaffected.
TM_sendCommit(rm) == 
    /\ tmState = "init"
    /\ tmPrepared = RMs
    /\ tmState' = "committed"
    /\ msgs' = msgs \cup {[type |-> "commit"]}
    /\ UNCHANGED <<rmState, tmPrepared>>

\* The resource manager can recieve a commit message.
\* This may only happen if a commit message is present.
\* rmState[rm] is set to committed.
\* no message is sent, so msgs is unchanged.
\* transaction manager state remains unaffected.
RM_rcvCommit(rm) ==
    /\ [type |-> "commit"] \in msgs
    /\ rmState' = [rmState EXCEPT ![rm] = "committed"]
    /\ UNCHANGED <<tmState, tmPrepared, msgs>>

Next == \E rm \in RMs:
    \/ RM_sendPrepare(rm)
    \/ RM_rcvAbort(rm)
    \/ RM_rcvCommit(rm)
    \/ RM_silentAbort(rm)
    \/ TM_rcvPrepare(rm)
    \/ TM_sendAbort(rm)
    \/ TM_sendCommit(rm)

\* Consistency property: it cannot be the case that one RM is committed while the other is aborted.
Consistent == \A rm1, rm2 \in RMs : ~(rmState[rm1] = "aborted" /\ rmState[rm2] = "committed")
====