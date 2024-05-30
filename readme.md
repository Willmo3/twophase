# Twophase

## Introduction
This is a TLA+ specification of the two phase commit protocol for distributed consensus.

### Credit 
CMU SoDA's implementation heavily inspired my work. See at https://github.com/cmu-soda/recomp-verify/blob/master/benchmarks/tla/two_phase/9/TwoPhase.tla!

Leslie Lamport's TLA+ video series scaffolded me. (See it on lamport.org)

## The Algorithm
Consider a consistent operation in a distributed system, like a database commit over several resource managers. By definition, a consistent operation must effect all nodes uniformly. Yet in a distributed system, where "the failure of a computer you didn't even know existed can render your computer unusable" (Lamport), this can't be taken for granted.

To negate this risk, two phase commit obeys the following invariant.

### The Invariant
For any two nodes N1 and N2, if N1 is committed, then N2 is not aborted.

### The implementation
(Note: we consider a simplified version of two-phase commit)

In two phase commit, a central node tracks how many worker nodes are prepared to make a commit.

At any point, a worker node may declare itself prepared to commit a change to the central node.

Once each node has declared itself prepared, the first phase of two phase commit is over! 

The central node now declares the change committed and messages this to each worker node.

Finally, when each node receives an explicit commit message from the main node, it declares the change committed.

### Why it works
What can go wrong here? 

Suppose a worker node is unreachable. In a poorly implemented system, the central node might declare a change committed without this node knowing. Now consistency has been violated!

However, with two-phase commit, changes can only be committed when the transaction manager receives explicit confirmation from each and every node. Even a silent failure cannot threaten consistency!

And while the central node is a single point of failure, if it goes offline, the worker nodes cannot commit their changes.

Our algorithm isn't foolproof -- a worker node might miss the main node's explicit commit message, for instance. A more detailed exploration of two phase commit would address this.

## The  Model

### Terminology
In the style of Lamport's lecture series, I opt to use database terminology for two-phase commit.

### Variables
Variables are named statefully because (like most formal methods) TLA+ treats computation as a state machine to be traversed.

1. tmState:
In what state is the transaction manager currently? Is it committed? Aborted? 
2. rmState:
This is a function mapping resource managers to their current states.
3. tmPrepared:
This is the set of resource managers which the transaction manager believes are prepared to commit.
4. msgs:
This is the set of all messages that have been sent.

Note that messages are not removed from this set as they are received! Beyond making the model simpler, this has the added benefit of testing for a variety of internet errors, such as messages being errantly recieved multiple times.

### Constants
1. RMs
The resource managers employed by this model. Unlike in Lamport's solution, these are not specified in the config file -- rather, they are written into the mode.

### Typing
#### Message:
1. A prepared message, which must contain the sending resource manager.
2. An abort or commit message. For simplicity, these do not contain the sending resource manager.

#### TypeOK:
1. Each resource manager must have state "working", "prepared", "committed", or "aborted"
2. All messages must obey the above message type constraint.
3. The set of resource managers marked as prepared by the transaction manager must be a subset of all the resource managers.
4. The transaction manager state must be "init", "committed", or "aborted"

### States
- RM\_sendPrepare: a resource manager declares that it is prepared.
- TM\_rcvPrepare: the transaction manager receives a prepare message.
- TM\_sendAbort: the transaction manager emits an abort message and declares its state aborted.
- RM\_rcvAbort: A resource manager recieves an abort message
- RM\_silentAbort: A resource manager silently aborts
- TM\_sendCommit: Once the transaction manager has recieved commit messages from each of the resource managers, it may emit a commit message.
- RM\_rcvCommit: The resource manager recieves a commit message.

### Invariants
#### Consistent:
For each resource manager r1 and r2, r1 and r2 cannot have opposing states from among "committed" and "aborted".
